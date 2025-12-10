# lesion_model.py
import torch
import timm
from PIL import Image
from torchvision import transforms

DEVICE = torch.device("cuda" if torch.cuda.is_available() else "cpu")

MODEL_PATH = "best_model.pth"  # 你現在放在 skin_server 底下的那顆

# -----------------------------
# 1. 載入模型（你的 convnext_tiny）
# -----------------------------
def load_model(ckpt_path: str):
    ckpt = torch.load(ckpt_path, map_location=DEVICE)

    model_name = ckpt["model_name"]
    classes = ckpt["classes"]
    num_classes = len(classes)

    model = timm.create_model(
        model_name,
        pretrained=False,
        num_classes=num_classes
    )
    model.load_state_dict(ckpt["model_state"])
    model.to(DEVICE)
    model.eval()

    return model, classes


# -----------------------------
# 2. 圖片前處理
# -----------------------------
transform = transforms.Compose([
    transforms.Resize((224, 224)),
    transforms.ToTensor(),
    transforms.Normalize(
        mean=[0.485, 0.456, 0.406],
        std=[0.229, 0.224, 0.225]
    )
])

print("🚀 載入 ConvNeXt 皮膚病灶模型中...")
lesion_model, lesion_classes = load_model(MODEL_PATH)
print(f"✅ 模型載入完成，共有 {len(lesion_classes)} 個類別")


# -----------------------------
# 3. 單張圖片推論
# -----------------------------
@torch.inference_mode()
def predict_lesion(image_path: str):
    """
    使用 ConvNeXt 模型做單張分類，回傳：
    {
      "top1": { "label": ..., "confidence": ... },
      "top3": [ {label, confidence}, ... ]
    }
    """
    img = Image.open(image_path).convert("RGB")
    x = transform(img).unsqueeze(0).to(DEVICE)

    outputs = lesion_model(x)
    probs = torch.softmax(outputs, dim=1)[0]

    # Top1
    top1_prob, top1_idx = torch.max(probs, dim=0)
    top1_label = lesion_classes[top1_idx.item()]

    # Top3
    top3_prob, top3_idx = torch.topk(probs, k=min(3, probs.shape[0]))
    top3 = []
    for prob, idx in zip(top3_prob, top3_idx):
        top3.append({
            "label": lesion_classes[idx.item()],
            "confidence": float(round(prob.item(), 3))
        })

    return {
        "top1": {
            "label": top1_label,
            "confidence": float(round(top1_prob.item(), 3)),
        },
        "top3": top3
    }
