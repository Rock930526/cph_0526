# ============================================================
# download.py  — 一鍵下載＆轉檔＆寫入標籤（GPU 版）
# ============================================================
import os
import torch
import torch.nn as nn
from transformers import (
    AutoModelForImageClassification,
    ConvNextForImageClassification,
)

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
MODEL_DIR = os.path.join(BASE_DIR, "model")
os.makedirs(MODEL_DIR, exist_ok=True)

# ------------------------------------------------------------
# 設定裝置：優先使用 GPU，否則自動 fallback
# ------------------------------------------------------------
device = torch.device("cuda:0" if torch.cuda.is_available() else "cpu")
print(f"⚙️ 使用裝置：{device}")

# ------------------------------------------------------------
# Trace 並存檔（確保 dummy、model 都在同一裝置）
# ------------------------------------------------------------
def trace_and_save(model: nn.Module, filename: str):
    model.eval().to(device)
    dummy = torch.randn(1, 3, 224, 224, device=device)
    path = os.path.join(MODEL_DIR, filename)
    with torch.no_grad():
        traced = torch.jit.trace(model, dummy, strict=False)
        traced.save(path)
    size = os.path.getsize(path) / (1024 * 1024)
    print(f"✅ {filename} 已輸出 ({size:.1f} MB) -> {path}")
    return path


# # ---------- 1) 疾病分類（ConvNeXt） ----------
# print("\n🚀 [1/2] 下載疾病分類模型 (ConvNeXt)...")
# disease_model_id = "AlexHan12138/Skin-Disease-Classification-23classes"
# disease_model = ConvNextForImageClassification.from_pretrained(disease_model_id)
# trace_and_save(disease_model, "skinconvnext_scripted.pt")

# # 產生 labels.txt
# disease_labels = []
# cfg = getattr(disease_model, "config", None)
# if cfg and getattr(cfg, "id2label", None):
#     disease_labels = [cfg.id2label[i] for i in sorted(cfg.id2label.keys())]
# else:
#     print("⚠️ 無法從模型 config 取得 id2label。")
# labels_txt = os.path.join(MODEL_DIR, "labels.txt")
# with open(labels_txt, "w", encoding="utf-8") as f:
#     f.write("\n".join(disease_labels))
# print(f"📝 已建立疾病分類標籤檔：{labels_txt}（{len(disease_labels)} 類）")


# ---------- 2) 病變分類（SwinV2 Large） ----------
print("\n🚀 [2/2] 下載病變分類模型 (SwinV2 Large)...")
lesion_model_id = (
    "ALM-AHME/swinv2-large-patch4-window12to16-192to256-22kto1k-"
    "ft-finetuned-Lesion-Classification-HAM10000-AH"
)
hf_lesion = AutoModelForImageClassification.from_pretrained(lesion_model_id).to(device)

# 包裝成回傳 logits 的 wrapper
class HFImageClassifierWrapper(nn.Module):
    def __init__(self, base):
        super().__init__()
        self.base = base
    def forward(self, x: torch.Tensor) -> torch.Tensor:
        return self.base(pixel_values=x).logits

wrapped = HFImageClassifierWrapper(hf_lesion)
trace_and_save(wrapped, "lesion_vit_scripted.pt")

# lesion_labels.txt
lesion_labels = []
cfg2 = getattr(hf_lesion, "config", None)
if cfg2 and getattr(cfg2, "id2label", None):
    lesion_labels = [cfg2.id2label[i] for i in sorted(cfg2.id2label.keys())]
if not lesion_labels:
    lesion_labels = ["AKIEC", "BCC", "BKL", "DF", "MEL", "NV", "VASC"]
lesion_labels_txt = os.path.join(MODEL_DIR, "lesion_labels.txt")
with open(lesion_labels_txt, "w", encoding="utf-8") as f:
    f.write("\n".join(lesion_labels))
print(f"📝 已建立病變分類標籤檔：{lesion_labels_txt}（{len(lesion_labels)} 類）")

print("\n🎉 所有模型已成功下載並轉換完畢！")
print(f"📂 模型儲存位置：{MODEL_DIR}")
