# ============================================================
# inference.py
# 功能：
#  - 使用 ConvNeXt 模型進行皮膚疾病分類
#  - 產出中文疾病摘要與結構化資訊
#  - 自動生成報告文本（供 LLM 使用）
# ============================================================
#prompt = f"以下是AI皮膚影像辨識結果：\n{result['report_text']}\n請以臨床醫師語氣生成完整報告，包含：診斷描述、可能病因、建議治療與追蹤建議。"

import torch
import timm
from torchvision import transforms
from PIL import Image

# === 模型設定 ===
MODEL_NAME = "convnext_large.fb_in22k_ft_in1k"
MODEL_PATH = "dermnet23_convnext.pth"  # ✅ 記得改成你訓練後的檔案名稱
CLASS_NAMES = [
    "acne", "actinic_keratosis", "eczema", "psoriasis",
    "urticaria", "vitiligo", "melanoma", "rosacea",
    "lupus", "impetigo", "dermatitis", "cellulitis",
    "boil", "scabies", "warts", "tinea", "onychomycosis",
    "alopecia", "basal_cell_carcinoma", "squamous_cell_carcinoma",
    "seborrheic_keratosis", "molluscum", "other"
]

DEVICE = torch.device("cuda" if torch.cuda.is_available() else "cpu")

# 載入模型與權重
model = timm.create_model(MODEL_NAME, pretrained=False, num_classes=len(CLASS_NAMES))
model.load_state_dict(torch.load(MODEL_PATH, map_location=DEVICE))
model.eval().to(DEVICE)

# === 影像轉換 ===
transform = transforms.Compose([
    transforms.Resize((224, 224)),
    transforms.ToTensor(),
    transforms.Normalize([0.5, 0.5, 0.5], [0.5, 0.5, 0.5])
])

# === 疾病摘要字典（可持續擴充） ===
DISEASE_SUMMARY = {
    "acne": "痤瘡（青春痘）是毛囊皮脂腺的慢性發炎性疾病，常見於青少年，與荷爾蒙分泌及皮脂阻塞相關。",
    "actinic_keratosis": "光化性角化症是一種由長期日曬引起的皮膚癌前病變，常見於臉部、手臂等暴露部位，需定期追蹤以防惡化為鱗狀細胞癌。",
    "eczema": "濕疹是一種常見的慢性皮膚炎，特徵為紅疹、脫屑與劇烈搔癢，常與過敏體質、環境刺激及皮膚屏障功能異常有關。",
    "psoriasis": "乾癬（牛皮癬）是一種慢性免疫相關皮膚病，會出現銀白色鱗屑與紅斑，常分布於肘部、膝蓋與頭皮，病情易反覆發作。",
    "urticaria": "蕁麻疹是一種暫時性皮膚過敏反應，表現為紅腫丘疹與強烈癢感，可能由食物、藥物、壓力或感染引起。",
    "vitiligo": "白斑病（白癜風）為皮膚色素細胞功能喪失所致的色素脫失性疾病，與自體免疫及遺傳因素相關。",
    "melanoma": "黑色素瘤是一種惡性皮膚腫瘤，常源自異常變化的痣，具有高度轉移性，早期發現與切除是治療關鍵。",
    "rosacea": "酒糟性皮膚炎為臉部慢性炎症性疾病，表現為潮紅、微血管擴張與丘疹，常見於中年人，與皮膚血管反應異常有關。",
    "lupus": "紅斑性狼瘡是一種自體免疫疾病，可侵犯皮膚與內臟，皮膚型狼瘡表現為蝴蝶狀紅斑與光敏感。",
    "impetigo": "膿痂疹為皮膚細菌感染，常由金黃色葡萄球菌或鏈球菌引起，多見於兒童，特徵為黃棕色結痂。",
    "dermatitis": "皮膚炎泛指皮膚的發炎反應，包括接觸性與異位性皮膚炎，症狀包含紅腫、癢與脫屑，常因外界刺激或過敏造成。",
    "cellulitis": "蜂窩性組織炎為皮膚與皮下組織的急性細菌感染，常伴隨疼痛與腫脹，需儘早使用抗生素治療。",
    "boil": "癤（疔瘡）為毛囊細菌感染形成的膿瘍，常由金黃色葡萄球菌引起，可能融合形成較大膿腫。",
    "scabies": "疥瘡是由疥蟎感染皮膚所致的傳染病，特徵為劇癢與隧道樣皮疹，常見於手指縫、手腕與腹部。",
    "warts": "疣為人類乳突病毒（HPV）感染所致的皮膚增生，常見於手足或生殖部位，部分可自癒或需冷凍治療。",
    "tinea": "癬（皮癬菌感染）為黴菌侵入角質層、毛髮或指甲造成的感染，依部位可分頭癬、足癬、體癬等。",
    "onychomycosis": "甲癬為指（趾）甲受黴菌感染所致，導致甲板變厚、變色與脆裂，治療需口服抗黴菌藥物。",
    "alopecia": "禿髮症（斑禿）為毛囊自體免疫破壞導致的掉髮現象，常突然出現圓形脫髮區，多數可自行恢復。",
    "basal_cell_carcinoma": "基底細胞癌是最常見的皮膚癌，生長緩慢且少轉移，但若不治療會局部侵犯破壞組織。",
    "squamous_cell_carcinoma": "鱗狀細胞癌為第二常見皮膚癌，可能由光化性角化症演變而來，具局部侵犯與轉移風險。",
    "seborrheic_keratosis": "脂漏性角化症為良性老化性皮膚腫瘤，外觀呈油膩棕黑色斑塊，常見於中老年人背部與臉部。",
    "molluscum": "傳染性軟疣為病毒感染引起的良性丘疹，常見於兒童，具有傳染性但通常可自行痊癒。",
    "other": "其他皮膚異常影像，可能包括過敏反應、輕微發炎或非典型皮膚變化，建議進一步臨床評估。"
}


# === 預測主函式 ===
@torch.inference_mode()
def predict_image(image_path):
    """輸入影像路徑 → 輸出分類結果、摘要、建議與報告文本"""
    image = Image.open(image_path).convert("RGB")
    img_tensor = transform(image).unsqueeze(0).to(DEVICE)
    outputs = model(img_tensor)
    probs = torch.softmax(outputs, dim=1)[0]
    topk = torch.topk(probs, 3)

    results = [
        {"label": CLASS_NAMES[idx], "confidence": float(probs[idx])}
        for idx in topk.indices
    ]
    main_label = results[0]["label"]

    # --- 疾病摘要與結構化建議 ---
    summary = DISEASE_SUMMARY.get(main_label, "尚無此疾病的詳細說明。")
    structured = {
        "disease": main_label,
        "confidence": results[0]["confidence"],
        "possible_causes": [],
        "recommended_actions": []
    }

    if main_label == "psoriasis":
        structured["possible_causes"] = ["免疫系統異常", "遺傳因素", "壓力誘發"]
        structured["recommended_actions"] = ["皮膚科門診就診", "避免乾燥與搔抓", "使用保濕產品"]
    elif main_label == "eczema":
        structured["possible_causes"] = ["過敏反應", "外界刺激", "皮膚屏障受損"]
        structured["recommended_actions"] = ["保持皮膚清潔", "使用低敏保濕乳液", "避免接觸刺激物"]

    # === 自動生成報告文本 ===
    report_text = (
        f"模型分析顯示此影像最可能為「{main_label}」，信心度為 {results[0]['confidence']:.2%}。\n"
        f"{summary}\n"
        f"可能成因包括：{'、'.join(structured['possible_causes']) or '暫無資料'}。\n"
        f"建議措施：{'、'.join(structured['recommended_actions']) or '暫無建議'}。\n"
        f"次高可能性為：{results[1]['label']}（{results[1]['confidence']:.2%}）與 "
        f"{results[2]['label']}（{results[2]['confidence']:.2%}）。"
    )

    return {
        "label": main_label,
        "confidence": results[0]["confidence"],
        "summary": summary,
        "structured": structured,
        "top3": results,
        "report_text": report_text  # ✅ 給 LLM 用的完整報告敘述
    }
