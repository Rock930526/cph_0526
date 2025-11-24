# build_dermnet_index.py
# -*- coding: utf-8 -*-
"""
建立 Milvus + BGE-M3 皮膚疾病知識庫（DermNet）
自動處理 JSON 空欄位、fallback、多種欄位內容來源。
"""

import os
import json
from tqdm import tqdm
import numpy as np
import torch


from pymilvus import (
    connections, FieldSchema, CollectionSchema,
    DataType, Collection, utility
)
from FlagEmbedding import BGEM3FlagModel

# ===== 路徑設定 =====
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
KNOWLEDGE_JSON = os.path.join(BASE_DIR, "dermnet_full_translated.json")

# ===== Milvus 設定 =====
MILVUS_HOST = "127.0.0.1"
MILVUS_PORT = "19530"
COLLECTION_NAME = "dermnet_zh_bge_m3"

# BGE-m3 dense 向量維度
EMBED_DIM = 1024

# ===== 工具函數 =====
def safe_text(*fields):
    """依序挑選第一個非空欄位，全部空則回傳 None。"""
    for f in fields:
        if f and str(f).strip():
            return str(f).strip()
    return None


# ===== 1. 載入 JSON =====
with open(KNOWLEDGE_JSON, "r", encoding="utf-8") as f:
    raw_data = json.load(f)

print(f"載入 DermNet 筆數：{len(raw_data)}")

texts = []
titles = []
urls = []

for item in raw_data:

    # 1) title 允許英文 / 中文 fallback
    title = safe_text(item.get("title_zh"), item.get("title"))
    if title is None:
        print("⚠ 跳過：無標題", item.get("url"))
        continue

    url = item.get("url") or ""

    # 2) 挑選最佳內容欄位（依序降級）
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

    if content is None:
        print("⚠ 跳過：無有效內容", title)
        continue

    # 儲存
    titles.append(title)
    urls.append(url)
    texts.append(content)

print(f"有效文本筆數：{len(texts)}")


# ===== 2. 初始化 BGE-m3 =====
device = "cuda" if torch.cuda.is_available() else "cpu"
print(f"使用裝置：{device}")

model = BGEM3FlagModel("BAAI/bge-m3", device=device, use_fp16=(device == "cuda"))

batch_size = 16
all_embeddings = []

for i in tqdm(range(0, len(texts), batch_size), desc="產生向量中"):
    batch = texts[i:i+batch_size]
    emb = model.encode(batch, batch_size=len(batch)).get("dense_vecs")

    if emb is None:
        print("⚠ embedding 失敗，跳過批次", i)
        continue

    for e in emb:
        if isinstance(e, np.ndarray):
            all_embeddings.append(e.tolist())
        else:
            print("⚠ 無效 embedding，跳過")
            all_embeddings.append([0.0] * EMBED_DIM)

if len(all_embeddings) != len(texts):
    print("❌ embedding 數量不一致，停止。")
    exit()

print("✔ 向量產生完成：", len(all_embeddings))


# ===== 3. 建立 Milvus Collection =====

connections.connect(alias="default", host=MILVUS_HOST, port=MILVUS_PORT)
print("已連線 Milvus")

if utility.has_collection(COLLECTION_NAME):
    print(f"collection {COLLECTION_NAME} 已存在，刪除重建")
    utility.drop_collection(COLLECTION_NAME)

fields = [
    FieldSchema(name="id", dtype=DataType.INT64, is_primary=True, auto_id=True),
    FieldSchema(name="title", dtype=DataType.VARCHAR, max_length=512),
    FieldSchema(name="url", dtype=DataType.VARCHAR, max_length=512),
    FieldSchema(name="content", dtype=DataType.VARCHAR, max_length=8192),
    FieldSchema(name="embedding", dtype=DataType.FLOAT_VECTOR, dim=EMBED_DIM),
]

schema = CollectionSchema(fields=fields, description="DermNet 中文 RAG 知識庫")

collection = Collection(
    name=COLLECTION_NAME,
    schema=schema,
    using="default",
    shards_num=2,
)

# 建 index
index_params = {
    "metric_type": "COSINE",
    "index_type": "IVF_FLAT",
    "params": {"nlist": 1024},
}

collection.create_index("embedding", index_params)
print("✔ 已建立 index")

# ===== 4. 寫入 Milvus =====
mr = collection.insert([
    titles,
    urls,
    texts,
    all_embeddings,
])

print(f"✔ 寫入 {len(texts)} 筆資料，主鍵：{mr.primary_keys}")

collection.load()

print("\n🎉 DermNet 中文知識庫建立成功！")
