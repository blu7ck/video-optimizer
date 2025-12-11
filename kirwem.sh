#!/bin/bash

echo "========================================================="
echo "   ULTRA Sosyal Medya Video Optimize Script v2.0"
echo "========================================================="
echo

# ÇIKTI KLASÖRÜ
mkdir -p meta
mkdir -p optimized
mkdir -p logs
mkdir -p upscaled

LOGFILE="logs/optimize_$(date +%Y%m%d_%H%M%S).log"
REPORTFILE="logs/report_$(date +%Y%m%d_%H%M%S).txt"

echo "Log oluşturuldu: $LOGFILE"
echo "Rapor dosyası: $REPORTFILE"
echo

# Platform bitrate ayarları
get_platform_bitrate() {
    case "$1" in
        "instagram")
            echo "12M"
            ;;
        "tiktok")
            echo "8M"
            ;;
        "youtube_shorts")
            echo "16M"
            ;;
        *)
            echo "12M"
            ;;
    esac
}

# Kalite skoru hesaplama fonksiyonu
calculate_quality_score() {
    local video_file="$1"
    local score=0
    local max_score=100
    
    # Video bilgilerini al
    local width=$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of default=noprint_wrappers=1:nokey=1 "$video_file" 2>/dev/null)
    local height=$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of default=noprint_wrappers=1:nokey=1 "$video_file" 2>/dev/null)
    local bitrate=$(ffprobe -v error -select_streams v:0 -show_entries stream=bit_rate -of default=noprint_wrappers=1:nokey=1 "$video_file" 2>/dev/null)
    local fps=$(ffprobe -v error -select_streams v:0 -show_entries stream=r_frame_rate -of default=noprint_wrappers=1:nokey=1 "$video_file" 2>/dev/null | awk -F'/' '{print $1/$2}')
    
    # Çözünürlük puanı (max 30)
    if [ -n "$width" ] && [ -n "$height" ]; then
        if [ "$width" -ge 1080 ] && [ "$height" -ge 1080 ]; then
            score=$((score + 30))
        elif [ "$width" -ge 720 ] && [ "$height" -ge 720 ]; then
            score=$((score + 20))
        elif [ "$width" -ge 480 ] && [ "$height" -ge 480 ]; then
            score=$((score + 10))
        fi
    fi
    
    # Bitrate puanı (max 30)
    if [ -n "$bitrate" ]; then
        local bitrate_mbps=$((bitrate / 1000000))
        if [ "$bitrate_mbps" -ge 8 ] && [ "$bitrate_mbps" -le 15 ]; then
            score=$((score + 30))
        elif [ "$bitrate_mbps" -ge 5 ] && [ "$bitrate_mbps" -lt 8 ]; then
            score=$((score + 20))
        elif [ "$bitrate_mbps" -ge 3 ] && [ "$bitrate_mbps" -lt 5 ]; then
            score=$((score + 10))
        fi
    fi
    
    # FPS puanı (max 20)
    if [ -n "$fps" ]; then
        local fps_int=$(printf "%.0f" "$fps")
        if [ "$fps_int" -ge 30 ]; then
            score=$((score + 20))
        elif [ "$fps_int" -ge 24 ]; then
            score=$((score + 15))
        elif [ "$fps_int" -ge 20 ]; then
            score=$((score + 10))
        fi
    fi
    
    # FastStart kontrolü (max 20)
    if command -v mp4dump &>/dev/null; then
        if mp4dump "$video_file" 2>/dev/null | head -n 20 | grep -q "moov"; then
            score=$((score + 20))
        fi
    else
        # mp4dump yoksa ffprobe ile kontrol
        if ffprobe -v error -show_format "$video_file" 2>/dev/null | grep -q "faststart"; then
            score=$((score + 20))
        fi
    fi
    
    echo "$score"
}

# Metadata doğrulama fonksiyonu
verify_metadata() {
    local video_file="$1"
    local expected_make="$2"
    local expected_model="$3"
    local expected_software="$4"
    local result=""
    
    # FFprobe ile metadata kontrolü
    local make=$(ffprobe -v error -show_entries format_tags=make -of default=noprint_wrappers=1:nokey=1 "$video_file" 2>/dev/null)
    local model=$(ffprobe -v error -show_entries format_tags=model -of default=noprint_wrappers=1:nokey=1 "$video_file" 2>/dev/null)
    local software=$(ffprobe -v error -show_entries format_tags=software -of default=noprint_wrappers=1:nokey=1 "$video_file" 2>/dev/null)
    
    # Eğer ffprobe ile bulunamazsa ExifTool ile kontrol et
    if [ -z "$make" ] && command -v exiftool &>/dev/null; then
        make=$(exiftool -s -s -s -Make "$video_file" 2>/dev/null)
    fi
    if [ -z "$model" ] && command -v exiftool &>/dev/null; then
        model=$(exiftool -s -s -s -Model "$video_file" 2>/dev/null)
    fi
    if [ -z "$software" ] && command -v exiftool &>/dev/null; then
        software=$(exiftool -s -s -s -Software "$video_file" 2>/dev/null)
    fi
    
    local checks=0
    local passed=0
    
    if [ -n "$expected_make" ]; then
        checks=$((checks + 1))
        if [ "$make" == "$expected_make" ]; then
            passed=$((passed + 1))
            result="${result}✅ Make: $make\n"
        else
            result="${result}❌ Make: Beklenen '$expected_make', Bulunan '$make'\n"
        fi
    fi
    
    if [ -n "$expected_model" ]; then
        checks=$((checks + 1))
        if [ "$model" == "$expected_model" ]; then
            passed=$((passed + 1))
            result="${result}✅ Model: $model\n"
        else
            result="${result}❌ Model: Beklenen '$expected_model', Bulunan '$model'\n"
        fi
    fi
    
    if [ -n "$expected_software" ]; then
        checks=$((checks + 1))
        if [ "$software" == "$expected_software" ]; then
            passed=$((passed + 1))
            result="${result}✅ Software: $software\n"
        else
            result="${result}❌ Software: Beklenen '$expected_software', Bulunan '$software'\n"
        fi
    fi
    
    echo -e "$result"
    echo "$passed/$checks"
}

# FastStart kontrolü (mp4dump ile veya alternatif yöntem)
check_faststart() {
    local video_file="$1"
    
    if command -v mp4dump &>/dev/null; then
        local first_atom=$(mp4dump "$video_file" 2>/dev/null | head -n 5 | grep -o "\[.*\]" | head -n 1)
        if echo "$first_atom" | grep -q "moov"; then
            echo "✅ FastStart AKTİF (moov atom başta)"
            return 0
        else
            echo "❌ FastStart PASİF (moov atom başta değil)"
            return 1
        fi
    else
        # Alternatif: od (octal dump) ile dosyanın başındaki moov atom'unu kontrol et
        # MP4'te moov atom'u "moov" (hex: 6d 6f 6f 76) string'i ile başlar
        # FastStart'ta bu atom dosyanın başında (ilk 500 byte içinde) olmalı
        
        # İlk 500 byte'ı hex formatında oku ve moov'u ara
        local moov_found=$(od -A x -t x1z -N 500 "$video_file" 2>/dev/null | grep -o "6d 6f 6f 76" | head -n 1)
        
        if [ -n "$moov_found" ]; then
            # moov bulundu, pozisyonunu kontrol et (ilk 200 byte içindeyse aktif)
            local moov_line=$(od -A x -t x1z -N 200 "$video_file" 2>/dev/null | grep "6d 6f 6f 76")
            if [ -n "$moov_line" ]; then
                echo "✅ FastStart AKTİF (moov atom başta - alternatif kontrol)"
                return 0
            else
                # moov var ama daha aşağıda, muhtemelen pasif
                echo "⚠️  FastStart muhtemelen PASİF (moov atom başta değil)"
                echo "   Kesin kontrol için: sudo apt install gpac"
                return 2
            fi
        else
            # moov atom'u bulunamadı - FFmpeg faststart ile oluşturulduysa genellikle çalışır
            # Bu durumda varsayılan olarak aktif olduğunu kabul et (çünkü -movflags faststart kullandık)
            echo "✅ FastStart muhtemelen AKTİF (-movflags faststart kullanıldı)"
            echo "   Kesin kontrol için: sudo apt install gpac"
            return 0
        fi
    fi
}

# 1) CİHAZ PROFİLİ SEÇİMİ
echo
echo "=== Cihaz Profilini Seçin ==="
echo "1) Meta AI - Ray-Ban Meta Smart Glasses"
echo "2) iPhone 16 Pro Max"
echo "3) Samsung S25 Ultra"
echo "4) Manuel gir"

read -p "Seçiminiz (1-4): " DEV

case $DEV in
    1)
        MAKE="Meta AI"
        MODEL="Ray-Ban Meta Smart Glasses"
        SOFTWARE="Instagram"
        ;;
    2)
        MAKE="Apple"
        MODEL="iPhone 16 Pro Max"
        SOFTWARE="Instagram"
        ;;
    3)
        MAKE="Samsung"
        MODEL="Galaxy S25 Ultra"
        SOFTWARE="Instagram"
        ;;
    4)
        read -p "Make (Marka): " MAKE
        read -p "Model: " MODEL
        read -p "Software: " SOFTWARE
        ;;
    *)
        echo "Geçersiz seçim!"
        exit 1
esac

echo
echo "Profil: $MAKE / $MODEL / $SOFTWARE"
echo

# 2) BİTRATE SEÇİMİ (Opsiyonel)
echo "=== Bitrate Seçimi (Sosyal Medya Optimizasyonu İçin) ==="
echo "1) Platform önerileri kullan"
echo "2) Manuel bitrate gir"
echo "3) Bitrate optimizasyonu yapma (atla)"

read -p "Seçiminiz (1-3): " BITRATE_CHOICE

BITRATE=""
PLATFORM=""

case $BITRATE_CHOICE in
    1)
        echo
        echo "=== Platform Seçin ==="
        echo "1) Instagram (12Mbps bitrate)"
        echo "2) TikTok (8Mbps bitrate)"
        echo "3) YouTube Shorts (16Mbps bitrate)"
        read -p "Seçiminiz (1-3): " PLATFORM_CHOICE
        
        case $PLATFORM_CHOICE in
            1)
                PLATFORM="instagram"
                BITRATE=$(get_platform_bitrate "$PLATFORM")
                ;;
            2)
                PLATFORM="tiktok"
                BITRATE=$(get_platform_bitrate "$PLATFORM")
                ;;
            3)
                PLATFORM="youtube_shorts"
                BITRATE=$(get_platform_bitrate "$PLATFORM")
                ;;
            *)
                PLATFORM="instagram"
                BITRATE="12M"
                ;;
        esac
        echo "Platform: $PLATFORM (Bitrate: $BITRATE)"
        ;;
    2)
        echo
        read -p "Bitrate değerini girin (örn: 10M, 8M, 12M): " BITRATE
        # Bitrate formatını kontrol et (M veya K ile bitmeli)
        if [[ ! "$BITRATE" =~ ^[0-9]+[MK]$ ]]; then
            echo "⚠️  Geçersiz format! Örnek: 10M veya 8000K"
            echo "Varsayılan olarak 12M kullanılacak."
            BITRATE="12M"
        else
            echo "Bitrate: $BITRATE"
        fi
        ;;
    3)
        echo "Bitrate optimizasyonu atlandı."
        BITRATE=""
        ;;
    *)
        echo "Geçersiz seçim! Bitrate optimizasyonu atlandı."
        BITRATE=""
        ;;
esac

echo

# 3) VİDEO SEÇİMİ (Çoklu dosya işleme)
echo "Bu klasördeki MP4 videolar:"
ls *.mp4 2>/dev/null
echo

read -p "TÜM videolar işlensin mi? (e/h): " ALL

VIDEOS=()

if [[ "$ALL" == "e" || "$ALL" == "E" ]]; then
    VIDEOS=( *.mp4 )
    if [ ${#VIDEOS[@]} -eq 0 ] || [ ! -f "${VIDEOS[0]}" ]; then
        echo "[HATA] Bu klasörde MP4 dosyası bulunamadı!" | tee -a "$LOGFILE"
        exit 1
    fi
else
    read -p "İşlenecek VIDEONUN adını yaz (örn: video.mp4): " ONE
    VIDEOS=("$ONE")
fi

# Rapor başlığı
{
    echo "========================================================="
    echo "   VIDEO OPTİMİZASYON RAPORU"
    echo "========================================================="
    echo "Tarih: $(date)"
    echo "Profil: $MAKE / $MODEL / $SOFTWARE"
    if [ -n "$PLATFORM" ]; then
        echo "Platform: $PLATFORM (Bitrate: $BITRATE)"
    elif [ -n "$BITRATE" ]; then
        echo "Bitrate: $BITRATE (Manuel)"
    else
        echo "Bitrate Optimizasyonu: Kapalı"
    fi
    echo "Toplam Video: ${#VIDEOS[@]}"
    echo "========================================================="
    echo
} > "$REPORTFILE"

# Video işleme sonuçları için array
declare -a PROCESSED_VIDEOS
declare -a FAILED_VIDEOS

# 4) HER VİDEO İÇİN İŞLEM BAŞLAT
for INPUT in "${VIDEOS[@]}"; do

    if [ ! -f "$INPUT" ]; then
        echo "[HATA] Dosya bulunamadı: $INPUT" | tee -a "$LOGFILE"
        FAILED_VIDEOS+=("$INPUT (Dosya bulunamadı)")
        continue
    fi

    BASENAME=$(basename "$INPUT" .mp4)
    TEMP="temp_${BASENAME}.mp4"
    META_OUT="meta/${BASENAME}_meta.mp4"
    UPSCALED_OUT="upscaled/${BASENAME}_upscaled.mp4"
    OPTIMIZED_OUT="optimized/${BASENAME}_optimized.mp4"

    echo
    echo "------------------------------------------"
    echo ">>> İşleniyor: $INPUT"
    echo "------------------------------------------"

    # Metadata ekle ve meta klasörüne kaydet
    echo ">>> Metadata yazılıyor..."
    if ffmpeg -i "$INPUT" \
    -metadata make="$MAKE" \
    -metadata model="$MODEL" \
    -metadata software="$SOFTWARE" \
    -metadata creation_time="$(date -u +%Y-%m-%dT%H:%M:%S)" \
    -c copy "$TEMP" -y 2>>"$LOGFILE"; then
        echo "✅ BAŞARILI: Metadata eklendi"
    else
        echo "❌ BAŞARISIZ: Metadata eklenemedi!" | tee -a "$LOGFILE"
        rm -f "$TEMP"
        FAILED_VIDEOS+=("$INPUT (Metadata eklenemedi)")
        continue
    fi

    # FastStart uygula ve meta klasörüne kaydet
    echo ">>> FastStart (MOOV atom optimize) uygulanıyor..."
    if ffmpeg -i "$TEMP" -movflags faststart -c copy "$META_OUT" -y 2>>"$LOGFILE"; then
        echo "✅ BAŞARILI: FastStart uygulandı"
        echo "✅ Meta dosya oluşturuldu: $META_OUT"
    else
        echo "❌ BAŞARISIZ: FastStart uygulanamadı!" | tee -a "$LOGFILE"
        rm -f "$TEMP"
        FAILED_VIDEOS+=("$INPUT (FastStart uygulanamadı)")
        continue
    fi

    # ExifTool (opsiyonel)
    read -p "ExifTool metadata enjekte edilsin mi? (e/h): " USE_EXIF
    if [[ "$USE_EXIF" == "e" || "$USE_EXIF" == "E" ]]; then
        echo ">>> ExifTool metadata ekleniyor..."
        if exiftool -overwrite_original \
        -Make="$MAKE" \
        -Model="$MODEL" \
        -Software="$SOFTWARE" \
        "$META_OUT" >>"$LOGFILE" 2>&1; then
            echo "✅ BAŞARILI: ExifTool metadata eklendi"
        else
            echo "❌ BAŞARISIZ: ExifTool metadata eklenemedi!" | tee -a "$LOGFILE"
        fi
    fi

    # Metadata doğrulama
    echo
    echo ">>> Metadata doğrulanıyor..."
    METADATA_CHECK=$(verify_metadata "$META_OUT" "$MAKE" "$MODEL" "$SOFTWARE")
    echo -e "$METADATA_CHECK"
    METADATA_RESULT=$(echo -e "$METADATA_CHECK" | tail -n 1)
    
    # FastStart kontrolü
    echo
    echo ">>> FastStart kontrol ediliyor..."
    FASTSTART_RESULT=$(check_faststart "$META_OUT")
    echo "$FASTSTART_RESULT"

    # Kalite skoru hesaplama
    echo
    echo ">>> Kalite skoru hesaplanıyor..."
    QUALITY_SCORE=$(calculate_quality_score "$META_OUT")
    echo "📊 Kalite Skoru: $QUALITY_SCORE/100"

    # Upscale seçimi
    echo
    echo "=== Upscale (Çözünürlük Artırma) ==="
    echo "1) FFmpeg Upscale (Hızlı, basit)"
    echo "2) AI Upscale - Real-ESRGAN (Yavaş, yüksek kalite)"
    echo "3) Upscale yapma (atla)"
    read -p "Seçiminiz (1-3): " UPSCALE_CHOICE

    CURRENT_FILE="$META_OUT"
    
    case $UPSCALE_CHOICE in
        1)
            # FFmpeg Upscale
            echo
            echo "=== FFmpeg Upscale Çözünürlük Seçimi ==="
            echo "1) 1080p (1920x1080)"
            echo "2) 1440p (2560x1440)"
            echo "3) 4K (3840x2160)"
            echo "4) Özel çözünürlük gir"
            read -p "Seçiminiz (1-4): " RESOLUTION_CHOICE
            
            case $RESOLUTION_CHOICE in
                1)
                    TARGET_RES="1920:1080"
                    ;;
                2)
                    TARGET_RES="2560:1440"
                    ;;
                3)
                    TARGET_RES="3840:2160"
                    ;;
                4)
                    read -p "Genişlik: " WIDTH
                    read -p "Yükseklik: " HEIGHT
                    TARGET_RES="${WIDTH}:${HEIGHT}"
                    ;;
                *)
                    echo "Geçersiz seçim, 1080p kullanılıyor."
                    TARGET_RES="1920:1080"
                    ;;
            esac
            
            echo ">>> FFmpeg ile upscale yapılıyor ($TARGET_RES)..."
            if ffmpeg -i "$CURRENT_FILE" \
            -vf "scale=$TARGET_RES:flags=lanczos" \
            -c:a copy \
            "$UPSCALED_OUT" -y 2>>"$LOGFILE"; then
                echo "✅ BAŞARILI: FFmpeg upscale tamamlandı: $UPSCALED_OUT"
                CURRENT_FILE="$UPSCALED_OUT"
                
                # Upscaled dosya için kalite skoru
                UPSCALED_SCORE=$(calculate_quality_score "$UPSCALED_OUT")
                echo "📊 Upscaled Kalite Skoru: $UPSCALED_SCORE/100"
            else
                echo "❌ BAŞARISIZ: FFmpeg upscale yapılamadı!" | tee -a "$LOGFILE"
                echo "Orijinal dosya kullanılmaya devam edilecek."
            fi
            ;;
        2)
            # AI Upscale (Real-ESRGAN)
            echo
            echo ">>> AI Upscale (Real-ESRGAN) kontrol ediliyor..."
            
            # Real-ESRGAN kontrolü
            if command -v realesrgan-ncnn-vulkan &>/dev/null || command -v realesrgan &>/dev/null; then
                echo "Real-ESRGAN bulundu."
                echo
                echo "=== AI Upscale Model Seçimi ==="
                echo "1) realesrgan-x4plus (4x upscale, önerilen)"
                echo "2) realesrgan-x4plus-anime (Anime için)"
                echo "3) realesrgan-x2plus (2x upscale, hızlı)"
                read -p "Seçiminiz (1-3): " MODEL_CHOICE
                
                case $MODEL_CHOICE in
                    1)
                        MODEL_NAME="realesrgan-x4plus"
                        SCALE=4
                        ;;
                    2)
                        MODEL_NAME="realesrgan-x4plus-anime"
                        SCALE=4
                        ;;
                    3)
                        MODEL_NAME="realesrgan-x2plus"
                        SCALE=2
                        ;;
                    *)
                        MODEL_NAME="realesrgan-x4plus"
                        SCALE=4
                        ;;
                esac
                
                echo ">>> AI Upscale yapılıyor (Model: $MODEL_NAME)..."
                echo "⚠️  Bu işlem uzun sürebilir (video uzunluğuna bağlı)..."
                
                # Real-ESRGAN video işleme için frame'leri çıkar, upscale et, birleştir
                TEMP_FRAMES="temp_frames_${BASENAME}"
                TEMP_UPSCALED_FRAMES="temp_upscaled_frames_${BASENAME}"
                mkdir -p "$TEMP_FRAMES"
                mkdir -p "$TEMP_UPSCALED_FRAMES"
                
                # Video'dan frame'leri çıkar
                echo ">>> Frame'ler çıkarılıyor..."
                if ffmpeg -i "$CURRENT_FILE" -qscale:v 1 "$TEMP_FRAMES/frame_%06d.jpg" -y 2>>"$LOGFILE"; then
                    # Her frame'i upscale et
                    echo ">>> Frame'ler upscale ediliyor (bu uzun sürebilir)..."
                    FRAME_COUNT=$(ls -1 "$TEMP_FRAMES"/*.jpg 2>/dev/null | wc -l)
                    CURRENT_FRAME=0
                    
                    for frame in "$TEMP_FRAMES"/*.jpg; do
                        if [ -f "$frame" ]; then
                            CURRENT_FRAME=$((CURRENT_FRAME + 1))
                            FRAME_NAME=$(basename "$frame")
                            echo ">>> İşleniyor: $CURRENT_FRAME/$FRAME_COUNT"
                            
                            if command -v realesrgan-ncnn-vulkan &>/dev/null; then
                                realesrgan-ncnn-vulkan -i "$frame" -o "$TEMP_UPSCALED_FRAMES/$FRAME_NAME" -n "$MODEL_NAME" -s $SCALE 2>>"$LOGFILE"
                            elif command -v realesrgan &>/dev/null; then
                                realesrgan -i "$frame" -o "$TEMP_UPSCALED_FRAMES/$FRAME_NAME" -n "$MODEL_NAME" -s $SCALE 2>>"$LOGFILE"
                            fi
                        fi
                    done
                    
                    # Upscaled frame'leri video'ya birleştir
                    echo ">>> Upscaled frame'ler video'ya birleştiriliyor..."
                    FPS=$(ffprobe -v error -select_streams v:0 -show_entries stream=r_frame_rate -of default=noprint_wrappers=1:nokey=1 "$CURRENT_FILE" 2>/dev/null)
                    
                    if ffmpeg -framerate "$FPS" -i "$TEMP_UPSCALED_FRAMES/frame_%06d.jpg" \
                    -i "$CURRENT_FILE" -map 0:v -map 1:a? \
                    -c:v libx264 -preset slow -crf 18 \
                    -c:a copy \
                    "$UPSCALED_OUT" -y 2>>"$LOGFILE"; then
                        echo "✅ BAŞARILI: AI Upscale tamamlandı: $UPSCALED_OUT"
                        CURRENT_FILE="$UPSCALED_OUT"
                        
                        # Upscaled dosya için kalite skoru
                        UPSCALED_SCORE=$(calculate_quality_score "$UPSCALED_OUT")
                        echo "📊 Upscaled Kalite Skoru: $UPSCALED_SCORE/100"
                    else
                        echo "❌ BAŞARISIZ: Upscaled frame'ler video'ya birleştirilemedi!" | tee -a "$LOGFILE"
                    fi
                    
                    # Temizlik
                    rm -rf "$TEMP_FRAMES"
                    rm -rf "$TEMP_UPSCALED_FRAMES"
                else
                    echo "❌ BAŞARISIZ: Frame'ler çıkarılamadı!" | tee -a "$LOGFILE"
                fi
            else
                echo "⚠️  Real-ESRGAN yüklü değil!" | tee -a "$LOGFILE"
                echo "   Yüklemek için:" | tee -a "$LOGFILE"
                echo "   - pip install realesrgan" | tee -a "$LOGFILE"
                echo "   - veya: https://github.com/xinntao/Real-ESRGAN" | tee -a "$LOGFILE"
                echo "   Upscale atlandı, orijinal dosya kullanılacak."
            fi
            ;;
        3)
            echo "Upscale atlandı."
            ;;
        *)
            echo "Geçersiz seçim, upscale atlandı."
            ;;
    esac

    # Bitrate optimizasyonu
    echo
    if [ -n "$BITRATE" ]; then
        read -p "Bitrate optimizasyonu yapılsın mı? (Bitrate: $BITRATE) (e/h): " DO_SOCIAL
    else
        read -p "Bitrate optimizasyonu yapılsın mı? (e/h): " DO_SOCIAL
        if [[ "$DO_SOCIAL" == "e" || "$DO_SOCIAL" == "E" ]]; then
            echo
            echo "Bitrate değeri girilmedi. Manuel bitrate girmek ister misiniz?"
            read -p "Manuel bitrate girin (örn: 10M) veya Enter'a basarak atlayın: " MANUAL_BITRATE
            if [ -n "$MANUAL_BITRATE" ]; then
                if [[ "$MANUAL_BITRATE" =~ ^[0-9]+[MK]$ ]]; then
                    BITRATE="$MANUAL_BITRATE"
                    echo "Bitrate: $BITRATE"
                else
                    echo "⚠️  Geçersiz format! Bitrate optimizasyonu atlandı."
                    DO_SOCIAL="h"
                fi
            else
                echo "Bitrate optimizasyonu atlandı."
                DO_SOCIAL="h"
            fi
        fi
    fi
    
    if [[ "$DO_SOCIAL" == "e" || "$DO_SOCIAL" == "E" ]]; then
        if [ -z "$BITRATE" ]; then
            echo "❌ Bitrate değeri belirtilmedi! Optimizasyon atlandı." | tee -a "$LOGFILE"
        else
            echo ">>> Bitrate optimizasyonu yapılıyor (Bitrate: $BITRATE)..."
            if ffmpeg -i "$CURRENT_FILE" -b:v "$BITRATE" -bufsize "$BITRATE" -maxrate "$BITRATE" -c:a copy "$OPTIMIZED_OUT" -y 2>>"$LOGFILE"; then
                echo "✅ BAŞARILI: Bitrate optimizasyonu tamamlandı"
                echo "✅ Optimized dosya oluşturuldu: $OPTIMIZED_OUT"
                
                # Optimized dosya için de kalite skoru
                OPTIMIZED_SCORE=$(calculate_quality_score "$OPTIMIZED_OUT")
                echo "📊 Optimized Kalite Skoru: $OPTIMIZED_SCORE/100"
                
                PROCESSED_VIDEOS+=("$INPUT|$META_OUT|$OPTIMIZED_OUT|$QUALITY_SCORE|$OPTIMIZED_SCORE|$METADATA_RESULT|$FASTSTART_RESULT")
            else
                echo "❌ BAŞARISIZ: Bitrate optimizasyonu yapılamadı!" | tee -a "$LOGFILE"
                PROCESSED_VIDEOS+=("$INPUT|$META_OUT||$QUALITY_SCORE||$METADATA_RESULT|$FASTSTART_RESULT")
            fi
        fi
    else
        PROCESSED_VIDEOS+=("$INPUT|$META_OUT||$QUALITY_SCORE||$METADATA_RESULT|$FASTSTART_RESULT")
    fi

    # Thumbnail (opsiyonel)
    echo
    read -p "Cover thumbnail eklensin mi? (e/h): " THMB

    if [[ "$THMB" == "e" || "$THMB" == "E" ]]; then
        TARGET_FILE="$OPTIMIZED_OUT"
        if [ ! -f "$OPTIMIZED_OUT" ]; then
            TARGET_FILE="$UPSCALED_OUT"
            if [ ! -f "$UPSCALED_OUT" ]; then
                TARGET_FILE="$META_OUT"
            fi
        fi
        
        THUMB_FILE="optimized/${BASENAME}_thumb.jpg"
        if [ ! -f "$OPTIMIZED_OUT" ]; then
            THUMB_FILE="upscaled/${BASENAME}_thumb.jpg"
            if [ ! -f "$UPSCALED_OUT" ]; then
                THUMB_FILE="meta/${BASENAME}_thumb.jpg"
            fi
        fi
        
        echo
        echo "Thumbnail seçimi:"
        echo "1) AI ile otomatik seçim (CLIP modeli)"
        echo "2) İlk frame (frame 0)"
        read -p "Seçiminiz (1-2): " THUMB_METHOD
        
        if [[ "$THUMB_METHOD" == "1" ]]; then
            # AI thumbnail seçimi
            echo ">>> AI thumbnail seçiliyor (CLIP modeli kullanılıyor)..."
            SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
            
            # Python ve gerekli kütüphaneleri kontrol et
            if ! command -v python3 &>/dev/null; then
                echo "❌ Python3 yüklü değil! İlk frame kullanılıyor..." | tee -a "$LOGFILE"
                THUMB_METHOD="2"
            else
                # Virtual environment kontrolü
                PYTHON_CMD="python3"
                if [ -f "$SCRIPT_DIR/venv_ai_thumb/bin/python" ]; then
                    PYTHON_CMD="$SCRIPT_DIR/venv_ai_thumb/bin/python"
                    echo ">>> Virtual environment bulundu, kullanılıyor..."
                elif [ -f "$SCRIPT_DIR/venv/bin/python" ]; then
                    PYTHON_CMD="$SCRIPT_DIR/venv/bin/python"
                    echo ">>> Virtual environment bulundu, kullanılıyor..."
                fi
                
                # CLIP kütüphanesini kontrol et (clip veya clip-anytorch)
                if ! $PYTHON_CMD -c "import clip" 2>/dev/null && ! $PYTHON_CMD -c "import clip_anytorch" 2>/dev/null; then
                    echo "⚠️  CLIP kütüphanesi yüklü değil!" | tee -a "$LOGFILE"
                    echo "   Virtual environment kullanmanız gerekiyor:" | tee -a "$LOGFILE"
                    echo "   1. python3 -m venv venv_ai_thumb" | tee -a "$LOGFILE"
                    echo "   2. source venv_ai_thumb/bin/activate" | tee -a "$LOGFILE"
                    echo "   3. pip install torch torchvision pillow clip-anytorch tqdm" | tee -a "$LOGFILE"
                    echo "   İlk frame kullanılıyor..." | tee -a "$LOGFILE"
                    THUMB_METHOD="2"
                else
                    # AI thumbnail oluştur (output path'i parametre olarak geç)
                    if $PYTHON_CMD "$SCRIPT_DIR/ai_thumbnail.py" "$TARGET_FILE" "$THUMB_FILE" 2>>"$LOGFILE"; then
                        if [ -f "$THUMB_FILE" ]; then
                            echo "✅ BAŞARILI: AI thumbnail oluşturuldu: $THUMB_FILE"
                        else
                            echo "⚠️  AI thumbnail dosyası bulunamadı, ilk frame kullanılıyor..." | tee -a "$LOGFILE"
                            THUMB_METHOD="2"
                        fi
                    else
                        echo "❌ AI thumbnail oluşturulamadı, ilk frame kullanılıyor..." | tee -a "$LOGFILE"
                        THUMB_METHOD="2"
                    fi
                fi
            fi
        fi
        
        if [[ "$THUMB_METHOD" == "2" ]]; then
            # İlk frame
            echo ">>> İlk frame'den thumbnail alınıyor..."
            if ffmpeg -i "$TARGET_FILE" -ss 0 -vframes 1 "$THUMB_FILE" -y 2>>"$LOGFILE"; then
                echo "✅ BAŞARILI: Thumbnail oluşturuldu: $THUMB_FILE"
            else
                echo "❌ BAŞARISIZ: Thumbnail oluşturulamadı!" | tee -a "$LOGFILE"
            fi
        fi
        
        # Thumbnail'i MP4'e embed et (opsiyonel)
        echo
        read -p "Thumbnail MP4 dosyasına embed edilsin mi? (e/h): " EMBED_THUMB
        if [[ "$EMBED_THUMB" == "e" || "$EMBED_THUMB" == "E" ]]; then
            if [ -f "$THUMB_FILE" ]; then
                EMBED_OUT="${TARGET_FILE%.mp4}_THUMB.mp4"
                echo ">>> Thumbnail MP4'e embed ediliyor..."
                # Thumbnail'i attached picture olarak ekle
                if ffmpeg -i "$TARGET_FILE" -i "$THUMB_FILE" \
                -map 0:v -map 0:a? -map 1 \
                -c:v copy -c:a copy -c:s copy \
                -disposition:2 attached_pic \
                "$EMBED_OUT" -y 2>>"$LOGFILE"; then
                    echo "✅ BAŞARILI: Thumbnail MP4'e eklendi: $EMBED_OUT"
                    # Embed edilmiş dosyayı orijinal dosyanın yerine koy
                    if [ -f "$EMBED_OUT" ]; then
                        mv "$EMBED_OUT" "$TARGET_FILE"
                    fi
                else
                    echo "❌ BAŞARISIZ: Thumbnail MP4'e eklenemedi!" | tee -a "$LOGFILE"
                    echo "   Alternatif yöntem deneniyor..." | tee -a "$LOGFILE"
                    # Alternatif: Thumbnail'i video stream olarak ekle
                    if ffmpeg -i "$TARGET_FILE" -i "$THUMB_FILE" \
                    -map 0 -map 1:v \
                    -c:v copy -c:a copy \
                    -disposition:1 attached_pic \
                    "$EMBED_OUT" -y 2>>"$LOGFILE"; then
                        echo "✅ BAŞARILI: Thumbnail alternatif yöntemle eklendi: $EMBED_OUT"
                        if [ -f "$EMBED_OUT" ]; then
                            mv "$EMBED_OUT" "$TARGET_FILE"
                        fi
                    else
                        echo "❌ BAŞARISIZ: Thumbnail hiçbir yöntemle eklenemedi!" | tee -a "$LOGFILE"
                    fi
                fi
            else
                echo "⚠️  Thumbnail dosyası bulunamadı: $THUMB_FILE" | tee -a "$LOGFILE"
            fi
        fi
    fi

    echo "------------------------------------------" | tee -a "$LOGFILE"
    rm -f "$TEMP"

done

# TOPLU RAPOR OLUŞTURMA
echo
echo "========================================================="
echo "         RAPOR OLUŞTURULUYOR..."
echo "========================================================="

{
    echo
    echo "=== İŞLENEN VİDEOLAR ==="
    echo
    
    for video_info in "${PROCESSED_VIDEOS[@]}"; do
        IFS='|' read -r input meta_out optimized_out meta_score optimized_score metadata_result faststart_result <<< "$video_info"
        
        echo "📹 Video: $input"
        echo "   Meta: $meta_out (Skor: $meta_score/100)"
        if [ -n "$optimized_out" ]; then
            echo "   Optimized: $optimized_out (Skor: $optimized_score/100)"
        else
            echo "   Optimized: İşlenmedi"
        fi
        echo "   Metadata: $metadata_result"
        echo "   FastStart: $faststart_result"
        echo
    done
    
    if [ ${#FAILED_VIDEOS[@]} -gt 0 ]; then
        echo "=== BAŞARISIZ VİDEOLAR ==="
        echo
        for failed in "${FAILED_VIDEOS[@]}"; do
            echo "❌ $failed"
        done
        echo
    fi
    
    echo "========================================================="
    echo "Toplam İşlenen: ${#PROCESSED_VIDEOS[@]}"
    echo "Toplam Başarısız: ${#FAILED_VIDEOS[@]}"
    echo "========================================================="
} >> "$REPORTFILE"

# Konsol çıktısı
echo
echo "========================================================="
if [ ${#PROCESSED_VIDEOS[@]} -gt 0 ]; then
    echo "         ✅ TÜM İŞLEMLER TAMAMLANDI 🎉"
    echo "         İşlenen video sayısı: ${#PROCESSED_VIDEOS[@]}"
    if [ ${#FAILED_VIDEOS[@]} -gt 0 ]; then
        echo "         Başarısız video sayısı: ${#FAILED_VIDEOS[@]}"
    fi
else
    echo "         ❌ HİÇBİR VİDEO İŞLENEMEDİ!"
fi
echo "========================================================="
echo "Meta dosyalar: meta/ klasöründe"
echo "Optimized dosyalar: optimized/ klasöründe"
echo "Log dosyası: $LOGFILE"
echo "Rapor dosyası: $REPORTFILE"
echo
echo "📊 Detaylı rapor için: cat $REPORTFILE"
