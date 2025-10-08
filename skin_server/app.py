from flask import Flask, request, jsonify
from flask_cors import CORS
from datetime import datetime
import os
from inference import predict_skin_disease

app = Flask(__name__)
CORS(app)

UPLOAD_DIR = "static/uploads"
os.makedirs(UPLOAD_DIR, exist_ok=True)

@app.route("/analyze", methods=["POST"])
def analyze():
    f = request.files.get("image")
    if not f or f.filename == "":
        return jsonify({"error": "No image"}), 400

    filename = datetime.now().strftime("%Y%m%d_%H%M%S_") + f.filename
    path = os.path.join(UPLOAD_DIR, filename).replace("\\", "/")
    f.save(path)

    pred = predict_skin_disease(path)
    return jsonify({
        "message": "success",
        "image_path": path,
        "prediction": pred
    })

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
