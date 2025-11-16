# model_loader.py
import torch
import os
from torchvision import transforms
from PIL import Image
from swin_mil_model import SwinMILModel

MODEL_PATH = "swin_mil_final.pth"

# Patch preprocessing
transform = transforms.Compose([
    transforms.Resize((512, 512)),
    transforms.ToTensor(),
    transforms.Normalize(mean=[0.485, 0.456, 0.406],
                         std=[0.229, 0.224, 0.225])
])

class ModelLoader:
    def __init__(self):
        print("[INFO] Loading Swin + MIL architecture...")
        self.model = SwinMILModel(num_classes=3)

        print("[INFO] Loading weights from:", MODEL_PATH)
        checkpoint = torch.load(MODEL_PATH, map_location="cpu")
        self.model.load_state_dict(checkpoint)
        self.model.eval()
        
        self.classes = ["normal", "hcc", "chc"]
        print("[INFO] Model loaded successfully.")

    def predict_patch(self, img_path: str):
        img = Image.open(img_path).convert("RGB")
        img = transform(img).unsqueeze(0)

        with torch.no_grad():
            logits = self.model(img)
            probs = torch.softmax(logits, dim=1).squeeze().tolist()
            label = int(torch.argmax(logits))

        return label, probs
