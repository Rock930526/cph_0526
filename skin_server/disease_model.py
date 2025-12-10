# # disease_model.py
# import torch
# import timm
# from PIL import Image
# from torchvision import transforms

# DEVICE = torch.device("cuda" if torch.cuda.is_available() else "cpu")

# def load_disease_model(ckpt_path):
#     ckpt = torch.load(ckpt_path, map_location=DEVICE)

#     model_name = ckpt["model_name"]
#     classes = ckpt["classes"]
#     num_classes = len(classes)

#     model = timm.create_model(model_name, pretrained=False, num_classes=num_classes)
#     model.load_state_dict(ckpt["model_state"])
#     model.to(DEVICE)
#     model.eval()

#     return model, classes


# transform = transforms.Compose([
#     transforms.Resize((224, 224)),
#     transforms.ToTensor(),
#     transforms.Normalize(
#         [0.485, 0.456, 0.406],
#         [0.229, 0.224, 0.225]
#     )
# ])


# @torch.inference_mode()
# def predict_disease(image_path, model, classes):
#     img = Image.open(image_path).convert("RGB")
#     x = transform(img).unsqueeze(0).to(DEVICE)

#     outputs = model(x)
#     probs = torch.softmax(outputs, dim=1)[0]

#     top1_prob, top1_idx = torch.max(probs, dim=0)

#     return {
#         "class_name": classes[top1_idx.item()],
#         "confidence": round(top1_prob.item(), 3)
#     }
