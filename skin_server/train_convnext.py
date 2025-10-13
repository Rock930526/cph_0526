# ============================================================
# train_convnext_advanced.py
# 進階版 DermNet23 訓練腳本
# - 自動偵測類別數量
# - WeightedRandomSampler 類別平衡
# - Data Augmentation 增強泛化能力
# - CosineAnnealingLR 學習率衰減
# - 自動儲存最佳模型
# - 訓練與驗證過程詳細輸出
# ============================================================

import os
import torch
import torch.nn as nn
import torch.optim as optim
from torchvision import datasets, transforms
from torch.utils.data import DataLoader, random_split, WeightedRandomSampler
from tqdm import tqdm
import timm
from sklearn.metrics import confusion_matrix
import numpy as np

# ================= 基本設定 =================
DATA_DIR = "C:/Users/HIMuser/Desktop/archive/train"  # ✅ DermNet23 訓練資料夾
MODEL_NAME = "convnext_large.fb_in22k_ft_in1k"
BATCH_SIZE = 8
EPOCHS = 30
LR = 5e-5
DEVICE = torch.device("cuda" if torch.cuda.is_available() else "cpu")
SAVE_PATH = "dermnet23_convnext.pth"

# ================= 資料前處理 =================
# 加強資料多樣性，防止過擬合
train_transform = transforms.Compose([
    transforms.Resize((224, 224)),
    transforms.RandomHorizontalFlip(),
    transforms.RandomRotation(15),
    transforms.ColorJitter(brightness=0.2, contrast=0.2, saturation=0.2),
    transforms.ToTensor(),
    transforms.Normalize(mean=[0.5]*3, std=[0.5]*3)
])

val_transform = transforms.Compose([
    transforms.Resize((224, 224)),
    transforms.ToTensor(),
    transforms.Normalize(mean=[0.5]*3, std=[0.5]*3)
])

# 載入資料集
full_dataset = datasets.ImageFolder(DATA_DIR, transform=train_transform)
num_classes = len(full_dataset.classes)
print(f"✅ 偵測到 {num_classes} 個類別：{full_dataset.classes}")

# 拆分 train/val
train_size = int(0.8 * len(full_dataset))
val_size = len(full_dataset) - train_size
train_dataset, val_dataset = random_split(full_dataset, [train_size, val_size])
val_dataset.dataset.transform = val_transform  # 驗證集不需增強

# ================= 類別平衡 =================
# 根據每類樣本數，建立權重
class_counts = [len(os.listdir(os.path.join(DATA_DIR, c))) for c in full_dataset.classes]
weights = 1.0 / torch.tensor(class_counts, dtype=torch.float)
sample_weights = [weights[label] for _, label in train_dataset]
sampler = WeightedRandomSampler(sample_weights, num_samples=len(sample_weights), replacement=True)

train_loader = DataLoader(train_dataset, batch_size=BATCH_SIZE, sampler=sampler)
val_loader = DataLoader(val_dataset, batch_size=BATCH_SIZE, shuffle=False)

# ================= 模型設定 =================
model = timm.create_model(MODEL_NAME, pretrained=True, num_classes=num_classes)
model = model.to(DEVICE)

criterion = nn.CrossEntropyLoss()
optimizer = optim.AdamW(model.parameters(), lr=LR)
scheduler = optim.lr_scheduler.CosineAnnealingLR(optimizer, T_max=EPOCHS)

best_acc = 0.0

# ================= 訓練迴圈 =================
for epoch in range(EPOCHS):
    model.train()
    total_loss, correct, total = 0, 0, 0
    pbar = tqdm(train_loader, desc=f"Epoch {epoch+1}/{EPOCHS}")

    for imgs, labels in pbar:
        imgs, labels = imgs.to(DEVICE), labels.to(DEVICE)
        optimizer.zero_grad()
        outputs = model(imgs)
        loss = criterion(outputs, labels)
        loss.backward()
        optimizer.step()

        total_loss += loss.item()
        preds = outputs.argmax(1)
        correct += (preds == labels).sum().item()
        total += labels.size(0)
        pbar.set_postfix({"loss": f"{loss.item():.3f}"})

    train_acc = correct / total

    # ================= 驗證 =================
    model.eval()
    correct, total = 0, 0
    all_preds, all_labels = [], []
    with torch.no_grad():
        for imgs, labels in val_loader:
            imgs, labels = imgs.to(DEVICE), labels.to(DEVICE)
            outputs = model(imgs)
            preds = outputs.argmax(1)
            correct += (preds == labels).sum().item()
            total += labels.size(0)
            all_preds.extend(preds.cpu().numpy())
            all_labels.extend(labels.cpu().numpy())

    val_acc = correct / total
    scheduler.step()

    print(f"Epoch {epoch+1}: TrainAcc={train_acc:.3f}, ValAcc={val_acc:.3f}")

    # 混淆矩陣（可視化模型混淆情形）
    cm = confusion_matrix(all_labels, all_preds)
    print("Confusion Matrix:\n", cm)

    # 儲存最佳模型
    if val_acc > best_acc:
        best_acc = val_acc
        torch.save(model.state_dict(), SAVE_PATH)
        print(f"✅ 模型已保存 (ValAcc={val_acc:.3f})")

print(f"🎯 訓練完成！最佳驗證準確率: {best_acc:.3f}")
