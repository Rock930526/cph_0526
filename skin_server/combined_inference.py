# combined_inference.py
# 單階段流程：
#   ConvNeXt 影像分類 → RAG（Milvus）→ DeepSeek LLM 報告

import json
from typing import Dict, Any, List, Optional

import requests

from lesion_model import predict_lesion
from rag_milvus import search_knowledge

# Ollama 伺服器（DeepSeek-R1 14B）
OLLAMA_URL = "http://127.0.0.1:11434/api/generate"
LLM_MODEL = "deepseek-r1:14b"


# ---------------------------
# 風險評估（依目前 8 類中文標籤）
# ---------------------------
def compute_risk_flag(top1_label: str, conf: float) -> str:
    """
    依照分類結果給一個大概的風險等級字串。
    你之後覺得不合理可以再調這裡就好。
    """
    malignant = {"基底細胞癌", "鱗狀細胞癌"}
    pre_malignant = {"光化性角化"}

    if top1_label in malignant and conf >= 0.50:
        return "🔴 影像顯示疑似皮膚惡性腫瘤，建議儘速就醫，由皮膚科醫師面診確認。"
    if top1_label in pre_malignant and conf >= 0.50:
        return "🟡 影像顯示可能為癌前病變，建議儘早安排皮膚科門診追蹤。"
    return "🟢 目前分類多偏向良性病灶，但仍建議依實際症狀與醫師評估為主。"


# ---------------------------
# LLM 報告用的 Prompt
# ---------------------------
def build_report_prompt(
    lesion: Dict[str, Any],
    rag_info: List[Dict[str, Any]],
    risk_flag: str,
) -> str:
    top1 = lesion.get("top1", {})
    top3 = lesion.get("top3", [])

    label = top1.get("label", "未知病灶")
    conf = float(top1.get("confidence", 0.0)) * 100.0

    sb: List[str] = []

    sb.append("你是一套協助台灣皮膚科門診的臨床決策輔助系統。")
    sb.append("你只能根據我提供的 RAG 醫學內容與模型輸出進行說明，不可以自行延伸額外醫學知識。")
    sb.append("請用繁體中文，語氣中立且易懂，回答給一般民眾閱讀。")
    sb.append("")
    sb.append("=== 影像 AI 分類結果（僅供參考，非正式診斷） ===")
    sb.append(f"- 模型主要分類結果：{label}（信心約 {conf:.1f}%）")
    if top3:
        sb.append("- Top3 可能結果：")
        for i, item in enumerate(top3, start=1):
            sb.append(
                f"  {i}. {item.get('label', '未知')} "
                f"(約 {float(item.get('confidence', 0.0))*100:.1f}%)"
            )
    sb.append("")
    sb.append("=== 風險提示（系統內規則評估） ===")
    sb.append(risk_flag)
    sb.append("")
    sb.append("=== 可使用的醫學知識（RAG 查詢結果） ===")

    if not rag_info:
        sb.append("（目前資料庫中沒有找到與此病名相符的條目，請你明確說明資訊有限。）")
    else:
        for i, item in enumerate(rag_info, start=1):
            title = item.get("title") or "未命名條目"
            content = item.get("content") or ""
            url = item.get("url") or ""
            sb.append(f"【資料 {i}：{title}】")
            if url:
                sb.append(f"來源連結：{url}")
            sb.append(content)
            sb.append("")

    sb.append("")
    sb.append("=== 回覆要求 ===")
    sb.append("請依照下面結構，整理一份給民眾看的說明：")
    sb.append("一、此類皮膚病灶的簡介（依照 RAG 內容，不要加入額外知識）。")
    sb.append("二、常見的症狀與外觀特徵（盡量對應 RAG 內容）。")
    sb.append("三、可能的風險與需要注意的情況（結合上述風險提示與 RAG）。")
    sb.append("四、居家照護與日常注意事項（清潔、保濕、避免刺激等，一樣要以 RAG 內容為主）。")
    sb.append("五、何時應該就醫或回診，特別是哪些警訊需要儘速就醫。")
    sb.append("")
    sb.append("請以條列與短段落整理，讓一般民眾可以看懂。")

    return "\n".join(sb)


# ---------------------------
# 呼叫 Ollama LLM
# ---------------------------
def call_llm(prompt: str) -> str:
    payload = {
        "model": LLM_MODEL,
        "prompt": prompt,
        "stream": False,
        "temperature": 0.7,
    }
    resp = requests.post(OLLAMA_URL, json=payload, timeout=300)
    resp.raise_for_status()
    data = resp.json()
    return data.get("response", "")


# ---------------------------
# 主流程：影像 → RAG → LLM
# ---------------------------
def predict_combined(
    image_path: str,
    survey: Optional[Dict[str, Any]] = None,  # 現在不再使用問卷，但保留參數避免爆掉
) -> Dict[str, Any]:
    try:
        # 1️⃣ ConvNeXt 影像分類
        lesion = predict_lesion(image_path)
        top1 = lesion.get("top1", {})
        top1_label = top1.get("label", "未知")
        top1_conf = float(top1.get("confidence", 0.0))

        # 2️⃣ 風險簡易評估
        risk_flag = compute_risk_flag(top1_label, top1_conf)

        # 3️⃣ RAG：用 top1 label 去 DermNet / Milvus 搜尋
        rag_info: List[Dict[str, Any]] = search_knowledge(top1_label, top_k=5)

        # 4️⃣ 建立 LLM Prompt + 呼叫 DeepSeek
        prompt = build_report_prompt(lesion, rag_info, risk_flag)

        try:
            final_text = call_llm(prompt)
        except Exception as llm_err:
            print("⚠️ LLM 呼叫失敗：", llm_err)
            final_text = "系統在產生說明文字時發生錯誤，但影像分類結果仍可供醫師參考。"

        # 5️⃣ 簡短 summary（方便 log / debug）
        top3_labels = [x.get("label", "") for x in lesion.get("top3", [])]
        summary = (
            f"AI 主要分類結果：{top1_label}（約 {top1_conf*100:.1f}%）；"
            f"Top3 依序為：{', '.join(top3_labels) or '無'}。"
        )

        return {
            "lesion": lesion,              # 影像模型原始結果
            "rag": rag_info,               # RAG 取回的醫學內容
            "risk_flag": risk_flag,        # 風險文字
            "summary": summary,            # 簡短摘要
            "final_top1": top1_label,      # 給前端用的主要結果
            "final_text": final_text,      # LLM 報告
        }

    except Exception as e:
        import traceback
        traceback.print_exc()
        return {
            "error": str(e),
            "summary": "⚠️ 推論過程中發生錯誤",
            "rag": [],
            "final_top1": "無資料",
            "final_text": "系統在分析過程中發生錯誤，請稍後再試或洽系統管理者。",
        }
