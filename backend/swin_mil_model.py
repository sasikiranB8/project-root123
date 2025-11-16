# swin_mil_model.py
import torch
import torch.nn as nn
from torchvision.models import swin_t

class SwinMILModel(nn.Module):
    def __init__(self, num_classes=3):
        super(SwinMILModel, self).__init__()

        # Load pretrained Swin Transformer
        self.backbone = swin_t(weights="IMAGENET1K_V1")

        # Replace classification head
        in_features = self.backbone.head.in_features
        self.backbone.head = nn.Identity()

        # New classifier for your dataset
        self.classifier = nn.Sequential(
            nn.Linear(in_features, 512),
            nn.ReLU(),
            nn.Dropout(0.3),
            nn.Linear(512, num_classes)
        )

    def forward(self, x):
        features = self.backbone(x)
        out = self.classifier(features)
        return out
