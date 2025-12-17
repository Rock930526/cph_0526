# app.py
from flask import Flask, request, jsonify
import os
import json

# ✅ 你的 ConvNeXt 病灶模型推論
from lesion_model import predict_lesion

# ✅ ConvNeXt + RAG + LLM 的整合流程
from combined_inference import predict_combined

app = Flask(__name__)
UPLOAD_FOLDER = "uploads"
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

print("🚀 Flask 伺服器啟動中（單一 ConvNeXt + RAG + LLM）...")


# ==============================================================
# 1. /predict_combined —— Flutter 主要用的 API
# ==============================================================
@app.route("/predict_combined", methods=["POST"])
def predict_combined_api():
    # 一定要有 image
    if "image" not in request.files:
        return jsonify({"error": "未上傳圖片"}), 400

    image = request.files["image"]
    img_path = os.path.join(UPLOAD_FOLDER, image.filename)
    image.save(img_path)

    # 問卷目前先不太用，但保留欄位
    survey_raw = request.form.get("survey", "")
    survey = {}
    if survey_raw:
        try:
            survey = json.loads(survey_raw)
        except Exception as e:
            print("⚠️ survey JSON 解析失敗：", e)

    try:
        # ⭐ 核心：呼叫你寫好的 combined_inference
        result = predict_combined(img_path, survey)

        # Flutter 只吃這兩個
        top1 = result.get("final_top1") or "無資料"
        report = result.get("final_text") or "（無 LLM 回覆）"

        return jsonify({
            "top1": top1,
            "report": report,
        }), 200

    except Exception as e:
        import traceback
        traceback.print_exc()
        return jsonify({"error": str(e)}), 500


# ==============================================================
# 2. /analyze —— Debug 用，只回 ConvNeXt 模型原始結果
# ==============================================================
@app.route("/analyze", methods=["POST"])
def analyze():
    if "image" not in request.files:
        return jsonify({"error": "未上傳圖片"}), 400

    img = request.files["image"]
    img_path = os.path.join(UPLOAD_FOLDER, img.filename)
    image_name = img.filename
    img.save(img_path)

    try:
        lesion_result = predict_lesion(img_path)
        return jsonify({
            "image": image_name,
            "lesion_raw": lesion_result,
        }), 200

    except Exception as e:
        import traceback
        traceback.print_exc()
        return jsonify({"error": str(e)}), 500



# ==============================================================
# 4. LLM 問答（Chat）API —— 不需要圖片、不需要模型
# ==============================================================
from combined_inference import ask_llm

@app.route("/ask_llm", methods=["POST"])
def ask_llm_api():
    try:
        data = request.get_json()
        prompt = data.get("question", "").strip()

        if not prompt:
            return jsonify({"error": "指令 不可為空"}), 400

        print("🧠 LLM 問答請求：", prompt)

        # 呼叫 LLM（DeepSeek）
        answer = ask_llm(prompt)

        return jsonify({"answer": answer}), 200

    except Exception as e:
        import traceback
        traceback.print_exc()
        return jsonify({"error": str(e)}), 500

# ==============================================================
# 3. 入口 —— 一定要 host=0.0.0.0, threaded=True
# ==============================================================
if __name__ == "__main__":
    # 一律用 python app.py 啟動，不要用 flask run
    app.run(
        host="0.0.0.0",
        port=5000,
        debug=True,
        threaded=True,   # 讓每個 request 各跑一條 thread
    )