# ============================================================
# combined_inference.py  —  模型辨識 + RAG（DermNet 中文知識庫）
# ============================================================
import torch
from inference import predict_image
from lesion_inference import predict_lesion

# Milvus RAG（為了避免循環 import）
from rag_milvus import search_knowledge


# 惡性病變標籤
MALIGNANT = {"MEL", "BCC", "AKIEC"}


def predict_combined(image_path: str, patient_report: str = "") -> dict:
    """
    系統主入口：疾病分類 + 病變分類 + RAG 衛教搜尋
    """

    try:
        # --------------------------
        # 1️⃣ 病灶辨識（ConvNeXt）
        # --------------------------
        disease = predict_image(image_path)

        # --------------------------
        # 2️⃣ 病變偵測（SwinV2）
        # --------------------------
        lesion = predict_lesion(image_path)

        # --------------------------
        # 3️⃣ 惡性風險分析
        # --------------------------
        risk_flag = "🟢 良性可能性高"
        for item in lesion.get("top3", []):
            if label in MALIGNANT:
                if conf >= 0.85:
                    risk_flag = "🔴 高度懷疑惡性，建議盡速就醫"
            elif conf >= 0.70:
                    risk_flag = "🟡 病灶有疑似惡性特徵，建議觀察或就醫"
            else:
                    risk_flag = "🟢 無明顯惡性特徵"

        # --------------------------
        # 4️⃣ 建立摘要（模型端）
        # --------------------------
        lesion_names = [x["label"] for x in lesion.get("top3", [])]

        summary = (
            f"疾病模型預測為 {disease['class_name']}（信心 {disease['confidence']*100:.1f}%）；"
            f"病變模型偵測到主要特徵：{', '.join(lesion_names) or '無'}。"
        )

        # --------------------------
        # 5️⃣ RAG 查詢（DermNet 中文資料庫）
        # --------------------------
        # 查詢使用「模型預測 + 患者自述」→ 更貼近臨床
        rag_query = f"{disease['class_name']} {patient_report}".strip()

        rag_results = search_knowledge(rag_query, top_k=5)

        # 測試版：若沒有找到資料，回傳「找不到」
        if not rag_results:
            rag_info = [{
                "title": "查無資料",
                "content": "測試版：尚未查找到相關可信醫療資料，請改用其他關鍵字。"
            }]
        else:
            rag_info = rag_results

        # --------------------------
        # ⚠️ 正式版（未啟用，僅註解）
        # --------------------------
        # 若找不到資料：
        #   1. 將 rag_query 丟給 Google/SerpAPI
        #   2. 擷取衛教段落（皮膚科權威）
        #   3. 過濾非醫療網站
        #
        # will_enable_in_final_version(rag_query)

        # --------------------------
        # 6️⃣ 回傳整合結果
        # --------------------------
        return {
            "disease": disease,
            "lesion": lesion,
            "risk_flag": risk_flag,
            "summary": summary,
            "rag": rag_info  # ← LLM 將依此內容撰寫衛教，不會亂掰
        }

    except Exception as e:
        return {
            "error": str(e),
            "summary": "⚠️ 推論過程中發生錯誤",
            "rag": []
        }
