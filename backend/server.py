# server.py
import sys
import os

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
from fastapi import FastAPI, UploadFile
from inference_pipeline import run_wsi_inference
import shutil
import uvicorn

app = FastAPI()

@app.post("/predict")
async def predict(file: UploadFile):
    save_path = "uploaded.svs"
    
    with open(save_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)

    label, probabilities = run_wsi_inference(save_path)

    return {
        "prediction": label,
        "probabilities": probabilities
    }

if __name__ == "__main__":
    uvicorn.run("server:app", host="0.0.0.0", port=8000)
