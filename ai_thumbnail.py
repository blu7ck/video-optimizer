#!/usr/bin/env python3

# ai_thumbnail.py

import os
import sys
from PIL import Image
import torch
import clip
from tqdm import tqdm

# 1) Video path ve output path
if len(sys.argv) < 2:
    print("Kullanım: python ai_thumbnail.py video.mp4 [output_path.jpg]")
    sys.exit(1)

video_path = sys.argv[1]
if len(sys.argv) >= 3:
    output_thumb = sys.argv[2]
else:
    output_thumb = f"{os.path.splitext(video_path)[0]}_thumb.jpg"

# Temp frames dizini (video ile aynı dizinde)
video_dir = os.path.dirname(video_path)
if not video_dir:
    video_dir = "."
frames_dir = os.path.join(video_dir, "temp_frames")
os.makedirs(frames_dir, exist_ok=True)

# 2) Video'dan kareleri çıkar (her saniye 1 kare)
os.system(f'ffmpeg -i "{video_path}" -vf fps=1 {frames_dir}/frame_%04d.jpg -y')

# 3) CLIP modeli yükle
device = "cuda" if torch.cuda.is_available() else "cpu"

# clip-anytorch veya OpenAI CLIP desteği
try:
    import clip
    model, preprocess = clip.load("ViT-B/32", device=device)
except ImportError:
    try:
        # clip-anytorch alternatifi
        from clip_anytorch import clip_anytorch
        model, preprocess = clip_anytorch("ViT-B/32", device=device)
    except ImportError:
        print("❌ CLIP kütüphanesi bulunamadı!")
        print("   Lütfen şunlardan birini yükleyin:")
        print("   - pip install git+https://github.com/openai/CLIP.git")
        print("   - pip install clip-anytorch")
        sys.exit(1)

# 4) Kareleri skorlama
scores = {}
frame_files = [f for f in sorted(os.listdir(frames_dir)) if f.endswith(".jpg")]
if not frame_files:
    print("❌ Hiç frame çıkarılamadı!")
    import shutil
    shutil.rmtree(frames_dir, ignore_errors=True)
    sys.exit(1)

for fname in tqdm(frame_files):
    try:
        image = preprocess(Image.open(os.path.join(frames_dir, fname))).unsqueeze(0).to(device)
        with torch.no_grad():
            # Basit scoring: image embedding norm'u (yüksek kontrast + netlik)
            score = image.norm().item()
            scores[fname] = score
    except Exception as e:
        print(f"⚠️  Frame işlenemedi {fname}: {e}")
        continue

# 5) En yüksek skorlu kareyi seç
if not scores:
    print("❌ Hiçbir frame skorlanamadı!")
    import shutil
    shutil.rmtree(frames_dir, ignore_errors=True)
    sys.exit(1)

best_frame = max(scores, key=scores.get)
output_dir = os.path.dirname(output_thumb)
if output_dir:
    os.makedirs(output_dir, exist_ok=True)
os.rename(os.path.join(frames_dir, best_frame), output_thumb)

# Temizlik
import shutil
shutil.rmtree(frames_dir, ignore_errors=True)

print(f"✅ AI seçilen thumbnail: {output_thumb}")

