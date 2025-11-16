# inference_pipeline.py
import os
import shutil
import numpy as np
from patch_extractor import extract_patches_from_svs
from model_loader import ModelLoader

def run_wsi_inference(svs_path):
    temp_dir = "patches_temp"

    # fresh temp folder
    if os.path.exists(temp_dir):
        shutil.rmtree(temp_dir)
    os.makedirs(temp_dir)

    print("[INFO] Extracting patches...")
    patch_paths = extract_patches_from_svs(svs_path, temp_dir)
    print(f"[INFO] Total patches extracted: {len(patch_paths)}")

    model = ModelLoader()

    all_probs = []

    for p in patch_paths:
        _, probs = model.predict_patch(p)
        all_probs.append(probs)

    # aggregate predictions
    all_probs = np.array(all_probs)
    avg_probs = np.mean(all_probs, axis=0)
    final_label = int(np.argmax(avg_probs))

    shutil.rmtree(temp_dir)

    return model.classes[final_label], avg_probs.tolist()
