# app.py
from flask import Flask, request, jsonify
from inference import predict_image
import os
from werkzeug.utils import secure_filename

app = Flask(__name__)

# === 上傳資料夾設定 ===
UPLOAD_FOLDER = "static/uploads"   # 改成放在 static 內方便前端顯示
ALLOWED_EXTENSIONS = {"jpg", "jpeg", "png"}

os.makedirs(UPLOAD_FOLDER, exist_ok=True)

def allowed_file(filename):
    return "." in filename and filename.rsplit(".", 1)[1].lower() in ALLOWED_EXTENSIONS

# === 路由：圖片分析 ===
@app.route("/analyze", methods=["POST"])
def analyze():
    # 檢查是否有 file 這個欄位
    if "file" not in request.files:
        return jsonify({"error": "No file uploaded"}), 400

    file = request.files["file"]

    # 檢查是否有選檔案
    if file.filename == "":
        return jsonify({"error": "No selected file"}), 400

    # 檢查副檔名是否合法
    if not allowed_file(file.filename):
        return jsonify({"error": "Invalid file type"}), 400

    # 儲存圖片
    filename = secure_filename(file.filename)
    filepath = os.path.join(UPLOAD_FOLDER, filename)
    file.save(filepath)

    try:
        result = predict_image(filepath)
        return jsonify({
            "image_path": filepath,
            "message": "success",
            "prediction": result
        })
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == "__main__":
    # host="0.0.0.0" 代表允許外部連線，例如手機或另一台電腦
    app.run(host="0.0.0.0", port=5000)
