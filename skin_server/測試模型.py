import torch
import timm
from PIL import Image
from torchvision import transforms
import os
import random

DEVICE = torch.device("cuda" if torch.cuda.is_available() else "cpu")

# -----------------------------
# 1. 載入模型
# -----------------------------
def load_model(ckpt_path):
    ckpt = torch.load(ckpt_path, map_location=DEVICE)

    model_name = ckpt["model_name"]
    classes = ckpt["classes"]
    num_classes = len(classes)

    model = timm.create_model(model_name, pretrained=False, num_classes=num_classes)
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


# -----------------------------
# 3. 預測單張圖片
# -----------------------------
def predict(model, img_path, classes):
    img = Image.open(img_path).convert("RGB")
    x = transform(img).unsqueeze(0).to(DEVICE)

    with torch.no_grad():
        outputs = model(x)
        probs = torch.softmax(outputs, dim=1)

    top1_prob, top1_idx = torch.max(probs, dim=1)
    top1_label = classes[top1_idx.item()]

    top3_prob, top3_idx = torch.topk(probs, 3)
    top3 = [(classes[idx], float(prob)) for prob, idx in zip(top3_prob[0], top3_idx[0])]

    return top1_label, float(top1_prob), top3


# -----------------------------
# ⭐ 4. 隨機抽取 val/ 中 50 張測試
# -----------------------------
def test_random_images(model, classes, folder, n=100):
    print(f"\n開始從 {folder} 中抽取圖片...\n")

    all_imgs = []
    for root, dirs, files in os.walk(folder):
        for f in files:
            if f.lower().endswith((".jpg", ".jpeg", ".png")):
                all_imgs.append(os.path.join(root, f))

    if len(all_imgs) == 0:
        print("❌ val/ 底下沒有找到圖片")
        return

    sample_imgs = random.sample(all_imgs, min(n, len(all_imgs)))

    correct = 0

    for img_path in sample_imgs:
        true_label = os.path.basename(os.path.dirname(img_path))
        pred, prob, _ = predict(model, img_path, classes)

        hit = (pred == true_label)
        mark = "✓" if hit else "✗"
        if hit:
            correct += 1

        print(f"{mark} GT={true_label:10s} | Pred={pred:10s} ({prob:.3f}) | {os.path.basename(img_path)}")

    acc = correct / len(sample_imgs)
    print(f"\n=== 隨機測試完成，準確率：{acc:.3f} ===\n")


# -----------------------------
# 5. 主流程
# -----------------------------
if __name__ == "__main__":
    model, classes = load_model("best_model.pth")

    print("\n選擇模式：")
    print("1. 單張圖片預測")
    print("2. 從 val/ 隨機抽 100 張測試模型準確率")
    mode = input("請輸入 1 或 2： ").strip()

    # 單張圖模式
    if mode == "1":
        img_path = input("請輸入圖片路徑： ").strip()
        top1, prob, top3 = predict(model, img_path, classes)

        print("\n=== 預測結果 ===")
        print(f"Top1: {top1} ({prob:.4f})")
        print("Top3:")
        for label, p in top3:
            print(f" - {label}: {p:.4f}")

    # 隨機 50 張模式
    elif mode == "2":
        val_folder = r"C:\Users\HIMuser\Desktop\ham10000_isic2019_full\val1"
        test_random_images(model, classes, val_folder)

    else:
        print("❌ 無效模式，請重新執行程式。")
