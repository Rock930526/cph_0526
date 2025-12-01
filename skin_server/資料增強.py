import os
import random
import shutil
from PIL import Image, ImageEnhance
from tqdm import tqdm

# ======================================
# 設定區：依照你的路徑修改
# ======================================
SOURCE_DIR = r"C:\Users\HIMuser\Desktop\ham10000_isic2019"   # 原始 train 資料夾
TARGET_MIN = 6000                               # 每類至少要多少張
AUG_PER_IMAGE = 3                               # 每張圖片生成幾張增強版本
RANDOM_SEED = 42
random.seed(RANDOM_SEED)

# ======================================
# 資料增強函式
# ======================================
def augment_image(img):
    """ 回傳 1 張增強後的圖片 """
    # 隨機旋轉
    angle = random.randint(-25, 25)
    img = img.rotate(angle)

    # 隨機左右翻轉
    if random.random() < 0.5:
        img = img.transpose(Image.FLIP_LEFT_RIGHT)

    # 隨機上下翻轉
    if random.random() < 0.3:
        img = img.transpose(Image.FLIP_TOP_BOTTOM)

    # 顏色增強
    enhancer = ImageEnhance.Color(img)
    img = enhancer.enhance(random.uniform(0.7, 1.4))

    # 對比度
    enhancer = ImageEnhance.Contrast(img)
    img = enhancer.enhance(random.uniform(0.8, 1.5))

    # 亮度
    enhancer = ImageEnhance.Brightness(img)
    img = enhancer.enhance(random.uniform(0.8, 1.3))

    return img


# ======================================
# 主程式
# ======================================
def main():
    classes = sorted(os.listdir(SOURCE_DIR))
    print("偵測到類別：", classes)

    for cls in classes:
        cls_dir = os.path.join(SOURCE_DIR, cls)
        if not os.path.isdir(cls_dir):
            continue

        imgs = [
            f for f in os.listdir(cls_dir)
            if f.lower().endswith((".jpg", ".jpeg", ".png"))
        ]

        n = len(imgs)
        print(f"\n[{cls}] 現有：{n} 張")

        if n >= TARGET_MIN:
            print(" → 已達標，略過")
            continue

        need = TARGET_MIN - n
        print(f" → 需要補 {need} 張")

        # 開始增強
        counter = 0
        pbar = tqdm(total=need, desc=f"Augmenting {cls}")

        while counter < need:
            src_img_name = random.choice(imgs)
            src_img_path = os.path.join(cls_dir, src_img_name)

            try:
                img = Image.open(src_img_path).convert("RGB")
            except:
                continue

            # 每張原圖做多個增強
            for _ in range(AUG_PER_IMAGE):
                if counter >= need:
                    break

                aug_img = augment_image(img)
                new_name = f"{os.path.splitext(src_img_name)[0]}_aug_{counter}.jpg"
                new_path = os.path.join(cls_dir, new_name)

                aug_img.save(new_path, quality=95)
                counter += 1
                pbar.update(1)

        pbar.close()
        print(f" → 完成，共新增 {counter} 張。")

    print("\n🎉 所有少數類增強完成！")


if __name__ == "__main__":
    main()
