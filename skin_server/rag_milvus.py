# rag_milvus.py
# -*- coding: utf-8 -*-
import os
from typing import List, Dict

from pymilvus import connections, Collection
from FlagEmbedding import BGEM3FlagModel

MILVUS_HOST = "127.0.0.1"
MILVUS_PORT = "19530"
COLLECTION_NAME = "dermnet_zh_bge_m3"
EMBED_DIM = 1024

# ---- Milvus 連線 & collection ----
connections.connect(alias="default", host=MILVUS_HOST, port=MILVUS_PORT)
collection = Collection(COLLECTION_NAME)
collection.load()

# ---- BGE-m3 模型（跟 index 用同一個）----
device = "cuda"  # 或 "cpu"
bge_model = BGEM3FlagModel("BAAI/bge-m3", device=device, use_fp16=(device == "cuda"))


def embed_query(text: str):
    vec = bge_model.encode([text])["dense_vecs"][0]
    return [float(x) for x in vec]


def search_knowledge(query: str, top_k: int = 5) -> List[Dict]:
    """
    回傳 top_k 筆相關段落：
    [{title, url, content, score}, ...]
    """
    q_vec = embed_query(query)

    search_params = {
        "metric_type": "COSINE",
        "params": {"nprobe": 10}
    }

    results = collection.search(
        data=[q_vec],
        anns_field="embedding",
        param=search_params,
        limit=top_k,
        output_fields=["title", "url", "content"]
    )

    hits = results[0]
    out = []
    for h in hits:
        ent = h.entity
        out.append({
            "title": ent.get("title"),
            "url": ent.get("url"),
            "content": ent.get("content"),
            "score": float(h.distance),
        })
    return out
