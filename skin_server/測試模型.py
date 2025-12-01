import torch
import torch.nn.functional as F
import timm
from PIL import Image
from torchvision import transforms

# ==========================
# 類別（與訓練一致）
# ==========================
class_names = [
    '光化性角化',
    '基底細胞癌',
    '普通痣',
    '皮膚纖維瘤',
    '脂漏性角化',
    '血管病變',
    '鱗狀細胞癌',
    '黑色素瘤'
]
num_classes = len(class_names)

# ==========================
# 前處理（與訓練一致）
# ==========================
transform = transforms.Compose([
    transforms.Resize((256, 256)),
    transforms.ToTensor(),
])

# ==========================
# 載入訓練過模型
# ==========================
def load_model(weight_path="best_model.pth"):
    model = timm.create_model(
        "convnext_tiny",
        pretrained=False,
        num_classes=num_classes
    )

    state = torch.load(weight_path, map_location="cpu")
    model.load_state_dict(state)
    model.eval()
    return model

# ==========================
# 單張圖片預測
# ==========================
def predict_image(model, img_path):
    img = Image.open(img_path).convert("RGB")
    img_tensor = transform(img).unsqueeze(0)

    with torch.no_grad():
        logits = model(img_tensor)
        probs = F.softmax(logits, dim=1)[0]

    # Top1
    top1_idx = probs.argmax().item()
    top1_label = class_names[top1_idx]
    top1_prob = float(probs[top1_idx])

    # Top3
    top3_prob, top3_idx = torch.topk(probs, 3)
    top3 = [(class_names[idx], float(top3_prob[i])) for i, idx in enumerate(top3_idx)]

    return top1_label, top1_prob, top3


# ==========================
# 測試入口
# ==========================
if __name__ == "__main__":
    img_path = input("請輸入圖片路徑： ")

    model = load_model("best_model.pth")

    top1_label, top1_prob, top3 = predict_image(model, img_path)

    print("\n=============================")
    print("       預測結果 (Top-1)")
    print("=============================")
    print(f"{top1_label}   ({top1_prob:.4f})")

    print("\n===== Top-3 =====")
    for label, prob in top3:
        print(f"{label} : {prob:.4f}")
