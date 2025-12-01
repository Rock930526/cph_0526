import os
import shutil
import pandas as pd

# === 路徑設定 ===
BASE = r"C:\Users\HIMuser\Desktop\ISIC_2019_Training_Input"

IMG_DIR = os.path.join(BASE, "ISIC_2019_Training_Input")
CSV_PATH = os.path.join(BASE, "ISIC_2019_Training_GroundTruth.csv")
OUT_DIR = os.path.join(BASE, "ISIC2019")

os.makedirs(OUT_DIR, exist_ok=True)

# === 8 類（UNK 排除）===
LABELS = ["MEL", "NV", "BCC", "AK", "BKL", "DF", "VASC", "SCC"]

# 建資料夾
for lb in LABELS:
    os.makedirs(os.path.join(OUT_DIR, lb), exist_ok=True)

# === 讀 CSV ===
df = pd.read_csv(CSV_PATH)
print("總筆數：", len(df))

# === 開始分類 ===
for idx, row in df.iterrows():
    img_id = row["image"]
    filename_jpg = os.path.join(IMG_DIR, img_id + ".jpg")
    filename_jpeg = os.path.join(IMG_DIR, img_id + ".jpeg")

    # 可能是 jpg 或 jpeg
    if os.path.exists(filename_jpg):
        src = filename_jpg
    elif os.path.exists(filename_jpeg):
        src = filename_jpeg
    else:
        continue  # 找不到就跳過

    # 判定這張圖片是哪一類
    assigned = False
    for lb in LABELS:
        if row[lb] == 1:
            dst = os.path.join(OUT_DIR, lb, img_id + ".jpg")
            shutil.copy2(src, dst)
            assigned = True
            break

    if not assigned:
        # 代表他是 UNK → 不分類，不要動他
        pass

print("分類完成！輸出位置：", OUT_DIR)
