# 🎬 ULTRA Sosyal Medya Video Optimize Script v2.0

Sosyal medya platformları (Instagram, TikTok, YouTube Shorts) için video optimizasyon scripti. Metadata ekleme, FastStart optimizasyonu, AI destekli thumbnail seçimi ve platform bazlı bitrate ayarları içerir.

## ✨ Özellikler

- 📱 **Cihaz Profili Ekleme**: Meta AI, iPhone, Samsung gibi cihaz profilleri
- 🚀 **FastStart Optimizasyonu**: MOOV atom optimizasyonu ile hızlı yükleme
- 🎯 **Platform Optimizasyonu**: Instagram (12Mbps), TikTok (8Mbps), YouTube Shorts (16Mbps)
- 🤖 **AI Thumbnail**: CLIP modeli ile otomatik en iyi frame seçimi
- 📊 **Kalite Skoru**: Her video için 0-100 arası kalite değerlendirmesi
- ✅ **Metadata Doğrulama**: Her video için ayrı metadata kontrolü
- 📈 **Detaylı Rapor**: İşlem sonrası toplu rapor oluşturma
- 📁 **Organize Çıktı**: Meta ve Social klasörlerine otomatik ayrıştırma

## 📋 Gereksinimler

### Sistem Gereksinimleri

- **Linux** (Ubuntu/Debian önerilir)
- **Python 3.8+**
- **Bash shell**

### Gerekli Araçlar

```bash
# FFmpeg (video işleme)
sudo apt update
sudo apt install ffmpeg

# ExifTool (opsiyonel - metadata için)
sudo apt install libimage-exiftool-perl

# Python3 ve venv desteği
sudo apt install python3 python3-venv python3-full

# mp4dump (opsiyonel - FastStart kontrolü için)
# GPAC paketinden gelir
sudo apt install gpac
```

## 🚀 Kurulum

### 1. Repository'yi İndirin

```bash
git clone <repository-url>
cd Script
```

VEYA dosyaları manuel olarak indirip bir klasöre koyun.

### 2. Script'i Çalıştırılabilir Yapın

```bash
chmod +x kirwem.sh
chmod +x ai_thumbnail.py
```

### 3. AI Thumbnail için Virtual Environment Kurulumu

**⚠️ ÖNEMLİ:** AI thumbnail özelliği için Python kütüphaneleri gereklidir.

```bash
# Virtual environment oluştur
python3 -m venv venv_ai_thumb

# Virtual environment'ı aktif et
source venv_ai_thumb/bin/activate

# Gerekli kütüphaneleri yükle
pip install torch torchvision pillow clip-anytorch tqdm
```

**Not:** Kurulum birkaç dakika sürebilir (torch büyük bir pakettir).

### 4. Kurulumu Doğrulayın

```bash
# FFmpeg kontrolü
ffmpeg -version

# Python kontrolü
python3 --version

# Virtual environment kontrolü (aktifken)
python3 -c "import clip_anytorch; print('✅ CLIP yüklü')"
```

## 📖 Kullanım

### Temel Kullanım

1. **Videolarınızı script'in bulunduğu klasöre koyun**

2. **Script'i çalıştırın:**
   ```bash
   ./kirwem.sh
   ```

3. **Adımları takip edin:**
   - Cihaz profili seçin (1-4)
   - Platform seçin (Instagram/TikTok/YouTube Shorts)
   - Video seçin (Tümü veya tekil)
   - Opsiyonel ayarları seçin:
     - ExifTool metadata
     - Sosyal medya optimizasyonu
     - Thumbnail (AI veya ilk frame)

### Klasör Yapısı

Script çalıştıktan sonra:

```
Script/
├── kirwem.sh
├── ai_thumbnail.py
├── video1.mp4          # Orijinal videolar
├── video2.mp4
├── meta/               # Metadata eklenmiş videolar
│   ├── video1_meta.mp4
│   └── video2_meta.mp4
├── social/             # Sosyal medya için optimize edilmiş videolar
│   ├── video1_social.mp4
│   └── video2_social.mp4
└── logs/               # Log ve rapor dosyaları
    ├── optimize_YYYYMMDD_HHMMSS.log
    └── report_YYYYMMDD_HHMMSS.txt
```

### AI Thumbnail Kullanımı

AI thumbnail özelliği için virtual environment kurulmuş olmalıdır. Script otomatik olarak `venv_ai_thumb` klasörünü algılar.

**Manuel kullanım:**
```bash
source venv_ai_thumb/bin/activate
python3 ai_thumbnail.py video.mp4 output_thumb.jpg
```

## 🎯 Platform Bitrate Ayarları

- **Instagram**: 12 Mbps
- **TikTok**: 8 Mbps  
- **YouTube Shorts**: 16 Mbps

## 📊 Çıktı Dosyaları

### Meta Klasörü
- Metadata eklenmiş videolar
- FastStart optimizasyonu uygulanmış
- Orijinal kalitede

### Social Klasörü
- Platform bazlı bitrate optimizasyonu
- Sosyal medya için optimize edilmiş
- Daha küçük dosya boyutu

### Logs Klasörü
- İşlem logları
- Detaylı raporlar
- Metadata test sonuçları

## 🔧 Sorun Giderme

### "externally-managed-environment" Hatası

Bu hata, sistem Python ortamının korunması nedeniyle oluşur. **Mutlaka virtual environment kullanın:**

```bash
python3 -m venv venv_ai_thumb
source venv_ai_ai_thumb/bin/activate
pip install ...
```

### "CLIP kütüphanesi bulunamadı" Hatası

Virtual environment'ı aktif edin ve kütüphaneleri yükleyin:

```bash
source venv_ai_thumb/bin/activate
pip install clip-anytorch torch torchvision pillow tqdm
```

### "ffmpeg: command not found"

FFmpeg yüklü değil:

```bash
sudo apt update
sudo apt install ffmpeg
```

### AI Thumbnail Çalışmıyor

1. Virtual environment aktif mi kontrol edin
2. Kütüphaneler yüklü mü kontrol edin:
   ```bash
   source venv_ai_thumb/bin/activate
   python3 -c "import clip_anytorch; print('OK')"
   ```
3. Script otomatik olarak ilk frame'e geçer (hata durumunda)

## 📝 Örnek Kullanım Senaryosu

```bash
# 1. Videoları klasöre koy
cp /path/to/videos/*.mp4 .

# 2. Script'i çalıştır
./kirwem.sh

# 3. Seçimler:
#    - Cihaz: 2 (iPhone 16 Pro Max)
#    - Platform: 1 (Instagram)
#    - Video: e (Tümü)
#    - ExifTool: e (Evet)
#    - Sosyal optimizasyon: e (Evet)
#    - Thumbnail: e (Evet)
#    - Thumbnail yöntemi: 1 (AI)

# 4. Sonuçlar:
#    - meta/ klasöründe metadata eklenmiş videolar
#    - social/ klasöründe optimize edilmiş videolar
#    - logs/ klasöründe raporlar
```

## 🎨 Cihaz Profilleri

1. **Meta AI - Ray-Ban Meta Smart Glasses**
2. **iPhone 16 Pro Max**
3. **Samsung Galaxy S25 Ultra**
4. **Manuel Gir** (Özel cihaz bilgisi)

## 📄 Lisans

Bu script açık kaynaklıdır. İstediğiniz gibi kullanabilir ve değiştirebilirsiniz.

## 🤝 Katkıda Bulunma

Hata bulursanız veya özellik önerisi varsa issue açabilirsiniz.

## ⚠️ Notlar

- Script, video dosyalarını orijinal halinde bırakır (sadece kopyaları işler)
- Virtual environment kurulumu sadece AI thumbnail için gereklidir
- AI thumbnail yüklü değilse script otomatik olarak ilk frame kullanır
- mp4dump opsiyoneldir (FastStart kontrolü için)

## 📞 Destek

Sorun yaşarsanız:
1. Log dosyalarını kontrol edin: `logs/` klasörü
2. Rapor dosyalarını inceleyin: `logs/report_*.txt`
3. Virtual environment'ın aktif olduğundan emin olun

---

**Versiyon:** 2.0  
**Son Güncelleme:** 2024

