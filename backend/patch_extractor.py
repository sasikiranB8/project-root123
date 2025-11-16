# patch_extractor.py
import openslide
from PIL import Image
import os

PATCH_SIZE = 512
STEP = 512  # no overlap

def extract_patches_from_svs(svs_path, output_dir):
    slide = openslide.OpenSlide(svs_path)
    W, H = slide.dimensions

    os.makedirs(output_dir, exist_ok=True)
    patch_paths = []

    for y in range(0, H, STEP):
        for x in range(0, W, STEP):
            patch = slide.read_region((x, y), 0, (PATCH_SIZE, PATCH_SIZE)).convert("RGB")
            name = f"{x}_{y}.png"
            path = os.path.join(output_dir, name)
            patch.save(path)
            patch_paths.append(path)

    slide.close()
    return patch_paths
