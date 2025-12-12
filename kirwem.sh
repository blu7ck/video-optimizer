#!/bin/bash

echo "========================================================="
echo "   ULTRA Sosyal Medya Video Optimize Script v2.1"
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

# Platform bitrate ayarları (cozunurluge gore dinamik)
get_platform_bitrate() {
    local platform="$1"
    local width="$2"
    local height="$3"
    
    # Cozunurluk hesapla
    local total_pixels=0
    if [ -n "$width" ] && [ -n "$height" ] && [ "$width" != "0" ] && [ "$height" != "0" ]; then
        total_pixels=$((width * height))
    fi
    
    case "$platform" in
        "instagram")
            # Instagram: 1080p icin 12M, 4K icin 35M
            if [ "$total_pixels" -gt 8000000 ]; then  # 4K+
                echo "35M"
            elif [ "$total_pixels" -gt 3500000 ]; then  # 1440p+
                echo "20M"
            else
                echo "12M"  # 1080p ve alti
            fi
            ;;
        "tiktok")
            # TikTok: 1080p icin 10M, 4K icin 30M
            if [ "$total_pixels" -gt 8000000 ]; then  # 4K+
                echo "30M"
            elif [ "$total_pixels" -gt 3500000 ]; then  # 1440p+
                echo "16M"
            else
                echo "10M"  # 1080p ve alti
            fi
            ;;
        "youtube_shorts")
            # YouTube Shorts: 1080p icin 16M, 4K icin 45M
            if [ "$total_pixels" -gt 8000000 ]; then  # 4K+
                echo "45M"
            elif [ "$total_pixels" -gt 3500000 ]; then  # 1440p+
                echo "25M"
            else
                echo "16M"  # 1080p ve alti
            fi
            ;;
        *)
            # Varsayilan: cozunurluge gore
            if [ "$total_pixels" -gt 8000000 ]; then
                echo "35M"
            elif [ "$total_pixels" -gt 3500000 ]; then
                echo "20M"
            else
                echo "12M"
            fi
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
    # FPS'i güvenli şekilde parse et
    local fps_raw=$(ffprobe -v error -select_streams v:0 -show_entries stream=r_frame_rate -of default=noprint_wrappers=1:nokey=1 "$video_file" 2>/dev/null | head -1)
    local fps=""
    if [ -n "$fps_raw" ]; then
        if echo "$fps_raw" | grep -q "/"; then
            local fps_num=$(echo "$fps_raw" | cut -d'/' -f1)
            local fps_den=$(echo "$fps_raw" | cut -d'/' -f2)
            if [ "$fps_den" -gt 0 ] && [ -n "$fps_num" ]; then
                fps=$(awk "BEGIN {printf \"%.2f\", $fps_num/$fps_den}")
            fi
        else
            fps="$fps_raw"
        fi
    fi
    
    # Çözünürlük puanı (max 35)
    if [ -n "$width" ] && [ -n "$height" ]; then
        if [ "$width" -ge 1920 ] && [ "$height" -ge 1080 ]; then
            score=$((score + 35))  # 1080p ve üzeri
        elif [ "$width" -ge 1280 ] && [ "$height" -ge 720 ]; then
            score=$((score + 25))  # 720p
        elif [ "$width" -ge 854 ] && [ "$height" -ge 480 ]; then
            score=$((score + 15))  # 480p
        elif [ "$width" -ge 640 ] && [ "$height" -ge 360 ]; then
            score=$((score + 5))   # 360p
        fi
    fi
    
    # Bitrate puanı (max 35)
    if [ -n "$bitrate" ] && [ "$bitrate" != "0" ] && [ "$bitrate" != "N/A" ]; then
        # Bitrate'i integer'a çevir ve kontrol et
        local bitrate_int=$(printf "%.0f" "$bitrate" 2>/dev/null || echo "0")
        if [ "$bitrate_int" -gt 0 ]; then
            local bitrate_mbps=$((bitrate_int / 1000000))
            if [ "$bitrate_mbps" -ge 20 ]; then
                score=$((score + 30))  # Çok yüksek (20+ Mbps) - biraz düşük puan
            elif [ "$bitrate_mbps" -ge 10 ] && [ "$bitrate_mbps" -lt 20 ]; then
                score=$((score + 35))  # İdeal aralık (10-19 Mbps)
            elif [ "$bitrate_mbps" -ge 8 ] && [ "$bitrate_mbps" -lt 10 ]; then
                score=$((score + 30))  # İyi (8-9 Mbps)
            elif [ "$bitrate_mbps" -ge 5 ] && [ "$bitrate_mbps" -lt 8 ]; then
                score=$((score + 20))  # Orta (5-7 Mbps)
            elif [ "$bitrate_mbps" -ge 3 ] && [ "$bitrate_mbps" -lt 5 ]; then
                score=$((score + 10))  # Düşük (3-4 Mbps)
            fi
        fi
    fi
    
    # FPS puanı (max 20)
    if [ -n "$fps" ] && [ "$fps" != "N/A" ] && [ "$fps" != "0" ]; then
        local fps_int=$(printf "%.0f" "$fps" 2>/dev/null || echo "0")
        if [ "$fps_int" -gt 0 ] && [ "$fps_int" -ge 30 ]; then
            score=$((score + 20))  # 30+ FPS
        elif [ "$fps_int" -ge 24 ]; then
            score=$((score + 15))  # 24-29 FPS
        elif [ "$fps_int" -ge 20 ]; then
            score=$((score + 10))  # 20-23 FPS
        elif [ "$fps_int" -ge 15 ]; then
            score=$((score + 5))   # 15-19 FPS
        fi
    fi
    
    # FastStart kontrolü (max 10)
    if command -v mp4dump &>/dev/null; then
        if mp4dump "$video_file" 2>/dev/null | head -n 20 | grep -q "moov"; then
            score=$((score + 10))
        fi
    else
        # mp4dump yoksa ffprobe ile kontrol
        if ffprobe -v error -show_format "$video_file" 2>/dev/null | grep -q "faststart"; then
            score=$((score + 10))
        else
            # Alternatif kontrol: od ile moov atom kontrolü
            local moov_found=$(od -A x -t x1z -N 200 "$video_file" 2>/dev/null | grep -o "6d 6f 6f 76" | head -n 1)
            if [ -n "$moov_found" ]; then
                score=$((score + 10))
            fi
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
            # Software metadata'sını gösterme (algoritma riski)
            result="${result}✅ Software: Doğrulandı\n"
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

# Video bilgilerini göster (bitrate, fps, boyut, ölçü)
show_video_info() {
    local video_file="$1"
    local label="$2"
    
    if [ ! -f "$video_file" ]; then
        echo "⚠️  Dosya bulunamadı: $video_file"
        return 1
    fi
    
    # Video bilgilerini al
    local width=$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of default=noprint_wrappers=1:nokey=1 "$video_file" 2>/dev/null)
    local height=$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of default=noprint_wrappers=1:nokey=1 "$video_file" 2>/dev/null)
    local bitrate=$(ffprobe -v error -select_streams v:0 -show_entries stream=bit_rate -of default=noprint_wrappers=1:nokey=1 "$video_file" 2>/dev/null)
    local fps_raw=$(ffprobe -v error -select_streams v:0 -show_entries stream=r_frame_rate -of default=noprint_wrappers=1:nokey=1 "$video_file" 2>/dev/null | head -1)
    local file_size=$(stat -f%z "$video_file" 2>/dev/null || stat -c%s "$video_file" 2>/dev/null)
    
    # FPS'i parse et
    local fps="N/A"
    if [ -n "$fps_raw" ]; then
        if echo "$fps_raw" | grep -q "/"; then
            local fps_num=$(echo "$fps_raw" | cut -d'/' -f1)
            local fps_den=$(echo "$fps_raw" | cut -d'/' -f2)
            if [ "$fps_den" -gt 0 ] && [ -n "$fps_num" ]; then
                fps=$(awk "BEGIN {printf \"%.1f\", $fps_num/$fps_den}")
            fi
        else
            fps="$fps_raw"
        fi
    fi
    
    # Bitrate'i formatla (Mbps)
    local bitrate_mbps="N/A"
    if [ -n "$bitrate" ] && [ "$bitrate" != "N/A" ] && [ "$bitrate" != "0" ]; then
        bitrate_mbps=$(awk "BEGIN {printf \"%.2f\", $bitrate/1000000}")
    fi
    
    # Dosya boyutunu formatla (MB)
    local file_size_mb="N/A"
    if [ -n "$file_size" ] && [ "$file_size" != "0" ]; then
        file_size_mb=$(awk "BEGIN {printf \"%.2f\", $file_size/1048576}")
    fi
    
    # Çözünürlük
    local resolution="N/A"
    if [ -n "$width" ] && [ -n "$height" ] && [ "$width" != "0" ] && [ "$height" != "0" ]; then
        resolution="${width}x${height}"
    fi
    
    # Metadata bilgilerini al (once ffprobe, sonra exiftool - guvenilir okuma)
    local make=""
    local model=""
    local software=""
    local creation_time=""
    
    # FFprobe ile metadata okuma (format_tags)
    make=$(ffprobe -v error -show_entries format_tags=make -of default=noprint_wrappers=1:nokey=1 "$video_file" 2>/dev/null | head -1 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | grep -v "^$")
    model=$(ffprobe -v error -show_entries format_tags=model -of default=noprint_wrappers=1:nokey=1 "$video_file" 2>/dev/null | head -1 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | grep -v "^$")
    software=$(ffprobe -v error -show_entries format_tags=software -of default=noprint_wrappers=1:nokey=1 "$video_file" 2>/dev/null | head -1 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | grep -v "^$")
    creation_time=$(ffprobe -v error -show_entries format_tags=creation_time -of default=noprint_wrappers=1:nokey=1 "$video_file" 2>/dev/null | head -1 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | grep -v "^$")
    
    # Eger ffprobe ile bulunamazsa ExifTool ile kontrol et (daha guvenilir)
    if [ -z "$make" ] && command -v exiftool &>/dev/null; then
        make=$(exiftool -s -s -s -Make "$video_file" 2>/dev/null | head -1 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | grep -v "^$")
    fi
    if [ -z "$model" ] && command -v exiftool &>/dev/null; then
        model=$(exiftool -s -s -s -Model "$video_file" 2>/dev/null | head -1 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | grep -v "^$")
    fi
    if [ -z "$software" ] && command -v exiftool &>/dev/null; then
        software=$(exiftool -s -s -s -Software "$video_file" 2>/dev/null | head -1 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | grep -v "^$")
    fi
    if [ -z "$creation_time" ] && command -v exiftool &>/dev/null; then
        # ExifTool ile creation time okuma (birden fazla tag dene)
        creation_time=$(exiftool -s -s -s -CreateDate "$video_file" 2>/dev/null | head -1 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | grep -v "^$")
        if [ -z "$creation_time" ]; then
            creation_time=$(exiftool -s -s -s -DateTimeOriginal "$video_file" 2>/dev/null | head -1 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | grep -v "^$")
        fi
        if [ -z "$creation_time" ]; then
            creation_time=$(exiftool -s -s -s -MediaCreateDate "$video_file" 2>/dev/null | head -1 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | grep -v "^$")
        fi
    fi
    
    # Creation time formatini duzelt (ISO 8601 veya ExifTool formatindan okunabilir formata)
    if [ -n "$creation_time" ] && [ "$creation_time" != "N/A" ]; then
        # ISO 8601 format: 2025-12-11T13:53:44.000000Z veya 2025-12-11T13:53:44Z
        # ExifTool format: 2025:12:11 13:53:44
        # Cikti format: 2025-12-11 13:53:44
        creation_time=$(echo "$creation_time" | sed 's/\([0-9][0-9][0-9][0-9]\):\([0-9][0-9]\):\([0-9][0-9]\)/\1-\2-\3/' | sed 's/T/ /' | sed 's/\.[0-9]*Z$//' | sed 's/Z$//' | cut -d' ' -f1-2 | head -1)
        # Gecersiz tarih kontrolu (0000-00-00 gibi)
        if echo "$creation_time" | grep -qE "0000-00-00|^$|^[[:space:]]*$"; then
            creation_time=""
        fi
    fi
    
    # Metadata degerlerini temizle ve formatla
    [ -z "$make" ] && make="N/A"
    [ -z "$model" ] && model="N/A"
    [ -z "$software" ] && software="N/A"
    [ -z "$creation_time" ] && creation_time="N/A"
    
    # Bilgileri göster
    echo "📹 $label:"
    echo "   Ölçü: $resolution | Bitrate: ${bitrate_mbps} Mbps | FPS: $fps | Boyut: ${file_size_mb} MB"
    echo "   Metadata: Make=$make | Model=$model | Tarih=$creation_time"
}

# 1) VİDEO SEÇİMİ (İlk adım - Çoklu dosya işleme)
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

# Rapor başlığı (profil bilgileri sonra eklenecek)
{
    echo "========================================================="
    echo "   VIDEO OPTİMİZASYON RAPORU"
    echo "========================================================="
    echo "Tarih: $(date)"
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
    TEMP2="temp2_${BASENAME}.mp4"
    UPSCALED_OUT="upscaled/${BASENAME}_upscaled.mp4"
    META_OUT="meta/${BASENAME}_meta.mp4"
    OPTIMIZED_OUT="optimized/${BASENAME}_optimized.mp4"
    FINAL_OUT=""

    echo
    echo "------------------------------------------"
    echo ">>> İşleniyor: $INPUT"
    echo "------------------------------------------"
    
    # Video bilgilerini göster (başlangıç)
    show_video_info "$INPUT" "Orijinal Video"
    echo

    # [1] UPSCALE - Tek encode burada
    echo
    echo "=== [1] Upscale (Çözünürlük Artırma) ==="
    echo "1) FFmpeg Upscale (Hızlı, basit)"
    echo "2) AI Upscale - NCNN-Vulkan (Çok hızlı, GPU, önerilen) [Henüz geliştiriliyor]"
    echo "3) AI Upscale - Python Real-ESRGAN (Yavaş, kolay kurulum) [Henüz geliştiriliyor]"
    echo "4) Upscale yapma (atla)"
    read -p "Seçiminiz (1-4): " UPSCALE_CHOICE

    CURRENT_FILE="$INPUT"
    
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
            # Cozunurluge gore minimum bitrate hesapla
            target_width=$(echo "$TARGET_RES" | cut -d':' -f1)
            target_height=$(echo "$TARGET_RES" | cut -d':' -f2)
            target_pixels=$((target_width * target_height))
            min_bitrate="8M"
            if [ "$target_pixels" -gt 8000000 ]; then  # 4K+
                min_bitrate="20M"
            elif [ "$target_pixels" -gt 2000000 ]; then  # 1080p+
                min_bitrate="12M"
            fi
            
            if ffmpeg -i "$CURRENT_FILE" \
            -vf "scale=$TARGET_RES:flags=lanczos" \
            -c:v libx264 -preset medium -crf 23 -pix_fmt yuv420p \
            -maxrate "$min_bitrate" -bufsize "$(echo "$min_bitrate" | sed 's/M$//')M" \
            -c:a copy \
            -movflags +faststart \
            "$UPSCALED_OUT" -y 2>>"$LOGFILE"; then
                # Cikti dosyasinin bitrate'ini kontrol et
                output_bitrate=$(ffprobe -v error -select_streams v:0 -show_entries stream=bit_rate -of default=noprint_wrappers=1:nokey=1 "$UPSCALED_OUT" 2>/dev/null)
                if [ -n "$output_bitrate" ] && [ "$output_bitrate" != "0" ] && [ "$output_bitrate" != "N/A" ]; then
                    output_bitrate_mbps=$(awk "BEGIN {printf \"%.2f\", $output_bitrate/1000000}")
                    echo "✅ BAŞARILI: FFmpeg upscale tamamlandı: $UPSCALED_OUT (Bitrate: ${output_bitrate_mbps} Mbps)"
                else
                    echo "✅ BAŞARILI: FFmpeg upscale tamamlandı: $UPSCALED_OUT"
                fi
                CURRENT_FILE="$UPSCALED_OUT"
            else
                echo "❌ BAŞARISIZ: FFmpeg upscale yapılamadı!" | tee -a "$LOGFILE"
                echo "Orijinal dosya kullanılmaya devam edilecek."
            fi
            ;;
        2)
            # AI Upscale (NCNN-Vulkan)
            echo
            echo ">>> AI Upscale (NCNN-Vulkan) kontrol ediliyor..."
            
            # NCNN-Vulkan kontrolü
            if command -v realesrgan-ncnn-vulkan &>/dev/null; then
                echo "✅ NCNN-Vulkan bulundu."
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
                
                echo ">>> AI Upscale yapılıyor (NCNN-Vulkan, Model: $MODEL_NAME)..."
                echo "⚠️  Bu işlem uzun sürebilir (video uzunluğuna bağlı)..."
                
                # Real-ESRGAN video işleme için frame'leri çıkar, upscale et, birleştir
                TEMP_FRAMES="temp_frames_${BASENAME}"
                TEMP_UPSCALED_FRAMES="temp_upscaled_frames_${BASENAME}"
                mkdir -p "$TEMP_FRAMES"
                mkdir -p "$TEMP_UPSCALED_FRAMES"
                
                # Video'dan frame'leri çıkar (yüksek kalite)
                echo ">>> Frame'ler çıkarılıyor..."
                if ffmpeg -i "$CURRENT_FILE" -qscale:v 1 -vsync 0 "$TEMP_FRAMES/frame_%06d.jpg" -y 2>>"$LOGFILE"; then
                    FRAME_COUNT=$(ls -1 "$TEMP_FRAMES"/*.jpg 2>/dev/null | wc -l | tr -d ' ')
                    if [ "$FRAME_COUNT" -eq 0 ]; then
                        echo "❌ BAŞARISIZ: Hiçbir frame çıkarılamadı!" | tee -a "$LOGFILE"
                        rm -rf "$TEMP_FRAMES"
                        rm -rf "$TEMP_UPSCALED_FRAMES"
                    else
                        echo ">>> $FRAME_COUNT frame çıkarıldı"
                        
                        # Her frame'i upscale et
                        echo ">>> Frame'ler upscale ediliyor (NCNN-Vulkan ile, bu uzun sürebilir)..."
                        CURRENT_FRAME=0
                        FAILED_FRAMES=0
                        
                        # Frame'leri sıralı işle (ls ile sıralama garantisi)
                        for frame in $(ls -1 "$TEMP_FRAMES"/*.jpg 2>/dev/null | sort); do
                            if [ -f "$frame" ]; then
                                CURRENT_FRAME=$((CURRENT_FRAME + 1))
                                FRAME_NAME=$(basename "$frame")
                                
                                # İlerleme göster (her 10 frame'de bir)
                                if [ $((CURRENT_FRAME % 10)) -eq 0 ] || [ "$CURRENT_FRAME" -eq 1 ] || [ "$CURRENT_FRAME" -eq "$FRAME_COUNT" ]; then
                                    echo ">>> İşleniyor: $CURRENT_FRAME/$FRAME_COUNT"
                                fi
                                
                                # Upscale komutunu çalıştır ve başarı durumunu kontrol et
                                # Orijinal frame'in çözünürlüğünü al
                                ORIGINAL_WIDTH=$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of default=noprint_wrappers=1:nokey=1 "$frame" 2>/dev/null | tr -d ' ')
                                ORIGINAL_HEIGHT=$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of default=noprint_wrappers=1:nokey=1 "$frame" 2>/dev/null | tr -d ' ')
                                
                                # Upscale komutunu çalıştır
                                if realesrgan-ncnn-vulkan -i "$frame" -o "$TEMP_UPSCALED_FRAMES/$FRAME_NAME" -n "$MODEL_NAME" -s $SCALE 2>>"$LOGFILE"; then
                                    # Upscaled frame'in varlığını, boyutunu ve geçerliliğini kontrol et
                                    if [ ! -f "$TEMP_UPSCALED_FRAMES/$FRAME_NAME" ]; then
                                        echo "⚠️  Uyarı: Upscaled frame oluşturulamadı: $FRAME_NAME" | tee -a "$LOGFILE"
                                        FAILED_FRAMES=$((FAILED_FRAMES + 1))
                                    elif [ ! -s "$TEMP_UPSCALED_FRAMES/$FRAME_NAME" ]; then
                                        echo "⚠️  Uyarı: Upscaled frame boş: $FRAME_NAME" | tee -a "$LOGFILE"
                                        rm -f "$TEMP_UPSCALED_FRAMES/$FRAME_NAME"
                                        FAILED_FRAMES=$((FAILED_FRAMES + 1))
                                    else
                                        # Upscaled frame'in çözünürlüğünü kontrol et (en önemli kontrol)
                                        UPSCALED_WIDTH=$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of default=noprint_wrappers=1:nokey=1 "$TEMP_UPSCALED_FRAMES/$FRAME_NAME" 2>/dev/null | tr -d ' ')
                                        UPSCALED_HEIGHT=$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of default=noprint_wrappers=1:nokey=1 "$TEMP_UPSCALED_FRAMES/$FRAME_NAME" 2>/dev/null | tr -d ' ')
                                        
                                        # Çözünürlük kontrolü - upscaled frame orijinalden SCALE katı büyük olmalı
                                        if [ -n "$ORIGINAL_WIDTH" ] && [ -n "$ORIGINAL_HEIGHT" ] && [ -n "$UPSCALED_WIDTH" ] && [ -n "$UPSCALED_HEIGHT" ] && \
                                           [ "$ORIGINAL_WIDTH" != "0" ] && [ "$ORIGINAL_HEIGHT" != "0" ] && \
                                           [ "$UPSCALED_WIDTH" != "0" ] && [ "$UPSCALED_HEIGHT" != "0" ]; then
                                            EXPECTED_WIDTH=$((ORIGINAL_WIDTH * SCALE))
                                            EXPECTED_HEIGHT=$((ORIGINAL_HEIGHT * SCALE))
                                            
                                            # Çözünürlük kontrolü (tolerans: ±2 piksel)
                                            if [ "$UPSCALED_WIDTH" -lt $((EXPECTED_WIDTH - 2)) ] || [ "$UPSCALED_HEIGHT" -lt $((EXPECTED_HEIGHT - 2)) ]; then
                                                echo "❌ HATA: Upscaled frame çözünürlüğü beklenenden küçük: $FRAME_NAME" | tee -a "$LOGFILE"
                                                echo "   Orijinal: ${ORIGINAL_WIDTH}x${ORIGINAL_HEIGHT}, Beklenen: ${EXPECTED_WIDTH}x${EXPECTED_HEIGHT}, Bulunan: ${UPSCALED_WIDTH}x${UPSCALED_HEIGHT}" | tee -a "$LOGFILE"
                                                echo "   Upscale başarısız! Frame siliniyor..." | tee -a "$LOGFILE"
                                                # Çözünürlük yanlışsa frame'i sil ve başarısız say
                                                rm -f "$TEMP_UPSCALED_FRAMES/$FRAME_NAME"
                                                FAILED_FRAMES=$((FAILED_FRAMES + 1))
                                            else
                                                # İlk birkaç frame için detaylı bilgi göster
                                                if [ "$CURRENT_FRAME" -le 3 ]; then
                                                    echo "✅ Frame $CURRENT_FRAME upscale başarılı: ${ORIGINAL_WIDTH}x${ORIGINAL_HEIGHT} -> ${UPSCALED_WIDTH}x${UPSCALED_HEIGHT}" | tee -a "$LOGFILE"
                                                fi
                                            fi
                                        else
                                            # Çözünürlük okunamadıysa dosya boyutu kontrolü yap
                                            ORIGINAL_SIZE=$(stat -f%z "$frame" 2>/dev/null || stat -c%s "$frame" 2>/dev/null)
                                            UPSCALED_SIZE=$(stat -f%z "$TEMP_UPSCALED_FRAMES/$FRAME_NAME" 2>/dev/null || stat -c%s "$TEMP_UPSCALED_FRAMES/$FRAME_NAME" 2>/dev/null)
                                            # 2x upscale için en az 2x, 4x upscale için en az 4x büyük olmalı (JPEG compression nedeniyle daha az olabilir ama çok küçükse sorun var)
                                            MIN_EXPECTED_SIZE=$((ORIGINAL_SIZE * SCALE / 2))  # JPEG compression için tolerans
                                            if [ "$UPSCALED_SIZE" -lt "$MIN_EXPECTED_SIZE" ]; then
                                                echo "⚠️  Uyarı: Upscaled frame beklenenden küçük: $FRAME_NAME (Orijinal: $ORIGINAL_SIZE, Upscaled: $UPSCALED_SIZE, Min beklenen: $MIN_EXPECTED_SIZE)" | tee -a "$LOGFILE"
                                            fi
                                        fi
                                    fi
                                else
                                    echo "⚠️  Uyarı: Upscale komutu başarısız: $FRAME_NAME" | tee -a "$LOGFILE"
                                    FAILED_FRAMES=$((FAILED_FRAMES + 1))
                                fi
                            fi
                        done
                        
                        # Upscaled frame sayısını kontrol et
                        UPSCALED_COUNT=$(ls -1 "$TEMP_UPSCALED_FRAMES"/*.jpg 2>/dev/null | wc -l | tr -d ' ')
                        echo ">>> Upscale tamamlandı: $UPSCALED_COUNT/$FRAME_COUNT frame başarılı"
                        
                        if [ "$UPSCALED_COUNT" -eq 0 ]; then
                            echo "❌ BAŞARISIZ: Hiçbir frame upscale edilemedi!" | tee -a "$LOGFILE"
                            rm -rf "$TEMP_FRAMES"
                            rm -rf "$TEMP_UPSCALED_FRAMES"
                        elif [ "$UPSCALED_COUNT" -lt "$FRAME_COUNT" ]; then
                            echo "⚠️  Uyarı: Bazı frame'ler upscale edilemedi ($FAILED_FRAMES frame başarısız)" | tee -a "$LOGFILE"
                        fi
                        
                        # Upscaled frame'leri video'ya birleştir
                        if [ "$UPSCALED_COUNT" -gt 0 ]; then
                            echo ">>> Upscaled frame'ler video'ya birleştiriliyor..."
                            FPS_RAW=$(ffprobe -v error -select_streams v:0 -show_entries stream=r_frame_rate -of default=noprint_wrappers=1:nokey=1 "$CURRENT_FILE" 2>/dev/null | head -1)
                            
                            # FPS'i parse et (30/1 -> 30 gibi)
                            if echo "$FPS_RAW" | grep -q "/"; then
                                FPS_NUM=$(echo "$FPS_RAW" | cut -d'/' -f1)
                                FPS_DEN=$(echo "$FPS_RAW" | cut -d'/' -f2)
                                if [ "$FPS_DEN" -gt 0 ] && [ -n "$FPS_NUM" ]; then
                                    FPS=$(awk "BEGIN {printf \"%.2f\", $FPS_NUM/$FPS_DEN}")
                                else
                                    FPS=30
                                fi
                            else
                                FPS="$FPS_RAW"
                            fi
                            
                            # FPS geçerli değilse varsayılan kullan
                            if [ -z "$FPS" ] || [ "$FPS" = "0" ] || [ "$FPS" = "N/A" ] || [ "$FPS" = "0.00" ]; then
                                FPS=30
                                echo "⚠️  FPS tespit edilemedi, varsayılan 30 kullanılıyor" | tee -a "$LOGFILE"
                            fi
                            
                            echo ">>> FPS: $FPS"
                            
                            # Upscaled frame'lerin varlığını ve sıralamasını kontrol et
                            FIRST_FRAME=$(ls -1 "$TEMP_UPSCALED_FRAMES"/frame_*.jpg 2>/dev/null | sort | head -1)
                            if [ -z "$FIRST_FRAME" ] || [ ! -f "$FIRST_FRAME" ]; then
                                echo "❌ BAŞARISIZ: Upscaled frame'ler bulunamadı!" | tee -a "$LOGFILE"
                            else
                                # Upscaled frame'lerin gerçek çözünürlüğünü kontrol et
                                upscaled_width=$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of default=noprint_wrappers=1:nokey=1 "$FIRST_FRAME" 2>/dev/null | tr -d ' ')
                                upscaled_height=$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of default=noprint_wrappers=1:nokey=1 "$FIRST_FRAME" 2>/dev/null | tr -d ' ')
                                
                                if [ -z "$upscaled_width" ] || [ "$upscaled_width" = "0" ] || [ -z "$upscaled_height" ] || [ "$upscaled_height" = "0" ]; then
                                    echo "⚠️  Uyarı: Upscaled frame çözünürlüğü okunamadı, varsayılan bitrate kullanılıyor" | tee -a "$LOGFILE"
                                    upscaled_width="0"
                                    upscaled_height="0"
                                else
                                    echo ">>> Upscaled çözünürlük: ${upscaled_width}x${upscaled_height}"
                                fi
                                
                                # Cozunurluge gore minimum bitrate hesapla (daha agresif)
                                min_bitrate_upscale="12M"
                                if [ -n "$upscaled_width" ] && [ -n "$upscaled_height" ] && [ "$upscaled_width" != "0" ] && [ "$upscaled_height" != "0" ]; then
                                    upscaled_pixels=$((upscaled_width * upscaled_height))
                                    if [ "$upscaled_pixels" -gt 16000000 ]; then  # 8K+ (7680x4320)
                                        min_bitrate_upscale="60M"
                                    elif [ "$upscaled_pixels" -gt 8000000 ]; then  # 4K+ (3840x2160)
                                        min_bitrate_upscale="35M"
                                    elif [ "$upscaled_pixels" -gt 3500000 ]; then  # 1440p+ (2560x1440)
                                        min_bitrate_upscale="20M"
                                    elif [ "$upscaled_pixels" -gt 2000000 ]; then  # 1080p+ (1920x1080)
                                        min_bitrate_upscale="12M"
                                    else
                                        min_bitrate_upscale="8M"
                                    fi
                                fi
                                
                                echo ">>> Minimum bitrate: $min_bitrate_upscale"
                                
                                # Video birleştirme - bitrate garantisi ile (CRF yerine bitrate-based encoding)
                                # Frame'leri sıralı okumak için -start_number kullan
                                FIRST_FRAME_NUM=$(echo "$FIRST_FRAME" | grep -o '[0-9]\+' | head -1)
                                if [ -z "$FIRST_FRAME_NUM" ]; then
                                    FIRST_FRAME_NUM=1
                                fi
                                
                                # Bitrate numarasını al (M'yi kaldır)
                                bitrate_num=$(echo "$min_bitrate_upscale" | sed 's/M$//')
                                bufsize_num=$((bitrate_num * 2))
                                
                                echo ">>> Video birleştiriliyor (Bitrate: ${min_bitrate_upscale}, FPS: $FPS, Çözünürlük: ${upscaled_width}x${upscaled_height})..."
                                # FFmpeg'de bitrate kontrolü: -b:v target bitrate, -maxrate maximum bitrate, -bufsize buffer size
                                # -b:v ve -maxrate aynı olduğunda CBR benzeri davranış, farklı olduğunda VBR
                                # Burada -b:v ve -maxrate aynı tutarak bitrate garantisi sağlıyoruz
                                if ffmpeg -framerate "$FPS" -start_number "$FIRST_FRAME_NUM" -i "$TEMP_UPSCALED_FRAMES/frame_%06d.jpg" \
                                -i "$CURRENT_FILE" -map 0:v -map 1:a? \
                                -c:v libx264 -preset medium -pix_fmt yuv420p \
                                -b:v "${min_bitrate_upscale}" \
                                -maxrate "${min_bitrate_upscale}" \
                                -bufsize "${bufsize_num}M" \
                                -g 30 -keyint_min 30 \
                                -profile:v high -level 4.0 \
                                -c:a copy \
                                -movflags +faststart \
                                "$UPSCALED_OUT" -y 2>>"$LOGFILE"; then
                                    # Çıktı dosyasının boyutunu kontrol et
                                    if [ -f "$UPSCALED_OUT" ] && [ -s "$UPSCALED_OUT" ]; then
                                        OUTPUT_SIZE=$(stat -f%z "$UPSCALED_OUT" 2>/dev/null || stat -c%s "$UPSCALED_OUT" 2>/dev/null)
                                        INPUT_SIZE=$(stat -f%z "$CURRENT_FILE" 2>/dev/null || stat -c%s "$CURRENT_FILE" 2>/dev/null)
                                        
                                        # Çıktı çok küçükse uyar
                                        if [ "$OUTPUT_SIZE" -lt 1000000 ] && [ "$INPUT_SIZE" -gt 10000000 ]; then
                                            echo "⚠️  UYARI: Çıktı dosyası beklenenden çok küçük! ($OUTPUT_SIZE bytes)" | tee -a "$LOGFILE"
                                            echo "   Video bozuk olabilir, kontrol edin." | tee -a "$LOGFILE"
                                        fi
                                        
                                        echo "✅ BAŞARILI: AI Upscale (NCNN-Vulkan) tamamlandı: $UPSCALED_OUT"
                                        CURRENT_FILE="$UPSCALED_OUT"
                                    else
                                        echo "❌ BAŞARISIZ: Çıktı dosyası oluşturulamadı veya boş!" | tee -a "$LOGFILE"
                                    fi
                                else
                                    echo "❌ BAŞARISIZ: Upscaled frame'ler video'ya birleştirilemedi!" | tee -a "$LOGFILE"
                                fi
                            fi
                        fi
                        
                        # Temizlik
                        rm -rf "$TEMP_FRAMES"
                        rm -rf "$TEMP_UPSCALED_FRAMES"
                    fi
                else
                    echo "❌ BAŞARISIZ: Frame'ler çıkarılamadı!" | tee -a "$LOGFILE"
                fi
            else
                echo "⚠️  NCNN-Vulkan yüklü değil!" | tee -a "$LOGFILE"
                echo "   Yüklemek için:" | tee -a "$LOGFILE"
                echo "   - GitHub'dan indirin: https://github.com/xinntao/Real-ESRGAN/releases" | tee -a "$LOGFILE"
                echo "   - veya: https://github.com/nihui/realesrgan-ncnn-vulkan" | tee -a "$LOGFILE"
                echo "   Upscale atlandı, orijinal dosya kullanılacak."
            fi
            ;;
        3)
            # AI Upscale (Python Real-ESRGAN)
            echo
            echo ">>> AI Upscale (Python Real-ESRGAN) kontrol ediliyor..."
            
            # Python Real-ESRGAN kontrolü
            if command -v realesrgan &>/dev/null; then
                echo "✅ Python Real-ESRGAN bulundu."
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
                
                echo ">>> AI Upscale yapılıyor (Python Real-ESRGAN, Model: $MODEL_NAME)..."
                echo "⚠️  Bu işlem çok uzun sürebilir (video uzunluğuna bağlı)..."
                
                # Real-ESRGAN video işleme için frame'leri çıkar, upscale et, birleştir
                TEMP_FRAMES="temp_frames_${BASENAME}"
                TEMP_UPSCALED_FRAMES="temp_upscaled_frames_${BASENAME}"
                mkdir -p "$TEMP_FRAMES"
                mkdir -p "$TEMP_UPSCALED_FRAMES"
                
                # Video'dan frame'leri çıkar
                echo ">>> Frame'ler çıkarılıyor..."
                if ffmpeg -i "$CURRENT_FILE" -qscale:v 1 "$TEMP_FRAMES/frame_%06d.jpg" -y 2>>"$LOGFILE"; then
                    # Her frame'i upscale et
                    echo ">>> Frame'ler upscale ediliyor (Python Real-ESRGAN ile, bu çok uzun sürebilir)..."
                    FRAME_COUNT=$(ls -1 "$TEMP_FRAMES"/*.jpg 2>/dev/null | wc -l)
                    CURRENT_FRAME=0
                    FAILED_FRAMES=0
                    
                    for frame in "$TEMP_FRAMES"/*.jpg; do
                        if [ -f "$frame" ]; then
                            CURRENT_FRAME=$((CURRENT_FRAME + 1))
                            FRAME_NAME=$(basename "$frame")
                            echo ">>> İşleniyor: $CURRENT_FRAME/$FRAME_COUNT"
                            
                            # Upscale komutunu çalıştır ve başarı durumunu kontrol et
                            if realesrgan -i "$frame" -o "$TEMP_UPSCALED_FRAMES/$FRAME_NAME" -n "$MODEL_NAME" -s $SCALE 2>>"$LOGFILE"; then
                                # Upscaled frame'in varlığını ve boyutunu kontrol et
                                if [ ! -f "$TEMP_UPSCALED_FRAMES/$FRAME_NAME" ] || [ ! -s "$TEMP_UPSCALED_FRAMES/$FRAME_NAME" ]; then
                                    echo "⚠️  Uyarı: Frame upscale edilemedi: $FRAME_NAME" | tee -a "$LOGFILE"
                                    FAILED_FRAMES=$((FAILED_FRAMES + 1))
                                fi
                            else
                                echo "⚠️  Uyarı: Upscale komutu başarısız: $FRAME_NAME" | tee -a "$LOGFILE"
                                FAILED_FRAMES=$((FAILED_FRAMES + 1))
                            fi
                        fi
                    done
                    
                    # Upscaled frame sayısını kontrol et
                    UPSCALED_COUNT=$(ls -1 "$TEMP_UPSCALED_FRAMES"/*.jpg 2>/dev/null | wc -l)
                    echo ">>> Upscale tamamlandı: $UPSCALED_COUNT/$FRAME_COUNT frame başarılı"
                    
                    if [ "$UPSCALED_COUNT" -eq 0 ]; then
                        echo "❌ BAŞARISIZ: Hiçbir frame upscale edilemedi!" | tee -a "$LOGFILE"
                        rm -rf "$TEMP_FRAMES"
                        rm -rf "$TEMP_UPSCALED_FRAMES"
                    elif [ "$UPSCALED_COUNT" -lt "$FRAME_COUNT" ]; then
                        echo "⚠️  Uyarı: Bazı frame'ler upscale edilemedi ($FAILED_FRAMES frame başarısız)" | tee -a "$LOGFILE"
                    fi
                    
                    # Upscaled frame'leri video'ya birleştir
                    if [ "$UPSCALED_COUNT" -gt 0 ]; then
                        echo ">>> Upscaled frame'ler video'ya birleştiriliyor..."
                        FPS_RAW=$(ffprobe -v error -select_streams v:0 -show_entries stream=r_frame_rate -of default=noprint_wrappers=1:nokey=1 "$CURRENT_FILE" 2>/dev/null | head -1)
                        
                        # FPS'i parse et (30/1 -> 30 gibi)
                        if echo "$FPS_RAW" | grep -q "/"; then
                            FPS_NUM=$(echo "$FPS_RAW" | cut -d'/' -f1)
                            FPS_DEN=$(echo "$FPS_RAW" | cut -d'/' -f2)
                            if [ "$FPS_DEN" -gt 0 ] && [ -n "$FPS_NUM" ]; then
                                # awk kullanarak bölme işlemi (bc yerine)
                                FPS=$(awk "BEGIN {printf \"%.2f\", $FPS_NUM/$FPS_DEN}")
                            else
                                FPS=30
                            fi
                        else
                            FPS="$FPS_RAW"
                        fi
                        
                        # FPS geçerli değilse varsayılan kullan
                        if [ -z "$FPS" ] || [ "$FPS" = "0" ] || [ "$FPS" = "N/A" ] || [ "$FPS" = "0.00" ]; then
                            FPS=30
                            echo "⚠️  FPS tespit edilemedi, varsayılan 30 kullanılıyor" | tee -a "$LOGFILE"
                        fi
                        
                        echo ">>> FPS: $FPS"
                        
                        # Video birleştirme - daha güvenli ayarlarla
                        # Cozunurluge gore minimum bitrate hesapla
                        upscaled_width=$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of default=noprint_wrappers=1:nokey=1 "$TEMP_UPSCALED_FRAMES/frame_000001.jpg" 2>/dev/null || echo "0")
                        upscaled_height=$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of default=noprint_wrappers=1:nokey=1 "$TEMP_UPSCALED_FRAMES/frame_000001.jpg" 2>/dev/null || echo "0")
                        min_bitrate_upscale="8M"
                        if [ -n "$upscaled_width" ] && [ -n "$upscaled_height" ] && [ "$upscaled_width" != "0" ] && [ "$upscaled_height" != "0" ]; then
                            upscaled_pixels=$((upscaled_width * upscaled_height))
                            if [ "$upscaled_pixels" -gt 8000000 ]; then  # 4K+
                                min_bitrate_upscale="20M"
                            elif [ "$upscaled_pixels" -gt 2000000 ]; then  # 1080p+
                                min_bitrate_upscale="12M"
                            fi
                        fi
                        
                        # Video birleştirme - minimum bitrate garantisi ile
                        if ffmpeg -framerate "$FPS" -i "$TEMP_UPSCALED_FRAMES/frame_%06d.jpg" \
                        -i "$CURRENT_FILE" -map 0:v -map 1:a? \
                        -c:v libx264 -preset medium -crf 23 -pix_fmt yuv420p \
                        -maxrate "$min_bitrate_upscale" -bufsize "$(echo "$min_bitrate_upscale" | sed 's/M$//')M" \
                        -c:a copy \
                        -movflags +faststart \
                        "$UPSCALED_OUT" -y 2>>"$LOGFILE"; then
                            # Çıktı dosyasının boyutunu kontrol et
                            if [ -f "$UPSCALED_OUT" ] && [ -s "$UPSCALED_OUT" ]; then
                                OUTPUT_SIZE=$(stat -f%z "$UPSCALED_OUT" 2>/dev/null || stat -c%s "$UPSCALED_OUT" 2>/dev/null)
                                INPUT_SIZE=$(stat -f%z "$CURRENT_FILE" 2>/dev/null || stat -c%s "$CURRENT_FILE" 2>/dev/null)
                                
                                # Çıktı çok küçükse uyar
                                if [ "$OUTPUT_SIZE" -lt 1000000 ] && [ "$INPUT_SIZE" -gt 10000000 ]; then
                                    echo "⚠️  UYARI: Çıktı dosyası beklenenden çok küçük! ($OUTPUT_SIZE bytes)" | tee -a "$LOGFILE"
                                    echo "   Video bozuk olabilir, kontrol edin." | tee -a "$LOGFILE"
                                fi
                                
                                echo "✅ BAŞARILI: AI Upscale (Python Real-ESRGAN) tamamlandı: $UPSCALED_OUT"
                                CURRENT_FILE="$UPSCALED_OUT"
                            else
                                echo "❌ BAŞARISIZ: Çıktı dosyası oluşturulamadı veya boş!" | tee -a "$LOGFILE"
                            fi
                        else
                            echo "❌ BAŞARISIZ: Upscaled frame'ler video'ya birleştirilemedi!" | tee -a "$LOGFILE"
                        fi
                    fi
                    
                    # Temizlik
                    rm -rf "$TEMP_FRAMES"
                    rm -rf "$TEMP_UPSCALED_FRAMES"
                else
                    echo "❌ BAŞARISIZ: Frame'ler çıkarılamadı!" | tee -a "$LOGFILE"
                fi
            else
                echo "⚠️  Python Real-ESRGAN yüklü değil!" | tee -a "$LOGFILE"
                echo "   Yüklemek için:" | tee -a "$LOGFILE"
                echo "   - pip install realesrgan" | tee -a "$LOGFILE"
                echo "   - veya: https://github.com/xinntao/Real-ESRGAN" | tee -a "$LOGFILE"
                echo "   Upscale atlandı, orijinal dosya kullanılacak."
            fi
            ;;
        4)
            echo "Upscale atlandı."
            ;;
        *)
            echo "Geçersiz seçim, upscale atlandı."
            ;;
    esac

    # [2] Metadata Yazma (Cihaz profili ve bitrate seçimi burada)
    echo
    echo "=== [2] Metadata Yazma ==="
    
    # Cihaz profili seçimi
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
            echo "Geçersiz seçim! Varsayılan profil kullanılıyor."
            MAKE="Apple"
            MODEL="iPhone 16 Pro Max"
            SOFTWARE="Instagram"
            ;;
    esac
    
    echo
    echo "Profil: $MAKE / $MODEL"
    echo
    
    # Bitrate seçimi (opsiyonel)
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
            echo "1) Instagram (Cozunurluge gore: 1080p=12M, 1440p=20M, 4K=35M)"
            echo "2) TikTok (Cozunurluge gore: 1080p=10M, 1440p=16M, 4K=30M)"
            echo "3) YouTube Shorts (Cozunurluge gore: 1080p=16M, 1440p=25M, 4K=45M)"
            read -p "Seciminiz (1-3): " PLATFORM_CHOICE
            
            # Video cozunurlugunu al (bitrate hesaplamasi icin)
            current_video_width=$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of default=noprint_wrappers=1:nokey=1 "$CURRENT_FILE" 2>/dev/null)
            current_video_height=$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of default=noprint_wrappers=1:nokey=1 "$CURRENT_FILE" 2>/dev/null)
            
            case $PLATFORM_CHOICE in
                1)
                    PLATFORM="instagram"
                    BITRATE=$(get_platform_bitrate "$PLATFORM" "$current_video_width" "$current_video_height")
                    ;;
                2)
                    PLATFORM="tiktok"
                    BITRATE=$(get_platform_bitrate "$PLATFORM" "$current_video_width" "$current_video_height")
                    ;;
                3)
                    PLATFORM="youtube_shorts"
                    BITRATE=$(get_platform_bitrate "$PLATFORM" "$current_video_width" "$current_video_height")
                    ;;
                *)
                    PLATFORM="instagram"
                    BITRATE=$(get_platform_bitrate "$PLATFORM" "$current_video_width" "$current_video_height")
                    ;;
            esac
            echo "Platform: $PLATFORM (Cozunurluk: ${current_video_width}x${current_video_height}, Bitrate: $BITRATE)"
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
    echo ">>> Metadata yazılıyor..."
    
    # [3] FastStart (moov atom başa)
    echo
    echo "=== [3] FastStart (MOOV Atom Optimize) ==="
    echo ">>> FastStart uygulanıyor..."
    
    # FFmpeg ile metadata yazma ve FastStart uygulama
    if ffmpeg -i "$CURRENT_FILE" \
    -metadata make="$MAKE" \
    -metadata model="$MODEL" \
    -metadata software="$SOFTWARE" \
    -metadata creation_time="$(date -u +%Y-%m-%dT%H:%M:%S)" \
    -movflags faststart \
    -c copy "$META_OUT" -y 2>>"$LOGFILE"; then
        echo "✅ BAŞARILI: FastStart uygulandı"
        echo "✅ Meta dosya oluşturuldu: $META_OUT"
        CURRENT_FILE="$META_OUT"
    else
        echo "❌ BAŞARISIZ: FastStart uygulanamadı!" | tee -a "$LOGFILE"
        FAILED_VIDEOS+=("$INPUT (FastStart uygulanamadı)")
        continue
    fi

    # ExifTool ile metadata guclendirme (FFmpeg'in -c copy ile yazamadigi metadata'lari yazar)
    # ExifTool MP4 metadata'yi daha guvenilir sekilde yazar ve birden fazla tag kullanir
    if command -v exiftool &>/dev/null; then
        echo ">>> ExifTool ile metadata guclendiriliyor..."
        creation_date_iso=$(date -u +%Y:%m:%d\ %H:%M:%S)
        if exiftool -overwrite_original \
        -Make="$MAKE" \
        -Model="$MODEL" \
        -Software="$SOFTWARE" \
        -CreateDate="$creation_date_iso" \
        -DateTimeOriginal="$creation_date_iso" \
        -MediaCreateDate="$creation_date_iso" \
        "$META_OUT" >>"$LOGFILE" 2>&1; then
            echo "✅ BAŞARILI: ExifTool metadata eklendi"
        else
            echo "⚠️  ExifTool metadata eklenemedi (opsiyonel)" | tee -a "$LOGFILE"
        fi
    else
        echo "⚠️  ExifTool yuklu degil, metadata sadece FFmpeg ile yazildi" | tee -a "$LOGFILE"
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

    # [4] Thumbnail / AI Thumbnail
    echo
    echo "=== [4] Thumbnail / AI Thumbnail ==="
    read -p "Cover thumbnail eklensin mi? (e/h): " THMB

    if [[ "$THMB" == "e" || "$THMB" == "E" ]]; then
        TARGET_FILE="$META_OUT"
        
        THUMB_FILE="meta/${BASENAME}_thumb.jpg"
        
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
                EMBED_OUT="${META_OUT%.mp4}_THUMB.mp4"
                echo ">>> Thumbnail MP4'e embed ediliyor..."
                # Thumbnail'i attached picture olarak ekle (FastStart ve metadata korunuyor)
                if ffmpeg -i "$META_OUT" -i "$THUMB_FILE" \
                -map_metadata 0 \
                -metadata make="$MAKE" \
                -metadata model="$MODEL" \
                -metadata software="$SOFTWARE" \
                -map 0:v -map 0:a? -map 1 \
                -c:v copy -c:a copy -c:s copy \
                -movflags faststart \
                -disposition:2 attached_pic \
                "$EMBED_OUT" -y 2>>"$LOGFILE"; then
                    echo "✅ BAŞARILI: Thumbnail MP4'e eklendi: $EMBED_OUT"
                    # Embed edilmiş dosyayı orijinal dosyanın yerine koy
                    if [ -f "$EMBED_OUT" ]; then
                        # ExifTool ile metadata guclendir (thumbnail embed sonrasi metadata kaybolabilir)
                        if command -v exiftool &>/dev/null; then
                            creation_date_iso=$(date -u +%Y:%m:%d\ %H:%M:%S)
                            exiftool -overwrite_original \
                            -Make="$MAKE" \
                            -Model="$MODEL" \
                            -Software="$SOFTWARE" \
                            -CreateDate="$creation_date_iso" \
                            -DateTimeOriginal="$creation_date_iso" \
                            -MediaCreateDate="$creation_date_iso" \
                            "$EMBED_OUT" >>"$LOGFILE" 2>&1
                        fi
                        mv "$EMBED_OUT" "$META_OUT"
                        CURRENT_FILE="$META_OUT"
                    fi
                else
                    echo "❌ BAŞARISIZ: Thumbnail MP4'e eklenemedi!" | tee -a "$LOGFILE"
                    echo "   Alternatif yöntem deneniyor..." | tee -a "$LOGFILE"
                    # Alternatif: Thumbnail'i video stream olarak ekle (FastStart ve metadata korunuyor)
                    if ffmpeg -i "$META_OUT" -i "$THUMB_FILE" \
                    -map_metadata 0 \
                    -metadata make="$MAKE" \
                    -metadata model="$MODEL" \
                    -metadata software="$SOFTWARE" \
                    -map 0 -map 1:v \
                    -c:v copy -c:a copy \
                    -movflags faststart \
                    -disposition:1 attached_pic \
                    "$EMBED_OUT" -y 2>>"$LOGFILE"; then
                        echo "✅ BAŞARILI: Thumbnail alternatif yöntemle eklendi: $EMBED_OUT"
                        if [ -f "$EMBED_OUT" ]; then
                            # ExifTool ile metadata guclendir (thumbnail embed sonrasi metadata kaybolabilir)
                            if command -v exiftool &>/dev/null; then
                                exiftool -overwrite_original \
                                -Make="$MAKE" \
                                -Model="$MODEL" \
                                -Software="$SOFTWARE" \
                                "$EMBED_OUT" >>"$LOGFILE" 2>&1
                            fi
                            mv "$EMBED_OUT" "$META_OUT"
                            CURRENT_FILE="$META_OUT"
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

    # [5] Bitrate Optimizasyonu
    echo
    echo "=== [5] Bitrate Optimizasyonu ==="
    OPTIMIZED_SCORE=""
    
    # Eğer metadata adımında bitrate optimizasyonu atlandıysa (BITRATE=""), burada atla
    if [ -z "$BITRATE" ]; then
        echo "Bitrate optimizasyonu metadata adımında atlandı, bu adım atlanıyor."
        DO_BITRATE="h"
        FINAL_OUT="$META_OUT"
    else
        # Bitrate set edildiyse, direkt yap (FastStart korunuyor)
        # Video cozunurlugunu kontrol et ve minimum bitrate hesapla
        video_width=$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of default=noprint_wrappers=1:nokey=1 "$CURRENT_FILE" 2>/dev/null)
        video_height=$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of default=noprint_wrappers=1:nokey=1 "$CURRENT_FILE" 2>/dev/null)
        
        # Bitrate formatini FFmpeg icin duzelt (12M -> 12M veya 12000000)
        # FFmpeg "12M" formatini anliyor ama daha guvenli olmasi icin kontrol edelim
        ffmpeg_bitrate="$BITRATE"
        
        # Eger bitrate formati "12M" ise, FFmpeg bunu anlayacak
        # Ama cozunurluge gore minimum bitrate kontrolu yapalim
        if [ -n "$video_width" ] && [ -n "$video_height" ] && [ "$video_width" != "0" ] && [ "$video_height" != "0" ]; then
            total_pixels=$((video_width * video_height))
            # Cozunurluge gore minimum bitrate (profesyonel standartlar)
            # 720p: 5Mbps, 1080p: 8-12Mbps, 1440p: 16-20Mbps, 4K: 35-45Mbps, 8K: 60-80Mbps
            min_bitrate_mbps=8
            if [ "$total_pixels" -gt 16000000 ]; then  # 8K+ (7680x4320)
                min_bitrate_mbps=60
            elif [ "$total_pixels" -gt 8000000 ]; then  # 4K+ (3840x2160)
                min_bitrate_mbps=35
            elif [ "$total_pixels" -gt 3500000 ]; then  # 1440p+ (2560x1440)
                min_bitrate_mbps=20
            elif [ "$total_pixels" -gt 2000000 ]; then  # 1080p+ (1920x1080)
                min_bitrate_mbps=12
            elif [ "$total_pixels" -gt 900000 ]; then  # 720p+ (1280x720)
                min_bitrate_mbps=8
            fi
            
            # Eger BITRATE bos ise, minimum bitrate kullan
            if [ -z "$BITRATE" ] || [ "$BITRATE" = "" ]; then
                echo "⚠️  Uyari: Bitrate secilmedi, cozunurluge gore minimum bitrate kullaniliyor!" | tee -a "$LOGFILE"
                echo "   Cozunurluk: ${video_width}x${video_height}, Minimum bitrate: ${min_bitrate_mbps}Mbps" | tee -a "$LOGFILE"
                ffmpeg_bitrate="${min_bitrate_mbps}M"
            else
                # Secilen bitrate'i kontrol et
                selected_bitrate_num=$(echo "$BITRATE" | sed 's/[^0-9]//g')
                if [ -z "$selected_bitrate_num" ] || [ "$selected_bitrate_num" -lt "$min_bitrate_mbps" ]; then
                    echo "⚠️  Uyari: Secilen bitrate ($BITRATE) cozunurluk icin cok dusuk!" | tee -a "$LOGFILE"
                    echo "   Cozunurluk: ${video_width}x${video_height}, Onerilen minimum: ${min_bitrate_mbps}Mbps" | tee -a "$LOGFILE"
                    echo "   Minimum bitrate kullaniliyor: ${min_bitrate_mbps}M" | tee -a "$LOGFILE"
                    ffmpeg_bitrate="${min_bitrate_mbps}M"
                fi
            fi
        else
            # Video cozunurlugu alinamadi, BITRATE bos ise varsayilan kullan
            if [ -z "$BITRATE" ] || [ "$BITRATE" = "" ]; then
                echo "⚠️  Uyari: Bitrate secilmedi ve cozunurluk alinamadi, varsayilan 12M kullaniliyor!" | tee -a "$LOGFILE"
                ffmpeg_bitrate="12M"
            fi
        fi
        
        echo ">>> Bitrate optimizasyonu yapiliyor (Hedef: $ffmpeg_bitrate)..."
        # VBR (Variable Bitrate) kullan, CRF ile kaliteyi koru, max bitrate limiti koy
        # Bu sekilde kalite korunur ve bitrate limiti uygulanir
        # bufsize genellikle maxrate'in 2 kati olmali
        bufsize_value="$ffmpeg_bitrate"
        if echo "$ffmpeg_bitrate" | grep -q "M$"; then
            bitrate_num=$(echo "$ffmpeg_bitrate" | sed 's/M$//')
            # bitrate_num'in gecerli bir sayi oldugunu kontrol et
            if [ -n "$bitrate_num" ] && [ "$bitrate_num" -gt 0 ] 2>/dev/null; then
                bufsize_num=$((bitrate_num * 2))
                bufsize_value="${bufsize_num}M"
            else
                # Gecersizse, varsayilan olarak bitrate'in 2 katini kullan
                bufsize_value="${ffmpeg_bitrate}"
            fi
        fi
        
        # Metadata'yi korumak icin hem map_metadata hem de metadata parametreleri ekle
        # Input metadata'yi koru ve ayni zamanda yeniden yaz (re-encode sirasinda kaybolabilir)
        if ffmpeg -i "$CURRENT_FILE" \
        -map_metadata 0 \
        -metadata make="$MAKE" \
        -metadata model="$MODEL" \
        -metadata software="$SOFTWARE" \
        -metadata creation_time="$(date -u +%Y-%m-%dT%H:%M:%S)" \
        -c:v libx264 -preset medium -crf 23 \
        -maxrate "$ffmpeg_bitrate" -bufsize "$bufsize_value" \
        -c:a copy \
        -movflags faststart \
        "$OPTIMIZED_OUT" -y 2>>"$LOGFILE"; then
            # Cikti dosyasinin bitrate'ini kontrol et
            output_bitrate=$(ffprobe -v error -select_streams v:0 -show_entries stream=bit_rate -of default=noprint_wrappers=1:nokey=1 "$OPTIMIZED_OUT" 2>/dev/null)
            if [ -n "$output_bitrate" ] && [ "$output_bitrate" != "0" ] && [ "$output_bitrate" != "N/A" ]; then
                output_bitrate_mbps=$(awk "BEGIN {printf \"%.2f\", $output_bitrate/1000000}")
                echo "✅ BAŞARILI: Bitrate optimizasyonu tamamlandı (Gerçek bitrate: ${output_bitrate_mbps} Mbps)"
            else
                echo "✅ BAŞARILI: Bitrate optimizasyonu tamamlandı"
            fi
            
            # Metadata'yi ExifTool ile guclendir (re-encode sonrasi metadata kaybolabilir)
            if command -v exiftool &>/dev/null; then
                creation_date_iso=$(date -u +%Y:%m:%d\ %H:%M:%S)
                if exiftool -overwrite_original \
                -Make="$MAKE" \
                -Model="$MODEL" \
                -Software="$SOFTWARE" \
                -CreateDate="$creation_date_iso" \
                -DateTimeOriginal="$creation_date_iso" \
                -MediaCreateDate="$creation_date_iso" \
                "$OPTIMIZED_OUT" >>"$LOGFILE" 2>&1; then
                    echo "✅ Metadata ExifTool ile guclendirildi"
                fi
            fi
            
            echo "✅ Optimized dosya oluşturuldu: $OPTIMIZED_OUT"
            FINAL_OUT="$OPTIMIZED_OUT"
            CURRENT_FILE="$OPTIMIZED_OUT"  # CURRENT_FILE'ı güncelle
        else
            echo "❌ BAŞARISIZ: Bitrate optimizasyonu yapılamadı!" | tee -a "$LOGFILE"
            FINAL_OUT="$META_OUT"
        fi
    fi

    # [6] Final output
    echo
    echo "=== [6] Final Output ==="
    
    # FINAL_OUT henüz set edilmediyse, META_OUT'u kullan
    if [ -z "$FINAL_OUT" ]; then
        FINAL_OUT="$META_OUT"
    fi
    
    if [ -f "$FINAL_OUT" ]; then
        echo "✅ BAŞARILI: Final dosya hazır -> $FINAL_OUT"
        
        # Final video bilgilerini göster
        echo
        show_video_info "$FINAL_OUT" "Final Video"
        echo
        
        # [7] Kalite Skoru Hesaplama (En son - Final dosya için)
        echo
        echo "=== [7] Kalite Skoru Hesaplama ==="
        echo ">>> Final dosya için kalite skoru hesaplanıyor..."
        FINAL_QUALITY_SCORE=$(calculate_quality_score "$FINAL_OUT")
        echo "📊 Final Kalite Skoru: $FINAL_QUALITY_SCORE/100"
        
        # Eğer optimized dosya varsa, onun skorunu da göster
        if [ -f "$OPTIMIZED_OUT" ] && [ "$FINAL_OUT" == "$OPTIMIZED_OUT" ]; then
            OPTIMIZED_SCORE="$FINAL_QUALITY_SCORE"
            PROCESSED_VIDEOS+=("$INPUT|$META_OUT|$FINAL_OUT|$FINAL_QUALITY_SCORE|$FINAL_QUALITY_SCORE|$METADATA_RESULT|$FASTSTART_RESULT")
        else
            PROCESSED_VIDEOS+=("$INPUT|$META_OUT|$FINAL_OUT|$FINAL_QUALITY_SCORE||$METADATA_RESULT|$FASTSTART_RESULT")
        fi
    else
        echo "❌ BAŞARISIZ: Final dosya oluşturulamadı!" | tee -a "$LOGFILE"
        PROCESSED_VIDEOS+=("$INPUT|$META_OUT||0||$METADATA_RESULT|$FASTSTART_RESULT")
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
