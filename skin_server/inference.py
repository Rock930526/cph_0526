# inference.py
import torch
import timm
from PIL import Image
from torchvision import transforms

# 定義分類標籤（HAM10000 七類皮膚病變）
CLASSES = ["akiec", "bcc", "bkl", "df", "mel", "nv", "vasc"]

# 初始化模型（EfficientNet-B3）
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
model = timm.create_model("efficientnet_b3", pretrained=True, num_classes=len(CLASSES))
model.eval()
model.to(device)

# 預處理流程
transform = transforms.Compose([
    transforms.Resize((300, 300)),
    transforms.ToTensor(),
    transforms.Normalize(mean=[0.485, 0.456, 0.406],
                         std=[0.229, 0.224, 0.225])
])

@torch.no_grad()
def predict_skin_disease(image_path: str) -> dict:
    image = Image.open(image_path).convert("RGB")
    x = transform(image).unsqueeze(0).to(device)
    outputs = model(x)
    prob = torch.nn.functional.softmax(outputs, dim=1)
    conf, pred = torch.max(prob, 1)
    return {
        "class_id": pred.item(),
        "class_name": CLASSES[pred.item()],
        "confidence": round(conf.item(), 3)
    }
