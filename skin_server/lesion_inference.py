import torch
from torchvision import transforms
from PIL import Image
import os

# ----------------------------------------------------------
# 強制使用 GPU，不再自動 fallback
# ----------------------------------------------------------
device = torch.device("cuda:0")  # ✅ 只用 GPU

MODEL_PATH = "model/lesion_vit_scripted.pt"
LABELS_PATH = "model/lession_labels.txt"

assert os.path.exists(MODEL_PATH), f"找不到模型檔案: {MODEL_PATH}"
lesion_model = torch.jit.load(MODEL_PATH, map_location="cuda:0").to(device)  # ✅ 放在 GPU
lesion_model.eval()

assert os.path.exists(LABELS_PATH), f"找不到標籤檔案: {LABELS_PATH}"
with open(LABELS_PATH, "r", encoding="utf-8") as f:
    lesion_labels = [line.strip() for line in f.readlines()]

transform = transforms.Compose([
    transforms.Resize(256),
    transforms.CenterCrop(224),
    transforms.ToTensor(),
    transforms.Normalize([0.485, 0.456, 0.406],
                         [0.229, 0.224, 0.225])
])

@torch.inference_mode()  # ✅ 推論模式，避免梯度記錄
def predict_lesion(image_path: str, threshold: float = 0.5) -> dict:
    # 讀取圖片並轉 tensor
    image = Image.open(image_path).convert("RGB")
    x = transform(image).unsqueeze(0).to(device)  # ✅ 移到 GPU

    logits = lesion_model(x)                      # ✅ GPU 推論
    probs = torch.sigmoid(logits)[0]

    # 篩選出高於門檻的病變
    lesion_results = []
    for i, p in enumerate(probs):
        if p.item() > threshold:
            lesion_results.append({
                "label": lesion_labels[i],
                "confidence": round(p.item(), 2)
            })

    # Top-3 結果
    top3 = torch.topk(probs, k=min(3, len(probs)))
    top3_predictions = [{
        "label": lesion_labels[idx.item()],
        "confidence": round(val.item(), 2)
    } for val, idx in zip(top3.values, top3.indices)]

    return {"lesions": lesion_results, "top3": top3_predictions}
