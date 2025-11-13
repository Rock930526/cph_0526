# ============================================================
# combined_inference.py
# ============================================================
import torch
from inference import predict_image         # 疾病分類（ConvNeXt）
from lesion_inference import predict_lesion # 病變分類（SwinV2）

# 依照你目前使用的 lesion_labels.txt 內容調整
MALIGNANT = {"MEL", "BCC", "AKIEC"}

def predict_combined(image_path: str) -> dict:
    try:
        disease = predict_image(image_path)
        lesion  = predict_lesion(image_path)

        # 風險旗標
        risk_flag = "🟢 Likely benign"
        for item in lesion.get("top3", []):
            if item["label"] in MALIGNANT and item["confidence"] >= 0.5:
                risk_flag = "⚠️ Possible malignant lesion"
                break

        lesion_names = [x["label"] for x in lesion.get("top3", [])]
        summary = (
            f"疾病模型預測為 {disease['class_name']} "
            f"(信心 {disease['confidence']*100:.1f}%)；"
            f"病變模型偵測到主要特徵：{', '.join(lesion_names) or '無'}。"
        )

        return {
            "disease": disease,
            "lesion": lesion,
            "risk_flag": risk_flag,
            "summary": summary
        }
    except Exception as e:
        return {"error": str(e), "summary": "⚠️ 推論過程中發生錯誤"}
