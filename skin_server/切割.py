import os
import shutil
import random

# =======================================
# 1. 來源資料夾（你的原始分類資料集）
# =======================================
SOURCE_DIR = r"C:\Users\HIMuser\Desktop\ham10000_isic2019"  # << 換成你的

# =======================================
# 2. 目標資料夾（訓練用）
# =======================================
TARGET_DIR = r"C:\Users\HIMuser\Desktop\ham10000_isic2019_full"  # << 輸出的地方

TRAIN_RATIO = 0.8  # 80% train / 20% val

# =======================================
# 建立資料夾
# =======================================
train_dir = os.path.join(TARGET_DIR, "train")
val_dir   = os.path.join(TARGET_DIR, "val")

os.makedirs(train_dir, exist_ok=True)
os.makedirs(val_dir, exist_ok=True)

# =======================================
# 開始分割
# =======================================
for cls in os.listdir(SOURCE_DIR):
    cls_path = os.path.join(SOURCE_DIR, cls)
    if not os.path.isdir(cls_path):
        continue

    print(f"分類：{cls}")

    # 建立 train / val 子資料夾
    os.makedirs(os.path.join(train_dir, cls), exist_ok=True)
    os.makedirs(os.path.join(val_dir, cls), exist_ok=True)

    images = [
        f for f in os.listdir(cls_path)
        if f.lower().endswith((".jpg", ".jpeg", ".png"))
    ]

    random.shuffle(images)

    split_idx = int(len(images) * TRAIN_RATIO)
    train_imgs = images[:split_idx]
    val_imgs   = images[split_idx:]

    # copy train
    for img in train_imgs:
        src = os.path.join(cls_path, img)
        dst = os.path.join(train_dir, cls, img)
        shutil.copy2(src, dst)

    # copy val
    for img in val_imgs:
        src = os.path.join(cls_path, img)
        dst = os.path.join(val_dir, cls, img)
        shutil.copy2(src, dst)

    print(f"  → Train: {len(train_imgs)} | Val: {len(val_imgs)}")

print("\n✔ Train/Val 分割完成！")
print(f"輸出路徑：{TARGET_DIR}")
