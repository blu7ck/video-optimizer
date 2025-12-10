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
**Son Güncelleme:** 2025/12

