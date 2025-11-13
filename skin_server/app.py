# app.py
from flask import Flask, request, jsonify
import os
from combined_inference import predict_combined

app = Flask(__name__)
UPLOAD_FOLDER = "uploads"
os.makedirs(UPLOAD_FOLDER, exist_ok=True)


@app.route("/predict_combined", methods=["POST"])
def predict_combined_api():
    if "image" not in request.files:
        return jsonify({"error": "未上傳圖片"}), 400

    image = request.files["image"]
    img_path = os.path.join(UPLOAD_FOLDER, image.filename)
    image.save(img_path)

    patient_report = request.form.get("patient_report", "").strip()

    try:
        # ✅ 改這裡 — 原本錯誤是 save_path 未定義
        result = predict_combined(img_path)
        print("[DEBUG] Prediction result:", result)
        return jsonify(result)
    except Exception as e:
        import traceback
        print("❌ Flask 內部錯誤:", e)
        traceback.print_exc()
        return jsonify({"error": str(e)}), 500




# 你原本的 /analyze 還保留，不影響
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
    app.run(host="0.0.0.0", port=5000)
