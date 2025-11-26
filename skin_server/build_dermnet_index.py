# build_dermnet_index.py
# -*- coding: utf-8 -*-
"""
Milvus + BGE-M3 高可靠 RAG 重建器
功能包含：
- 多 JSON 來源合併
- 自動清洗空欄位 / 無效欄位
- 忽略超短內容
- BGE-M3 批次 embed
- 重建 Milvus collection
"""

import os
import json
import numpy as np
from tqdm import tqdm
import torch

from pymilvus import (
    connections, FieldSchema, CollectionSchema,
    DataType, Collection, utility
)
from FlagEmbedding import BGEM3FlagModel

# ====== 設定 ======
JSON_DIR = r"./rag_sources"
MILVUS_HOST = "127.0.0.1"
MILVUS_PORT = "19530"
COLLECTION_NAME = "dermnet_zh_bge_m3"
EMBED_DIM = 1024


# ===== 清洗工具 =====
def clean_text(text):
    """去除 None / 空白 / 無效字串 / HTML 斷行"""
    if not text:
        return None

    text = str(text).strip()

    INVALID = ["", "None", "null", "undefined", "N/A", "nan"]
    if text.lower() in INVALID:
        return None

    # 去除太短的垃圾文本
    if len(text) < 10:
        return None

    return text


def safe_text(*fields):
    """依序挑選第一個有效欄位並清洗"""
    for f in fields:
        cleaned = clean_text(f)
        if cleaned:
            return cleaned
    return None


# ====== 1. 合併所有 JSON ======
all_titles = []
all_urls = []
all_contents = []

print(f"掃描 JSON 資料夾：{JSON_DIR}")
json_files = [f for f in os.listdir(JSON_DIR) if f.endswith(".json")]

print(f"找到 JSON 檔案：{json_files}\n")

for jf in json_files:
    path = os.path.join(JSON_DIR, jf)
    print(f"📥 載入：{jf}")

    with open(path, "r", encoding="utf-8") as f:
        data = json.load(f)

    for item in data:
        title = safe_text(item.get("title_zh"), item.get("title"))
        if not title:
            continue

        url = clean_text(item.get("url")) or ""

        content = safe_text(
            item.get("full_text_zh"),
            item.get("full_text"),
            item.get("content_zh"),
            item.get("content"),
            item.get("snippet_zh"),
            item.get("snippet"),
            item.get("symptoms_zh"),
            item.get("symptoms"),
            item.get("causes_zh"),
            item.get("causes"),
        )
        if not content:
            continue

        all_titles.append(title)
        all_urls.append(url)
        all_contents.append(content)

print(f"\n📌 最終有效內容數量：{len(all_contents)} 筆\n")


# ====== 2. BGE-M3 向量產生 ======
device = "cuda" if torch.cuda.is_available() else "cpu"
print("使用裝置：", device)

model = BGEM3FlagModel("BAAI/bge-m3", device=device, use_fp16=(device == "cuda"))

batch_size = 16
all_embeddings = []

print("🚀 開始產生 embedding ...")

for i in tqdm(range(0, len(all_contents), batch_size), desc="Embedding batches"):
    batch = all_contents[i:i+batch_size]

    try:
        emb = model.encode(batch).get("dense_vecs")
    except Exception as e:
        print("⚠ embedding 失敗，跳過該批次：", e)
        continue

    for e in emb:
        all_embeddings.append(e.tolist())

print("✔ embedding 完成：", len(all_embeddings))


# ====== 3. 重建 Milvus collection ======
connections.connect(alias="default", host=MILVUS_HOST, port=MILVUS_PORT)

if utility.has_collection(COLLECTION_NAME):
    print(f"⚠ collection '{COLLECTION_NAME}' 已存在，刪除重建...")
    utility.drop_collection(COLLECTION_NAME)

# Schema
fields = [
    FieldSchema(name="id", dtype=DataType.INT64, is_primary=True, auto_id=True),
    FieldSchema(name="title", dtype=DataType.VARCHAR, max_length=512),
    FieldSchema(name="url", dtype=DataType.VARCHAR, max_length=512),
    FieldSchema(name="content", dtype=DataType.VARCHAR, max_length=8192),
    FieldSchema(name="embedding", dtype=DataType.FLOAT_VECTOR, dim=EMBED_DIM),
]

schema = CollectionSchema(fields=fields, description="RAG Cleaned Knowledge Base")

collection = Collection(
    name=COLLECTION_NAME,
    schema=schema,
    using="default",
    shards_num=2,
)

# Index
index_params = {
    "metric_type": "COSINE",
    "index_type": "IVF_FLAT",
    "params": {"nlist": 1024},
}

print("🔨 建立 index ...")
collection.create_index("embedding", index_params)
print("✔ index 完成")


# ====== 4. 寫入 Milvus ======
print("📤 寫入資料 ...")

mr = collection.insert([
    all_titles,
    all_urls,
    all_contents,
    all_embeddings,
])

print(f"🎉 寫入完成，共：{len(all_titles)} 筆")
collection.load()

print("\n🚀 RAG 重建成功（含空欄位忽略 + 清洗）！")
