# inference.py（使用 skinconvnext_scripted.pt）
import torch
from torchvision import transforms
from PIL import Image
import os

# 模型與標籤檔案位置
MODEL_PATH = "model/skinconvnext_scripted.pt"
LABELS_PATH = "model/labels.txt"

device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

# 載入 TorchScript 模型
assert os.path.exists(MODEL_PATH), f"找不到模型檔案: {MODEL_PATH}"
model = torch.jit.load(MODEL_PATH, map_location=device)
model.eval()

# 載入疾病標籤
assert os.path.exists(LABELS_PATH), f"找不到標籤檔案: {LABELS_PATH}"
with open(LABELS_PATH, "r", encoding="utf-8") as f:
    id2label = [line.strip() for line in f.readlines()]

# 預處理流程（與訓練一致）
#transform = transforms.Compose([
    #transforms.Resize((224, 224)),
    #transforms.ToTensor(),
    #transforms.Normalize([0.485, 0.456, 0.406],
                         #[0.229, 0.224, 0.225])
#])

transform = transforms.Compose([
    transforms.Resize(256),
    transforms.CenterCrop(224),   # 增加這一行，強制病灶置中
    transforms.ToTensor(),
    transforms.Normalize([0.485, 0.456, 0.406],  # 可以先保留
                         [0.229, 0.224, 0.225])
])




def predict_image(image_path: str) -> dict:
    image = Image.open(image_path).convert("RGB")
    x = transform(image).unsqueeze(0).to(device)

    with torch.no_grad():
        logits = model(x)
        probs = torch.softmax(logits, dim=1)[0]
        confidence, class_idx = torch.max(probs, dim=0)

    class_idx = int(class_idx.item())
    confidence = float(confidence.item())
    class_name = id2label[class_idx] if class_idx < len(id2label) else str(class_idx)

    summary = f"This image is most likely showing a skin condition consistent with '{class_name}' with {confidence:.1%} confidence."

    # 列出 top-3 預測結果
    top3 = torch.topk(probs, k=3)
    top3_predictions = []
    for i in range(3):
        idx = top3.indices[i].item()
        label = id2label[idx] if idx < len(id2label) else str(idx)
        score = top3.values[i].item()
        top3_predictions.append({"label": label, "confidence": round(score, 4)})

    return {
        "class_id": class_idx,
        "class_name": class_name,
        "confidence": round(confidence, 2),
        "summary": summary,
        "top3": top3_predictions
    }
