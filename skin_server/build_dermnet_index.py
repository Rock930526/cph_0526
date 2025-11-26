# build_dermnet_index.py
# -*- coding: utf-8 -*-
"""
Milvus + BGE-M3 高可靠 RAG 重建器
強韌模式：不跳過任何資料，自動修正格式
支援格式：
1. [ {...}, {...} ]
2. { "items": [ {...}, {...} ] }
3. 任意亂格式（字串、list），會自動包成 dict
"""

import os
import json
from tqdm import tqdm
import torch
from pymilvus import (
    connections, FieldSchema, CollectionSchema,
    DataType, Collection, utility
)
from FlagEmbedding import BGEM3FlagModel


JSON_DIR = r"./rag_sources"
MILVUS_HOST = "127.0.0.1"
MILVUS_PORT = "19530"
COLLECTION_NAME = "dermnet_zh_bge_m3"
EMBED_DIM = 1024


# -------------------------
# 工具：清洗文字
# -------------------------
def clean_text(text):
    if not text:
        return None
    text = str(text).strip()
    if text.lower() in ["", "none", "null", "undefined", "n/a", "nan"]:
        return None
    if len(text) < 2:
        return None
    return text


def safe_text(*fields):
    for f in fields:
        cleaned = clean_text(f)
        if cleaned:
            return cleaned
    return None


# -------------------------
# 自動讀 JSON：
# - 支援 dict + items
# - 支援 list
# -------------------------
def load_json_safely(path):
    with open(path, "r", encoding="utf-8") as f:
        data = json.load(f)

    if isinstance(data, dict) and "items" in data:
        return data["items"]

    if isinstance(data, list):
        return data

    raise ValueError(f"⚠ JSON 格式錯誤：{path}")


# -------------------------
# 自動格式修正：統一轉成 dict
# -------------------------
def normalize_item(item):
    # 如果是 dict → 直接用
    if isinstance(item, dict):
        return item

    # 如果是 string → 自動包裝成 dict
    if isinstance(item, str):
        return {
            "title": item,
            "content": item,
            "url": ""
        }

    # 如果是 list → 合併成一個字串
    if isinstance(item, list):
        merged = "；".join([str(x) for x in item])
        return {
            "title": merged,
            "content": merged,
            "url": ""
        }

    # 其他類型（int/float/bool） → 轉字串
    return {
        "title": str(item),
        "content": str(item),
        "url": ""
    }


# -------------------------
# 1. 讀取所有 JSON
# -------------------------
all_titles = []
all_urls = []
all_contents = []

json_files = [f for f in os.listdir(JSON_DIR) if f.endswith(".json")]
print("找到 JSON：", json_files)

for jf in json_files:
    path = os.path.join(JSON_DIR, jf)
    print(f"📥 載入 {jf}")

    data = load_json_safely(path)

    for raw_item in data:

        item = normalize_item(raw_item)

        title = safe_text(
            item.get("term_zh_standard"),
            item.get("title_zh"),
            item.get("term_zh_raw"),
            item.get("title"),
            item.get("name_zh")
        )

        content = safe_text(
            item.get("full_text_zh"),
            item.get("content_zh"),
            item.get("snippet_zh"),
            item.get("symptoms_zh"),
            item.get("causes_zh"),
            item.get("content"),
            item.get("term_zh_raw"),
            title
        )

        url = item.get("url") or ""

        all_titles.append(title or "未命名")
        all_urls.append(url)
        all_contents.append(content or title)

print(f"\n📌 最終總筆數：{len(all_contents)} 筆\n")


# -------------------------
# 2. Embedding
# -------------------------
device = "cuda" if torch.cuda.is_available() else "cpu"
print("使用裝置：", device)

model = BGEM3FlagModel("BAAI/bge-m3", device=device, use_fp16=(device == "cuda"))

batch_size = 16
embeddings = []

print("🚀 產生 embedding ...")
for i in tqdm(range(0, len(all_contents), batch_size)):
    batch = all_contents[i:i+batch_size]
    try:
        emb = model.encode(batch)["dense_vecs"]
        for e in emb:
            embeddings.append(e.tolist())
    except Exception as e:
        print("⚠ Embedding 失敗跳過：", e)

print("✔ embedding 完成：", len(embeddings))


# -------------------------
# 3. 建立 Milvus collection
# -------------------------
connections.connect(alias="default", host=MILVUS_HOST, port=MILVUS_PORT)

if utility.has_collection(COLLECTION_NAME):
    print(f"刪除舊 collection：{COLLECTION_NAME}")
    utility.drop_collection(COLLECTION_NAME)

fields = [
    FieldSchema(name="id", dtype=DataType.INT64, is_primary=True, auto_id=True),
    FieldSchema(name="title", dtype=DataType.VARCHAR, max_length=512),
    FieldSchema(name="url", dtype=DataType.VARCHAR, max_length=512),
    FieldSchema(name="content", dtype=DataType.VARCHAR, max_length=8192),
    FieldSchema(name="embedding", dtype=DataType.FLOAT_VECTOR, dim=EMBED_DIM),
]

schema = CollectionSchema(fields, description="DermNet + TW 名詞 RAG DB")
collection = Collection(COLLECTION_NAME, schema, shards_num=2)

index_params = {
    "metric_type": "COSINE",
    "index_type": "IVF_FLAT",
    "params": {"nlist": 1024},
}

collection.create_index("embedding", index_params)
collection.insert([all_titles, all_urls, all_contents, embeddings])
collection.load()

print("\n🎉 RAG 重建成功（不遺漏任何資料）！")
