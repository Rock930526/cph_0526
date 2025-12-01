import os
import time

import torch
import torch.nn as nn
import torch.optim as optim
from torch.utils.data import DataLoader
from torchvision import datasets, transforms
import timm
from tqdm import tqdm


# ==============================
# 1. 基本設定（依需求修改）
# ==============================
DATA_DIR = r"C:\Users\HIMuser\Desktop\ham10000_isic2019_full"  # << 換成你的資料夾
TRAIN_DIR = os.path.join(DATA_DIR, "train")
VAL_DIR   = os.path.join(DATA_DIR, "val")

MODEL_NAME = "convnext_tiny"  # timm 模型名稱
BATCH_SIZE = 32
NUM_EPOCHS = 30
LR = 1e-4
NUM_WORKERS = 4

DEVICE = torch.device("cuda" if torch.cuda.is_available() else "cpu")


# ==============================
# 2. 資料增強 & Dataset
# ==============================
def get_dataloaders():
    # 訓練資料增強
    transform_train = transforms.Compose([
        transforms.Resize((256, 256)),
        transforms.RandomResizedCrop(224, scale=(0.8, 1.0)),
        transforms.RandomHorizontalFlip(),
        transforms.RandomVerticalFlip(),
        transforms.RandomRotation(15),
        transforms.ToTensor(),
        transforms.Normalize(
            mean=[0.485, 0.456, 0.406],   # ImageNet 標準
            std=[0.229, 0.224, 0.225]
        ),
    ])

    # 驗證資料：只做 Resize + Normalize
    transform_val = transforms.Compose([
        transforms.Resize((224, 224)),
        transforms.ToTensor(),
        transforms.Normalize(
            mean=[0.485, 0.456, 0.406],
            std=[0.229, 0.224, 0.225]
        ),
    ])

    train_dataset = datasets.ImageFolder(TRAIN_DIR, transform=transform_train)
    val_dataset   = datasets.ImageFolder(VAL_DIR,   transform=transform_val)

    train_loader = DataLoader(
        train_dataset,
        batch_size=BATCH_SIZE,
        shuffle=True,
        num_workers=NUM_WORKERS,
        pin_memory=True
    )

    val_loader = DataLoader(
        val_dataset,
        batch_size=BATCH_SIZE,
        shuffle=False,
        num_workers=NUM_WORKERS,
        pin_memory=True
    )

    return train_loader, val_loader, train_dataset.classes


# ==============================
# 3. 建立模型（timm + 轉移學習）
# ==============================
def build_model(num_classes: int):
    # 讀取預訓練 convnext_tiny
    model = timm.create_model(
        MODEL_NAME,
        pretrained=True,
        num_classes=num_classes
    )
    model.to(DEVICE)
    return model


# ==============================
# 4. 訓練 & 驗證函式
# ==============================
def train_one_epoch(model, loader, criterion, optimizer, epoch_idx):
    model.train()
    running_loss = 0.0

    pbar = tqdm(loader, desc=f"Epoch {epoch_idx} [Train]", ncols=100)

    for images, labels in pbar:
        images = images.to(DEVICE, non_blocking=True)
        labels = labels.to(DEVICE, non_blocking=True)

        optimizer.zero_grad()

        outputs = model(images)
        loss = criterion(outputs, labels)
        loss.backward()
        optimizer.step()

        running_loss += loss.item() * images.size(0)
        avg_loss = running_loss / ((pbar.n + 1) * loader.batch_size)
        pbar.set_postfix(loss=f"{avg_loss:.4f}")

    epoch_loss = running_loss / len(loader.dataset)
    return epoch_loss


def eval_one_epoch(model, loader, criterion, epoch_idx):
    model.eval()
    running_loss = 0.0
    correct = 0
    total = 0

    pbar = tqdm(loader, desc=f"Epoch {epoch_idx} [Val]  ", ncols=100)

    with torch.no_grad():
        for images, labels in pbar:
            images = images.to(DEVICE, non_blocking=True)
            labels = labels.to(DEVICE, non_blocking=True)

            outputs = model(images)
            loss = criterion(outputs, labels)

            running_loss += loss.item() * images.size(0)

            _, preds = torch.max(outputs, 1)
            total += labels.size(0)
            correct += (preds == labels).sum().item()

            avg_loss = running_loss / ((pbar.n + 1) * loader.batch_size)
            acc = correct / total if total > 0 else 0.0
            pbar.set_postfix(loss=f"{avg_loss:.4f}", acc=f"{acc:.4f}")

    epoch_loss = running_loss / len(loader.dataset)
    epoch_acc = correct / total if total > 0 else 0.0
    return epoch_loss, epoch_acc


# ==============================
# 5. 主訓練流程
# ==============================
def train():
    print(f"Using device: {DEVICE}")

    train_loader, val_loader, classes = get_dataloaders()
    num_classes = len(classes)
    print("Classes:", classes)
    print("Num classes:", num_classes)

    model = build_model(num_classes)

    criterion = nn.CrossEntropyLoss()
    optimizer = optim.AdamW(model.parameters(), lr=LR, weight_decay=1e-4)

    best_acc = 0.0
    os.makedirs("checkpoints", exist_ok=True)
    best_path = os.path.join("checkpoints", "best_model.pth")

    for epoch in range(1, NUM_EPOCHS + 1):
        print(f"\n========== Epoch {epoch}/{NUM_EPOCHS} ==========")
        start_time = time.time()

        train_loss = train_one_epoch(model, train_loader, criterion, optimizer, epoch)
        val_loss, val_acc = eval_one_epoch(model, val_loader, criterion, epoch)

        elapsed = time.time() - start_time
        print(f"Epoch {epoch} Done | "
              f"Train Loss: {train_loss:.4f} | "
              f"Val Loss: {val_loss:.4f} | "
              f"Val Acc: {val_acc:.4f} | "
              f"Time: {elapsed:.1f}s")

        # 儲存最佳模型
        if val_acc > best_acc:
            best_acc = val_acc
            torch.save(
                {
                    "model_state": model.state_dict(),
                    "classes": classes,
                    "epoch": epoch,
                    "val_acc": val_acc,
                    "model_name": MODEL_NAME
                },
                best_path
            )
            print(f"★ New best model saved! Acc={best_acc:.4f}")

    print("\nTraining finished.")
    print(f"Best Val Acc: {best_acc:.4f}")
    print(f"Best model path: {best_path}")


# ==============================
# 6. Windows 入口點
# ==============================
if __name__ == "__main__":
    train()
