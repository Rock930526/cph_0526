# app.py
from flask import Flask, request, jsonify
import os
import json

from combined_inference import predict_combined

app = Flask(__name__)
UPLOAD_FOLDER = "uploads"
os.makedirs(UPLOAD_FOLDER, exist_ok=True)


@app.route("/predict_combined", methods=["POST"])
def predict_combined_api():
    """
    單一入口：
    - 接收圖片 + 問卷 JSON（欄位名：survey）
    - 呼叫兩階段推論（影像模型 + DeepSeek + RAG + DeepSeek）
    """
    if "image" not in request.files:
        return jsonify({"error": "未上傳圖片"}), 400

    image = request.files["image"]
    img_path = os.path.join(UPLOAD_FOLDER, image.filename)
    image.save(img_path)

    # 問卷 JSON（可為空）
    survey_raw = request.form.get("survey", "")
    survey = {}
    if survey_raw:
        try:
            survey = json.loads(survey_raw)
        except Exception as e:
            print("⚠️ survey JSON 解析失敗:", e)

    try:
        result = predict_combined(img_path, survey)
        print("[DEBUG] Prediction result:", result)
        return jsonify(result)
    except Exception as e:
        import traceback
        print("❌ Flask 內部錯誤:", e)
        traceback.print_exc()
        return jsonify({"error": str(e)}), 500


# 保留原本 /analyze（如果你還有用）
from inference import predict_image
from lesion_inference import predict_lesion


@app.route("/analyze", methods=["POST"])
def analyze():
    if "image" not in request.files:
        return jsonify({"error": "未上傳圖片"}), 400

    img = request.files["image"]
    img_path = os.path.join(UPLOAD_FOLDER, img.filename)
    img.save(img_path)

    try:
        disease_result = predict_image(img_path)
        lesion_result = predict_lesion(img_path)
        response = {
            "prediction": {
                "disease": disease_result,
                "lesion": lesion_result,
                "summary": (
                    f"模型辨識為 {disease_result['class_name']} "
                    f"(信心 {disease_result['confidence']*100:.1f}%)，"
                    f"偵測到病變特徵："
                    f"{', '.join([x['label'] for x in lesion_result.get('lesions', [])]) or '無特徵'}。"
                )
            }
        }
        return jsonify(response)
    except Exception as e:
        return jsonify({"error": str(e)}), 500


if __name__ == "__main__":
    # 0.0.0.0 代表可以讓手機從區網連進來
    app.run(host="0.0.0.0", port=5000, debug=True)
