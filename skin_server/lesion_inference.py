# import torch
# import timm
# from PIL import Image
# from torchvision import transforms
# import os

# DEVICE = torch.device("cuda" if torch.cuda.is_available() else "cpu")

# # -----------------------------
# # 1. 載入模型（你原本寫好的）
# # -----------------------------
# def load_model(ckpt_path):
#     ckpt = torch.load(ckpt_path, map_location=DEVICE)

#     model_name = ckpt["model_name"]
#     classes = ckpt["classes"]
#     num_classes = len(classes)

#     model = timm.create_model(model_name, pretrained=False, num_classes=num_classes)
#     model.load_state_dict(ckpt["model_state"])
#     model.to(DEVICE)
#     model.eval()

#     return model, classes


# # -----------------------------
# # 2. 圖片前處理
# # -----------------------------
# transform = transforms.Compose([
#     transforms.Resize((224, 224)),
#     transforms.ToTensor(),
#     transforms.Normalize(
#         mean=[0.485, 0.456, 0.406],
#         std=[0.229, 0.224, 0.225]
#     )
# ])


# # -----------------------------
# # ⭐ 3. 新版：predict_lesion()
# # -----------------------------
# @torch.inference_mode()
# def predict_lesion(image_path: str, model, classes):
#     """回傳格式與你原本 lesion 版本一致：top1 + top3"""

#     img = Image.open(image_path).convert("RGB")
#     x = transform(img).unsqueeze(0).to(DEVICE)

#     outputs = model(x)
#     probs = torch.softmax(outputs, dim=1)[0]

#     # Top1
#     top1_prob, top1_idx = torch.max(probs, dim=0)
#     top1_label = classes[top1_idx.item()]

#     # Top3
#     top3_prob, top3_idx = torch.topk(probs, 3)
#     top3 = [{
#         "label": classes[idx.item()],
#         "confidence": round(prob.item(), 3)
#     } for prob, idx in zip(top3_prob, top3_idx)]

#     return {
#         "top1": {
#             "label": top1_label,
#             "confidence": round(top1_prob.item(), 3),
#         },
#         "top3": top3
#     }
