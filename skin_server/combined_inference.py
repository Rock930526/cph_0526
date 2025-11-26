# ============================================================
# combined_inference.py — 兩階段推論：
#   1) 影像模型 + 問卷 + DeepSeek (初步可能診斷)
#   2) 根據候選診斷做 RAG + DeepSeek (最終整合)
# ============================================================

import json
from typing import Dict, Any, List, Optional

import requests

from inference import predict_image
from lesion_inference import predict_lesion
from rag_milvus import search_knowledge

# 惡性病變種類
MALIGNANT = {"MEL", "BCC", "AKIEC"}

# Ollama 伺服器（DeepSeek-R1 14B）
OLLAMA_URL = "http://127.0.0.1:11434/api/generate"
LLM_MODEL = "deepseek-r1:14b"


# ------------------------------------------------------------
# 工具：從 SwinV2 結果中只取一個 lesion top1（從 lesions 排序）
# ------------------------------------------------------------
def get_lesion_top1(lesion: Dict[str, Any]) -> Dict[str, Any]:
    lesions = lesion.get("lesions") or []
    if not lesions:
        return {}

    # 從 lesions 裡用 confidence 排序取第一個
    top1 = max(lesions, key=lambda x: x.get("confidence", 0.0))
    return {
        "label": top1.get("label"),
        "confidence": float(top1.get("confidence", 0.0)),
    }


# ------------------------------------------------------------
# DeepSeek 第一階段 Prompt：不含 RAG，只看症狀 + 影像訊息
# ------------------------------------------------------------
def build_first_prompt(
    disease: Dict[str, Any],
    lesion_top1: Dict[str, Any],
    survey: Dict[str, Any],
) -> str:
    sb: List[str] = []

    sb.append("你是一位協助台灣皮膚科門診的臨床輔助系統。")
    sb.append("在第一階段，你只能根據：")
    sb.append("1. 患者填寫的症狀與病程問卷")
    sb.append("2. 影像模型提供的外觀與病變資訊（僅作參考，不可完全依賴）")
    sb.append("")
    sb.append("⚠️ 此階段「可以」引用任何外部醫學資料或教科書內容，不需只根據我給的資訊做初步推論。")
    sb.append("請輸出 JSON 格式，不要加註解或多餘文字，格式如下：")
    sb.append(
        """
{
  "candidates": ["疾病名稱1", "疾病名稱2", "..."],
  "reasoning": "你根據問卷與外觀做出的推理說明（繁體中文）"
}
        """.strip()
    )
    sb.append("")
    sb.append("=== 影像模型結果（僅供參考） ===")

    if disease:
        sb.append(
            f"- 疾病模型 top1：{disease.get('class_name', '未知')} "
            f"(信心 {disease.get('confidence', 0.0)*100:.1f}%)"
        )
        top3 = disease.get("top3") or []
        if top3:
            sb.append("- 疾病模型 top3：")
            for i, item in enumerate(top3, start=1):
                sb.append(
                    f"  {i}. {item.get('label', '未知')} "
                    f"({item.get('confidence', 0.0)*100:.1f}%)"
                )

    if lesion_top1:
        sb.append(
            f"- 病變模型主要特徵：{lesion_top1.get('label', '未知')} "
            f"(信心 {lesion_top1.get('confidence', 0.0)*100:.1f}%)"
        )

    sb.append("")
    sb.append("=== 患者問卷內容（原始 JSON） ===")
    sb.append(json.dumps(survey, ensure_ascii=False, indent=2))

    sb.append("")
    sb.append("請根據以上資訊，產出最有可能的 3~5 個皮膚疾病候選（常見名稱即可），")
    sb.append("並以 JSON 回覆（只允許上述欄位）。")

    return "\n".join(sb)


# ------------------------------------------------------------
# DeepSeek 第二階段 Prompt：整合 RAG + 第一階段結果
# ------------------------------------------------------------
def build_second_prompt(
    disease: Dict[str, Any],
    lesion_top1: Dict[str, Any],
    survey: Dict[str, Any],
    candidates: List[str],
    first_reasoning: str,
    rag_info: List[Dict[str, Any]],
    model_summary: str,
) -> str:
    sb: List[str] = []

    sb.append("你是一套台灣皮膚科臨床輔助系統，現在進入第二階段：")
    sb.append("可以使用下列來源作為判斷依據（依重要性排序）：")
    sb.append("1. 患者問卷與自述")
    sb.append("2. RAG 提供的皮膚科醫學內容（唯一可靠醫療知識來源）")
    sb.append("3. 第一階段推論與影像模型結果（僅作輔助，不得凌駕症狀與 RAG）")
    sb.append("")
    sb.append("⚠️ 嚴格規則：")
    sb.append("．禁止使用你自身的醫學知識，只能引用我提供的 RAG 文字內容。")
    sb.append("．若某疾病未出現在 RAG 中，不要過度延伸，只能說『資訊不足』。")
    sb.append("．避免使用藥品商品名，只能提到『含有某成分的外用藥』之類描述。")
    sb.append("．輸出全部使用繁體中文，語氣中立、專業、易懂。")
    sb.append("")
    sb.append("=== 第一階段推論（來自 DeepSeek） ===")
    sb.append("候選疾病列表：")
    for i, c in enumerate(candidates, start=1):
        sb.append(f"{i}. {c}")
    sb.append("")
    sb.append("第一階段推理摘要：")
    sb.append(first_reasoning or "（無）")
    sb.append("")
    sb.append("=== 影像模型摘要（僅供弱參考） ===")
    sb.append(model_summary)
    if lesion_top1:
        sb.append(
            f"病變主要特徵：{lesion_top1.get('label', '未知')} "
            f"(信心 {lesion_top1.get('confidence', 0.0)*100:.1f}%)"
        )
    sb.append("")
    sb.append("=== 患者問卷內容（JSON） ===")
    sb.append(json.dumps(survey, ensure_ascii=False, indent=2))

    sb.append("")
    sb.append("=== RAG 醫學資料（你唯一能引用的醫療知識） ===")
    if not rag_info:
        sb.append("（未找到相關 RAG 資料，如資訊不足請清楚說明不確定性）")
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
    sb.append("=== 請依下列結構輸出最終評估（繁體中文） ===")
    sb.append("一、可能診斷：")
    sb.append("．列出 2–4 個最可能的診斷，並說明症狀與 RAG 哪些部分支持該診斷。")
    sb.append("")
    sb.append("二、鑑別診斷：")
    sb.append("．說明幾個需要區分的其他疾病，強調外觀／分佈／病程上的差異。")
    sb.append("")
    sb.append("三、居家照護與日常建議：")
    sb.append("．提供清潔、保濕、避免刺激與生活作息建議。")
    sb.append("．若提到用藥，只能描述『含有某成分的外用藥物』，不得寫商品名。")
    sb.append("")
    sb.append("四、就醫與警訊：")
    sb.append("．說明什麼情況下應儘速就醫，如快速惡化、滲液、劇痛、臉部或生殖部位病灶等。")
    sb.append("．若懷疑有惡性病變可能，需明確標註並提醒就醫。")

    return "\n".join(sb)


# ------------------------------------------------------------
# DeepSeek 呼叫工具
# ------------------------------------------------------------
def call_llm(prompt: str) -> str:
    payload = {
        "model": LLM_MODEL,
        "prompt": prompt,
        "stream": False,
        "temperature": 0.7,
    }
    resp = requests.post(OLLAMA_URL, json=payload)
    resp.raise_for_status()
    data = resp.json()
    # Ollama /generate 預設欄位叫 "response"
    return data.get("response", "")


# ------------------------------------------------------------
# 主流程：兩階段推論 + RAG
# ------------------------------------------------------------
def predict_combined(
    image_path: str,
    survey: Optional[Dict[str, Any]] = None,
) -> Dict[str, Any]:
    if survey is None:
        survey = {}

    try:
        # 1️⃣ 影像模型：疾病分類
        disease = predict_image(image_path)

        # 2️⃣ 影像模型：病變分類（SwinV2）
        lesion = predict_lesion(image_path)
        lesion_top1 = get_lesion_top1(lesion)
        lesion["top1"] = lesion_top1  # 補充寫回去方便前端或日後使用

        # 3️⃣ 惡性風險分析（沿用你原本邏輯）
        risk_flag = "🟢 良性可能性高"
        for item in lesion.get("top3", []):
            label = item.get("label", "")
            conf = item.get("confidence", 0)
            if label in MALIGNANT:
                if conf >= 0.85:
                    risk_flag = "🔴 高度懷疑惡性，建議盡速就醫"
                elif conf >= 0.70:
                    risk_flag = "🟡 病灶有疑似惡性特徵，建議觀察或就醫"
                else:
                    risk_flag = "🟢 無明顯惡性特徵"

        # 4️⃣ 模型端摘要（給第二階段用）
        lesion_names = [x["label"] for x in lesion.get("top3", [])]
        summary = (
            f"疾病模型預測為 {disease['class_name']}（信心 {disease['confidence']*100:.1f}%）；"
            f"病變模型偵測到主要特徵：{', '.join(lesion_names) or '無'}。"
        )

        # ===============================
        #   第一階段 DeepSeek：候選診斷
        # ===============================
        first_prompt = build_first_prompt(disease, lesion_top1, survey)
        first_raw = call_llm(first_prompt)

        # 解析第一階段 JSON
        candidates: List[str] = []
        reasoning = ""
        try:
            first_json = json.loads(first_raw)
            if isinstance(first_json, dict):
                c_list = first_json.get("candidates") or []
                candidates = [str(x) for x in c_list if isinstance(x, str)]
                reasoning = str(first_json.get("reasoning") or "")
        except Exception:
            # 解析失敗就 fallback：用疾病模型 class_name 當唯一候選
            candidates = [disease.get("class_name", "")]
            reasoning = first_raw

        if not candidates:
            candidates = [disease.get("class_name", "")]

        # ===============================
        #   第二階段：RAG + DeepSeek
        # ===============================
        # 對每個候選診斷做 RAG 搜尋
        rag_info: List[Dict[str, Any]] = []
        seen_keys = set()
        for c in candidates:
            if not c:
                continue
            results = search_knowledge(c, top_k=3)
            for r in results:
                title = r.get("title") or ""
                url = r.get("url") or ""
                key = (title, url)
                if key in seen_keys:
                    continue
                seen_keys.add(key)
                rag_info.append(r)

        second_prompt = build_second_prompt(
            disease=disease,
            lesion_top1=lesion_top1,
            survey=survey,
            candidates=candidates,
            first_reasoning=reasoning,
            rag_info=rag_info,
            model_summary=summary,
        )
        final_text = call_llm(second_prompt)

        # 統一一些變數名稱給 return 用
        rag_results = rag_info
        final_candidates = candidates
        final_top1 = final_candidates[0] if final_candidates else "無法判定"

        # 最後統一回傳格式
        return {
            "disease": disease,        # 原始疾病模型結果
            "lesion": lesion,          # 原始病變模型結果（含 top1）
            "lesion_top1": lesion_top1,
            "rag": rag_results,        # RAG 段落
            "risk_flag": risk_flag,
            "summary": summary,

            # 第一階段 debug 資訊（保留給你看用）
            "first_pass": {
                "raw_response": first_raw,
                "candidates": candidates,
                "reasoning": reasoning,
            },

            # ✅ 這三個是給 Flutter 用的新 API
            "final_top1": final_top1,
            "final_candidates": final_candidates,
            "final_text": final_text,
        }

    except Exception as e:
        import traceback
        traceback.print_exc()
        return {
            "error": str(e),
            "summary": "⚠️ 推論過程中發生錯誤",
            "rag": [],
            "final_text": "系統在分析過程中發生錯誤，請稍後再試或洽系統管理者。",
        }
