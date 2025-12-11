# 🎬 ULTRA Social Media Video Optimize Script v2.0

[🇬🇧 English](#english) | [🇹🇷 Türkçe](#türkçe)

---

<a name="english"></a>
## 🇬🇧 English

### Overview

Video optimization script for social media platforms (Instagram, TikTok, YouTube Shorts). Includes metadata injection, FastStart optimization, AI-powered thumbnail selection, and platform-specific bitrate settings.

### ✨ Features

- 📱 **Device Profile Injection**: Meta AI, iPhone, Samsung device profiles
- 🚀 **FastStart Optimization**: MOOV atom optimization for fast loading
- 🎯 **Platform Optimization**: Instagram (12Mbps), TikTok (8Mbps), YouTube Shorts (16Mbps)
- 🤖 **AI Thumbnail**: CLIP model for automatic best frame selection
- 📊 **Quality Score**: 0-100 quality assessment for each video
- ✅ **Metadata Verification**: Individual metadata validation for each video
- 📈 **Detailed Reports**: Post-processing batch reports
- 📁 **Organized Output**: Automatic separation into Meta and Optimized folders

### 📋 Requirements

#### System Requirements

- **Linux** (Ubuntu/Debian recommended)
- **Python 3.8+**
- **Bash shell**
- **Internet connection** (for downloading libraries)

#### Required Tools - Step by Step Installation

**💡 Tip:** If you're new to Linux, run these commands sequentially in the terminal.

##### 1. Update System Packages

```bash
sudo apt update
```
*This command updates the system package list. It may ask for your password.*

##### 2. Install FFmpeg (Required for Video Processing)

```bash
sudo apt install ffmpeg
```
*FFmpeg is required for processing video files. Type "Y" (Yes) and press Enter during installation.*

##### 3. Install Python and Required Packages (Required)

```bash
sudo apt install python3 python3-pip python3-venv python3-all
```
*This command installs Python3 and all necessary components:*
- `python3`: Python programming language
- `python3-pip`: Python package manager
- `python3-venv`: Virtual environment creation tool
- `python3-all`: All Python development tools (recommended)

##### 4. Install ExifTool (Optional - for Metadata)

```bash
sudo apt install libimage-exiftool-perl
```
*This tool is used to read/write video metadata. Optional but recommended.*

##### 5. Install mp4dump (Optional - for FastStart Check)

```bash
sudo apt install gpac
```
*This tool checks if FastStart optimization is correctly applied. Optional but recommended.*

#### Installation Verification

Verify all tools are installed:

```bash
# Check FFmpeg
ffmpeg -version

# Check Python
python3 --version

# Check Pip
pip3 --version
```

Each command should display a version number. If you get "command not found" errors, repeat the installation steps above.

### 🚀 Installation - From Scratch

#### 1. Download Repository

**If using Git:**
```bash
git clone https://github.com/blu7ck/video-optimizer.git
cd video-optimizer
```

**If not using Git:**
1. Click "Code" button on GitHub page
2. Select "Download ZIP"
3. Extract the downloaded ZIP file
4. Navigate to the folder in terminal:
   ```bash
   cd ~/Downloads/video-optimizer-main
   ```

#### 2. Make Scripts Executable

Run these commands in terminal:

```bash
chmod +x kirwem.sh
chmod +x ai_thumbnail.py
```

**What does this do?** These commands give execution permission to script files. Required to avoid "Permission denied" errors.

#### 3. Virtual Environment Setup for AI Thumbnail

**⚠️ IMPORTANT:** Python libraries are required for AI thumbnail feature. If you skip this step, the script will work but AI thumbnail feature won't be available (first frame will be used).

##### Step 3.1: Create Virtual Environment

```bash
python3 -m venv venv_ai_thumb
```

**What does this do?** This command creates an isolated Python environment named `venv_ai_thumb`. This allows you to install libraries without affecting your system Python.

**If you get an error:** Make sure `python3-all` package is installed:
```bash
sudo apt install python3-all
```

##### Step 3.2: Activate Virtual Environment

```bash
source venv_ai_thumb/bin/activate
```

**What does this do?** Activates the virtual environment. When successful, you'll see `(venv_ai_thumb)` at the beginning of your terminal prompt.

**💡 Tip:** You need to run this command again each time you open a new terminal. The script automatically detects it, but it's required for manual usage.

##### Step 3.3: Install Required Libraries

```bash
pip install torch torchvision pillow clip-anytorch tqdm
```

**What does this do?** Installs Python libraries required for AI thumbnail:
- `torch`: PyTorch (for AI model)
- `torchvision`: Image processing
- `pillow`: Image handling
- `clip-anytorch`: CLIP model (for AI thumbnail selection)
- `tqdm`: Progress bar

**⏱️ Duration:** This process may take 5-15 minutes (torch is a large package, ~2GB). Depends on your internet speed.

**If you get errors:**
- Check your internet connection
- Make sure virtual environment is active (`(venv_ai_thumb)` should be visible)
- Try `pip3` instead of `pip`

##### Step 3.4: Verify Installation

```bash
python3 -c "import clip_anytorch; print('✅ CLIP installed')"
```

**What does this do?** Checks if CLIP library is successfully installed.

**If successful:** You'll see `✅ CLIP installed`.

**If you get an error:** Repeat Step 3.3.

#### 4. Verify All Installation

```bash
# Check FFmpeg
ffmpeg -version

# Check Python
python3 --version

# Is virtual environment active? (Should see (venv_ai_thumb) at terminal start)
# If not visible:
source venv_ai_thumb/bin/activate
```

**If all checks pass:** You're ready to use the script! 🎉

### 📖 Usage

#### Basic Usage

1. **Place your videos in the script's folder**

2. **Run the script:**
   ```bash
   ./kirwem.sh
   ```

3. **Follow the prompts:**
   - Select device profile (1-4)
   - Select platform (Instagram/TikTok/YouTube Shorts)
   - Select video (All or single)
   - Optional settings:
     - ExifTool metadata
     - Social media optimization
     - Thumbnail (AI or first frame)

#### Folder Structure

After script execution:

```
Script/
├── kirwem.sh
├── ai_thumbnail.py
├── video1.mp4          # Original videos
├── video2.mp4
├── meta/               # Videos with metadata added
│   ├── video1_meta.mp4
│   └── video2_meta.mp4
├── optimized/          # Bitrate optimized videos
│   ├── video1_optimized.mp4
│   └── video2_optimized.mp4
└── logs/               # Log and report files
    ├── optimize_YYYYMMDD_HHMMSS.log
    └── report_YYYYMMDD_HHMMSS.txt
```

### 🎯 Platform Bitrate Settings

- **Instagram**: 12 Mbps
- **TikTok**: 8 Mbps  
- **YouTube Shorts**: 16 Mbps

### 📊 Output Files

#### Meta Folder
- Videos with metadata added
- FastStart optimization applied
- Original quality

#### Optimized Folder
- Platform-based bitrate optimization
- Bitrate optimized videos
- Smaller file size

#### Logs Folder
- Process logs
- Detailed reports
- Metadata test results

### 🔧 Troubleshooting

#### "externally-managed-environment" Error

This error occurs due to system Python environment protection. **You must use virtual environment:**

```bash
# Create virtual environment
python3 -m venv venv_ai_thumb

# Activate (should see (venv_ai_thumb) at terminal start)
source venv_ai_thumb/bin/activate

# Now pip install will work
pip install torch torchvision pillow clip-anytorch tqdm
```

**💡 Tip:** If `python3-all` is not installed, you may get this error:
```bash
sudo apt install python3-all
```

#### "CLIP library not found" Error

Activate virtual environment and install libraries:

```bash
source venv_ai_thumb/bin/activate
pip install clip-anytorch torch torchvision pillow tqdm
```

#### "ffmpeg: command not found"

FFmpeg is not installed. Run these commands:

```bash
sudo apt update
sudo apt install ffmpeg
```

After installation, verify:
```bash
ffmpeg -version
```

You should see a version number.

#### AI Thumbnail Not Working

1. **Check if virtual environment is active:**
   ```bash
   source venv_ai_thumb/bin/activate
   ```
   Should see `(venv_ai_thumb)` at terminal start.

2. **Check if libraries are installed:**
   ```bash
   python3 -c "import clip_anytorch; print('✅ CLIP installed')"
   ```
   If you get an error:
   ```bash
   pip install torch torchvision pillow clip-anytorch tqdm
   ```

3. **Script automatically falls back to first frame** (on error). This is normal, script continues working.

4. **Check if python3-all is installed:**
   ```bash
   sudo apt install python3-all
   ```

---

<a name="türkçe"></a>
## 🇹🇷 Türkçe

Sosyal medya platformları (Instagram, TikTok, YouTube Shorts) için video optimizasyon scripti. Metadata ekleme, FastStart optimizasyonu, AI destekli thumbnail seçimi ve platform bazlı bitrate ayarları içerir.

## ✨ Özellikler

- 📱 **Cihaz Profili Ekleme**: Meta AI, iPhone, Samsung gibi cihaz profilleri
- 🚀 **FastStart Optimizasyonu**: MOOV atom optimizasyonu ile hızlı yükleme
- 🎯 **Platform Optimizasyonu**: Instagram (12Mbps), TikTok (8Mbps), YouTube Shorts (16Mbps)
- 🤖 **AI Thumbnail**: CLIP modeli ile otomatik en iyi frame seçimi
- 📊 **Kalite Skoru**: Her video için 0-100 arası kalite değerlendirmesi
- ✅ **Metadata Doğrulama**: Her video için ayrı metadata kontrolü
- 📈 **Detaylı Rapor**: İşlem sonrası toplu rapor oluşturma
- 📁 **Organize Çıktı**: Meta ve Optimized klasörlerine otomatik ayrıştırma

## 📋 Gereksinimler

### Sistem Gereksinimleri

- **Linux** (Ubuntu/Debian önerilir)
- **Python 3.8+**
- **Bash shell**
- **İnternet bağlantısı** (kütüphane indirmek için)

### Gerekli Araçlar - Adım Adım Kurulum

**💡 İpucu:** Eğer Linux kullanmaya yeni başladıysanız, aşağıdaki komutları sırayla terminalde çalıştırın.

#### 1. Sistem Paketlerini Güncelle

```bash
sudo apt update
```
*Bu komut sistem paket listesini günceller. Şifre isteyebilir.*

#### 2. FFmpeg Kurulumu (Video İşleme İçin - ZORUNLU)

```bash
sudo apt install ffmpeg
```
*FFmpeg video dosyalarını işlemek için gereklidir. Kurulum sırasında "Y" (Evet) yazıp Enter'a basın.*

#### 3. Python ve Gerekli Paketler (ZORUNLU)

```bash
sudo apt install python3 python3-pip python3-venv python3-all
```
*Bu komut Python3 ve tüm gerekli bileşenleri yükler:*
- `python3`: Python programlama dili
- `python3-pip`: Python paket yöneticisi
- `python3-venv`: Virtual environment oluşturma aracı
- `python3-all`: Tüm Python geliştirme araçları (önerilir)

#### 4. ExifTool Kurulumu (Metadata İçin - OPSİYONEL)

```bash
sudo apt install libimage-exiftool-perl
```
*Bu araç video metadata'sını okumak/yazmak için kullanılır. Opsiyonel ama önerilir.*

#### 5. mp4dump Kurulumu (FastStart Kontrolü İçin - OPSİYONEL)

```bash
sudo apt install gpac
```
*Bu araç FastStart optimizasyonunun doğru uygulanıp uygulanmadığını kontrol eder. Opsiyonel ama önerilir.*

#### Kurulum Kontrolü

Tüm araçların yüklü olduğunu kontrol edin:

```bash
# FFmpeg kontrolü
ffmpeg -version

# Python kontrolü
python3 --version

# Pip kontrolü
pip3 --version
```

Her komut bir versiyon numarası göstermelidir. Eğer "command not found" hatası alırsanız, yukarıdaki kurulum adımlarını tekrar edin.

## 🚀 Kurulum - Başlangıçtan İtibaren

### 1. Repository'yi İndirin

**Git kullanıyorsanız:**
```bash
git clone https://github.com/blu7ck/video-optimizer.git
cd video-optimizer
```

**Git kullanmıyorsanız:**
1. GitHub sayfasından "Code" butonuna tıklayın
2. "Download ZIP" seçeneğini seçin
3. İndirilen ZIP dosyasını açın
4. Terminal'de klasöre gidin:
   ```bash
   cd ~/Downloads/video-optimizer-main
   ```

### 2. Script'i Çalıştırılabilir Yapın

Terminal'de şu komutları çalıştırın:

```bash
chmod +x kirwem.sh
chmod +x ai_thumbnail.py
```

**Ne yapar?** Bu komutlar script dosyalarına çalıştırma izni verir. "Permission denied" hatası almamak için gereklidir.

### 3. AI Thumbnail için Virtual Environment Kurulumu

**⚠️ ÖNEMLİ:** AI thumbnail özelliği için Python kütüphaneleri gereklidir. Bu adımı atlarsanız, script çalışır ama AI thumbnail özelliği kullanılamaz (ilk frame kullanılır).

#### Adım 3.1: Virtual Environment Oluştur

```bash
python3 -m venv venv_ai_thumb
```

**Ne yapar?** Bu komut `venv_ai_thumb` adında izole bir Python ortamı oluşturur. Bu sayede sistem Python'unuza dokunmadan kütüphaneleri yükleyebilirsiniz.

**Hata alırsanız:** `python3-all` paketini yüklediğinizden emin olun:
```bash
sudo apt install python3-all
```

#### Adım 3.2: Virtual Environment'ı Aktif Et

```bash
source venv_ai_thumb/bin/activate
```

**Ne yapar?** Virtual environment'ı aktif eder. Başarılı olduğunda terminal başında `(venv_ai_thumb)` yazısı görünür.

**💡 İpucu:** Her yeni terminal açtığınızda bu komutu tekrar çalıştırmanız gerekir. Script otomatik olarak algılar, ama manuel kullanım için gereklidir.

#### Adım 3.3: Gerekli Kütüphaneleri Yükle

```bash
pip install torch torchvision pillow clip-anytorch tqdm
```

**Ne yapar?** AI thumbnail için gerekli Python kütüphanelerini yükler:
- `torch`: PyTorch (AI modeli için)
- `torchvision`: Görüntü işleme
- `pillow`: Resim işleme
- `clip-anytorch`: CLIP modeli (AI thumbnail seçimi için)
- `tqdm`: İlerleme çubuğu

**⏱️ Süre:** Bu işlem 5-15 dakika sürebilir (torch büyük bir pakettir, ~2GB). İnternet hızınıza bağlıdır.

**Hata alırsanız:**
- İnternet bağlantınızı kontrol edin
- Virtual environment'ın aktif olduğundan emin olun (`(venv_ai_thumb)` görünmeli)
- `pip` yerine `pip3` deneyin

#### Adım 3.4: Kurulumu Doğrulayın

```bash
python3 -c "import clip_anytorch; print('✅ CLIP yüklü')"
```

**Ne yapar?** CLIP kütüphanesinin başarıyla yüklendiğini kontrol eder.

**Başarılı olursa:** `✅ CLIP yüklü` yazısı görünür.

**Hata alırsanız:** Adım 3.3'ü tekrar edin.

### 4. Tüm Kurulumu Kontrol Edin

```bash
# FFmpeg kontrolü
ffmpeg -version

# Python kontrolü
python3 --version

# Virtual environment aktif mi? (Terminal başında (venv_ai_thumb) görünmeli)
# Eğer görünmüyorsa:
source venv_ai_thumb/bin/activate
```

**Tüm kontroller başarılıysa:** Artık script'i kullanmaya hazırsınız! 🎉

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
├── optimized/          # Bitrate optimize edilmiş videolar
│   ├── video1_optimized.mp4
│   └── video2_optimized.mp4
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

### Optimized Klasörü
- Platform bazlı bitrate optimizasyonu
- Bitrate optimize edilmiş videolar
- Daha küçük dosya boyutu

### Logs Klasörü
- İşlem logları
- Detaylı raporlar
- Metadata test sonuçları

## 🔧 Sorun Giderme

### "externally-managed-environment" Hatası

Bu hata, sistem Python ortamının korunması nedeniyle oluşur. **Mutlaka virtual environment kullanın:**

```bash
# Virtual environment oluştur
python3 -m venv venv_ai_thumb

# Aktif et (terminal başında (venv_ai_thumb) görünmeli)
source venv_ai_thumb/bin/activate

# Şimdi pip install çalışacak
pip install torch torchvision pillow clip-anytorch tqdm
```

**💡 İpucu:** Eğer `python3-all` yüklü değilse bu hatayı alabilirsiniz:
```bash
sudo apt install python3-all
```

### "CLIP kütüphanesi bulunamadı" Hatası

Virtual environment'ı aktif edin ve kütüphaneleri yükleyin:

```bash
source venv_ai_thumb/bin/activate
pip install clip-anytorch torch torchvision pillow tqdm
```

### "ffmpeg: command not found"

FFmpeg yüklü değil. Şu komutları çalıştırın:

```bash
sudo apt update
sudo apt install ffmpeg
```

Kurulumdan sonra kontrol edin:
```bash
ffmpeg -version
```

Bir versiyon numarası görünmelidir.

### AI Thumbnail Çalışmıyor

1. **Virtual environment aktif mi kontrol edin:**
   ```bash
   source venv_ai_thumb/bin/activate
   ```
   Terminal başında `(venv_ai_thumb)` görünmeli.

2. **Kütüphaneler yüklü mü kontrol edin:**
   ```bash
   python3 -c "import clip_anytorch; print('✅ CLIP yüklü')"
   ```
   Eğer hata alırsanız:
   ```bash
   pip install torch torchvision pillow clip-anytorch tqdm
   ```

3. **Script otomatik olarak ilk frame'e geçer** (hata durumunda). Bu normaldir, script çalışmaya devam eder.

4. **python3-all yüklü mü kontrol edin:**
   ```bash
   sudo apt install python3-all
   ```

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
#    - optimized/ klasöründe optimize edilmiş videolar
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
**Son Güncelleme:** 2025/12

