#!/bin/bash
# ============================================
# LinuxZoo Part 1: Complete Setup (Day 01-15)
# Refactored: Single Run, Non-Redundant, Idempotent
# ============================================
set -e

echo "=========================================="
echo "[*] Memulai Setup LinuxZoo Part 1 (Day 01-15)..."
echo "=========================================="

# ============================================
#  GLOBAL CONFIG & PREPARATION
# ============================================
USER="user"
HOME_DIR="/home/$USER"
BASE_DIR="$HOME_DIR/linuxzoo"
HOSTNAME="shinobee"

# 1. User Setup
if ! id "$USER" &>/dev/null; then
    echo "[+] Membuat user: $USER"
    useradd -m -s /bin/bash "$USER"
    echo "$USER:pass123" | chpasswd
fi

# 2. Hostname Setup
hostname "$HOSTNAME" 2>/dev/null || true
if ! grep -q "$HOSTNAME" /etc/hosts; then
    echo "127.0.1.1 $HOSTNAME" >> /etc/hosts
fi

# 3. Install Dependencies (sekali saja)
if ! command -v locate &>/dev/null || ! command -v ssh-keygen &>/dev/null; then
    echo "[+] Memperbarui repositori & menginstall paket..."
    apt-get update -qq >/dev/null 2>&1
    apt-get install -y -qq plocate openssh-client >/dev/null 2>&1
fi

# Bersihkan base dir lama secara aman
rm -rf "$BASE_DIR" 2>/dev/null || true
mkdir -p "$BASE_DIR"

# ============================================
# 🐧 DAY-BY-DAY SETUP
# ============================================

# DAY 01: Navigasi (Hidden Folder)
echo "[*] Setup Day 01..."
mkdir -p "$BASE_DIR/day01/.jejak_emperor"
cat > "$BASE_DIR/day01/clue.md" << 'EOF'
# Day 01: Jejak Emperor
Emperor tidak meninggalkan jejaknya di tempat yang mudah terlihat.
Ia menyimpan catatan awalnya di balik bayangan.
Carilah di mana hal yang tak terlihat biasanya bersembunyi.
EOF
echo "BEE{navigasi_tersembunyi}" > "$BASE_DIR/day01/.jejak_emperor/flag.txt"

# DAY 02: Dokumentasi (Command --help)
echo "[*] Setup Day 02..."
rm -f /usr/local/bin/adelie-guide 2>/dev/null || true
mkdir -p "$BASE_DIR/day02/.kotak_adelie"
cat > "$BASE_DIR/day02/clue.md" << 'EOF'
# Day 02: Kotak Petunjuk Adélie
Adélie tidak pernah bekerja tanpa membaca panduan.
Cek command `adelie-guide` yang sudah terpasang di sistem.
Minta bantuannya menggunakan `--help`, dan petunjuk akan terungkap.
EOF
echo "BEE{adelie_dokumentasi_sistem}" > "$BASE_DIR/day02/.kotak_adelie/flag.txt"
cat > /usr/local/bin/adelie-guide << 'SCRIPT'
#!/bin/bash
case "$1" in
  --help|-h)
    echo "Adélie Guide Tool v1.0"
    echo "Usage: adelie-guide [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --help, -h    Show this help message"
    echo "  --version     Show version info"
    echo ""
    echo "Documentation Reference:"
    echo "BEE{day02_adelie_dokumentasi_sistem}"
    ;;
  *)
    echo "Running default guide process..."
    echo "No specific action taken. Try --help for options."
    ;;
esac
SCRIPT
chmod +x /usr/local/bin/adelie-guide

# DAY 03: Manipulasi File (Split Flag)
echo "[*] Setup Day 03..."
mkdir -p "$BASE_DIR/day03/.sarang_gentoo"
cat > "$BASE_DIR/day03/clue.md" << 'EOF'
# Day 03: Batu Sarang Gentoo
Gentoo membangun dengan presisi. Tidak ada satu file yang menyimpan seluruh rahasia.
Catatan tersembunyi terpecah menjadi tiga bagian.
Kumpulkan, gabungkan, dan bacalah sebagai satu kesatuan.
EOF
printf "BEE{simulasi_" > "$BASE_DIR/day03/.sarang_gentoo/part1.txt"
printf "manipulasi_file_" > "$BASE_DIR/day03/.sarang_gentoo/part2.txt"
printf "presisi}" > "$BASE_DIR/day03/.sarang_gentoo/part3.txt"

# DAY 04: Pencarian Data (Locate + Grep Noise)
echo "[*] Setup Day 04..."
rm -f /opt/archives/chinstrap_logs.txt 2>/dev/null || true
mkdir -p "$BASE_DIR/day04" /opt/archives
cat > "$BASE_DIR/day04/clue.md" << 'EOF'
# Day 04: Jejak Chinstrap
Chinstrap tidak mencari secara acak. Ia mengikuti pola.
Gunakan `locate` untuk menemukan file arsip yang menyimpan log Chinstrap.
Setelah file ditemukan, saring isinya dengan `grep`. Flag tersembunyi di antara noise yang sangat panjang.
EOF
FLAG_FILE="/opt/archives/chinstrap_logs.txt"
FLAG="BEE{chinstrap_tracking_pattern_verified}"
NOISE="Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum. "
> "$FLAG_FILE"
for i in {1..30}; do echo "$NOISE" >> "$FLAG_FILE"; done
echo "[SYS_TRACE] Chinstrap signal intercepted. Pattern match confirmed: $FLAG" >> "$FLAG_FILE"
for i in {1..30}; do echo "$NOISE" >> "$FLAG_FILE"; done
chmod 644 "$FLAG_FILE"

# DAY 05: Pipeline (Multiple Logs + Grep)
echo "[*] Setup Day 05..."
rm -f /var/log/auth_king_*.log 2>/dev/null || true
mkdir -p "$BASE_DIR/day05"
cat > "$BASE_DIR/day05/clue.md" << 'EOF'
# Day 05: Arus Data King
King tidak membiarkan data mengalir semrawut.
Gunakan `locate` untuk menemukan semua file `auth_king` di sistem.
Ada banyak file dengan nama serupa. Saring isinya dengan pipeline yang tepat.
Flag tersembunyi di salah satu file, di antara ribuan baris log.
Hint: "king".
EOF
LOG_DIR="/var/log"
FLAG5="BEE{king_pipeline_flow_verified}"
generate_noise() {
    local file=$1 count=$2 i m s pid ip port
    for i in $(seq 1 $count); do
        m=$(printf "%02d" $((RANDOM % 60)))
        s=$(printf "%02d" $((RANDOM % 60)))
        pid=$((1000 + RANDOM % 9000))
        ip="192.168.$((RANDOM % 256)).$((RANDOM % 256))"
        port=$((2000 + RANDOM % 40000))
        echo "Jan 15 08:$m:$s shinobee sshd[$pid]: session opened for user from $ip port $port" >> "$file"
    done
}
for i in $(seq 1 9); do
    padded=$(printf "%02d" $i)
    target_file="$LOG_DIR/auth_king_${padded}.log"
    > "$target_file"
    if [ "$i" -ne 7 ]; then generate_noise "$target_file" 500; fi
done
FILE_07="$LOG_DIR/auth_king_07.log"
> "$FILE_07"
generate_noise "$FILE_07" 250
echo "Jan 15 08:42:17 shinobee kernel: [king] pipeline check: $FLAG5" >> "$FILE_07"
generate_noise "$FILE_07" 250
chmod 644 /var/log/auth_king_*.log

# DAY 06: Hidden Files (~/.bashrc)
echo "[*] Setup Day 06..."
BASHRC="$HOME_DIR/.bashrc"
touch "$BASHRC"
sed -i '/# ZOO_MACARONI_TRACE/d' "$BASHRC"
mkdir -p "$BASE_DIR/day06"
cat > "$BASE_DIR/day06/clue.md" << 'EOF'
# Day 06: Jejak Macaroni
Catatan rahasianya terselip di sebuah file yang selalu bekerja diam-diam setiap kali sesi terminalmu dimulai.
Audit file konfigurasi shell-mu, dan temukan apa yang ia sembunyikan.
EOF
echo "# ZOO_MACARONI_TRACE: BEE{hidden_audit_verified}" >> "$BASHRC"

# DAY 07: User/Group (su switch)
echo "[*] Setup Day 07..."
GUARD_USER="rockhopper"
GUARD_PASS="hopper"
if id "$GUARD_USER" &>/dev/null; then pkill -u "$GUARD_USER" 2>/dev/null || true; userdel -r "$GUARD_USER" 2>/dev/null || true; fi
rm -rf "$BASE_DIR/day07" 2>/dev/null || true
useradd -m -s /bin/bash "$GUARD_USER"
echo "$GUARD_USER:$GUARD_PASS" | chpasswd
mkdir -p "/home/$GUARD_USER"
echo "BEE{identity_switch_verified}" > "/home/$GUARD_USER/.access_log"
chmod 600 "/home/$GUARD_USER/.access_log"
chown "$GUARD_USER:$GUARD_USER" "/home/$GUARD_USER/.access_log"
mkdir -p "$BASE_DIR/day07"
cat > "$BASE_DIR/day07/clue.md" << EOF
# Day 07: Penjaga Koloni
Rockhopper tidak membiarkan sembarang identitas mengakses wilayahnya.
Jejak audit tersimpan di folder pribadi penjaga: /home/$GUARD_USER/.access_log
Kamu bukan pemiliknya. Pinjam identitasnya sementara dan gunakan kunci akses: "$GUARD_PASS".
EOF

# DAY 08: Permission (chmod 000)
echo "[*] Setup Day 08..."
VAULT_DIR="/opt/northern_vault"
TARGET_FILE="$VAULT_DIR/access.key"
rm -rf "$VAULT_DIR" 2>/dev/null || true
mkdir -p "$VAULT_DIR" "$BASE_DIR/day08"
echo "BEE{permission_chmod_verified}" > "$TARGET_FILE"
chown "$USER:$USER" "$TARGET_FILE"
chmod 000 "$TARGET_FILE"
cat > "$BASE_DIR/day08/clue.md" << 'EOF'
# Day 08: Kunci Northern Rockhopper
Rockhopper tidak membagi kunci sembarangan. Brankas digitalnya dikunci rapat: tidak ada pemilik, grup, maupun orang luar yang bisa menyentuhnya saat ini.
Jejak akses tersimpan di `/opt/northern_vault/access.key`.
Ubah mode aksesnya agar pemilik bisa baca/tulis, dan lainnya bisa baca.
Petunjuk: Kamu adalah pemilik file ini, tapi kuncinya sedang dalam mode "nol".
EOF

# DAY 09: SSH (Public Key Comment)
echo "[*] Setup Day 09..."
SSH_DIR="$HOME_DIR/.ssh"
KEY_NAME="hoiho_key"
rm -rf "$BASE_DIR/day09" 2>/dev/null || true
rm -f "$SSH_DIR/$KEY_NAME" "$SSH_DIR/$KEY_NAME.pub" 2>/dev/null || true
mkdir -p "$SSH_DIR" "$BASE_DIR/day09"
ssh-keygen -t ed25519 -f "$SSH_DIR/$KEY_NAME" -N "" -C "BEE{hoiho_ssh_key_verified}" -q 2>/dev/null
chmod 700 "$SSH_DIR"; chmod 600 "$SSH_DIR/$KEY_NAME"; chmod 644 "$SSH_DIR/$KEY_NAME.pub"
cat > "$BASE_DIR/day09/clue.md" << 'EOF'
# Day 09: Gerbang Hoiho
Hoiho memverifikasi setiap kunci sebelum membuka gerbang.
Sebuah pasangan kunci digital telah disiapkan di brankas konfigurasi remote-mu (~/.ssh/).
Carilah berkas berakhiran `.pub`. Jejak identitas tersimpan di kolom komentar paling akhir baris tersebut.
EOF

# DAY 10: Environment Variables (Split Concat)
echo "[*] Setup Day 10..."
sed -i '/# FIORDLAND_MAP/d; /ZOO_ROUTE_/d' "$BASHRC" "$HOME_DIR/.profile" 2>/dev/null || true
mkdir -p "$BASE_DIR/day10"
cat > "$BASE_DIR/day10/clue.md" << 'EOF'
# Day 10: Peta Jalan Fiordland
Fiordland tidak mengandalkan ingatan. Ia membaca tanda yang selalu dimuat saat sesi dimulai.
Dua koordinat peta jalan disembunyikan dalam konfigurasi shell-mu, terpecah menjadi bagian awal dan akhir.
Muat ulang konfigurasi (`source ~/.bashrc` atau login ulang), gabungkan kedua variabel, dan baca rutenya.
EOF

# Taruh di .profile (login shell) + .bashrc (interactive)
cat >> "$HOME_DIR/.profile" << 'VARS'
export ZOO_ROUTE_START="BEE{fiordland_"
export ZOO_ROUTE_END="env_persist_verified}"
VARS
cat >> "$BASHRC" << 'VARS'
export ZOO_ROUTE_START="BEE{fiordland_"
export ZOO_ROUTE_END="env_persist_verified}"
VARS

# DAY 11: FHS (/etc/motd)
echo "[*] Setup Day 11..."
MOTD_FILE="/etc/motd"
sed -i '/# Snares Trace/d' "$MOTD_FILE" 2>/dev/null || true
mkdir -p "$BASE_DIR/day11"
cat > "$BASE_DIR/day11/clue.md" << 'EOF'
# Day 11: Peta Snares
Snares mengenal setiap sudut pulau. Ia meninggalkan catatan di pesan yang selalu menyambutmu saat pertama kali menjejakkan kaki di sistem.
File itu berada di direktori konfigurasi utama, dan namanya adalah singkatan dari "Message of the Day".
Baca pesan sambutan itu, dan temukan jejak di baris penutupnya.
EOF
echo "# Snares Trace: BEE{fhs_motd_banner_verified}" >> "$MOTD_FILE"

# DAY 12: Text Processing (Scattered Log)
echo "[*] Setup Day 12..."
LOG12="/var/log/erect_audit.log"
TEMP_LOG=$(mktemp)
rm -f "$LOG12" 2>/dev/null || true
rm -rf "$BASE_DIR/day12" 2>/dev/null || true
mkdir -p "$BASE_DIR/day12"
SERVICES=("sshd" "systemd" "cron" "kernel" "NetworkManager" "sudo" "dockerd" "ufw")
MSGS=("Accepted publickey for admin from 192.168.1.10 port 22 ssh2" "session opened for user root by (uid=0)" "Started Daily Cleanup of Temporary Files." "Connection closed by 10.0.0.5 port 443" "Failed password for invalid user test from 172.16.0.10 port 4321 ssh2" "pam_unix(sudo:session): session opened for user root by admin(uid=0)" "Reached target Multi-User System." "Stopping OpenBSD Secure Shell server..." "Started System Logging Service." "dhclient[1234]: DHCPACK from 192.168.1.1" "TCP: request_sock_TCP: Possible SYN flooding on port 80. Sending cookies." "Out of memory: Kill process 1234 (java) score 800 or sacrifice child")
for i in $(seq 1 3000); do
  H=$(printf "%02d" $((RANDOM % 24))); M=$(printf "%02d" $((RANDOM % 60))); S=$(printf "%02d" $((RANDOM % 60)))
  PID=$((1000 + RANDOM % 9000))
  SVC=${SERVICES[$((RANDOM % ${#SERVICES[@]}))]}
  MSG=${MSGS[$((RANDOM % ${#MSGS[@]}))]}
  echo "Jan 15 $H:$M:$S shinobee $SVC[$PID]: $MSG" >> "$TEMP_LOG"
done
echo "Jan 15 04:11:22 shinobee erect[9901]: FLAG_PART_1=BEE{erect_" >> "$TEMP_LOG"
echo "Jan 15 12:33:45 shinobee erect[9902]: FLAG_PART_2=text_processing_" >> "$TEMP_LOG"
echo "Jan 15 18:05:09 shinobee erect[9903]: FLAG_PART_3=verified}" >> "$TEMP_LOG"
shuf "$TEMP_LOG" > "$LOG12"
rm -f "$TEMP_LOG"
chmod 644 "$LOG12"
chown root:root "$LOG12"
cat > "$BASE_DIR/day12/clue.md" << 'EOF'
# Day 12: Alihkan Noise, Kendalikan Output
Erect tidak membiarkan sinyal tercecer. Log pelacakan sistem ada di `/var/log/erect_audit.log`.
Flag dipecah menjadi 3 bagian yang ditandai `erect[...]`.
Gunakan pipeline untuk menyaring baris tracer, ekstraksi nilai setelah `=`, urutkan, dan gabungkan tanpa baris baru.
EOF

# DAY 13: Kompresi (tar.gz Archive)
echo "[*] Setup Day 13..."
BACKUP_DIR="/var/backups"
ARCHIVE="$BACKUP_DIR/african_archive.tar.gz"
TEMP_STAGING=$(mktemp -d)
rm -rf "$BASE_DIR/day13" "$ARCHIVE" 2>/dev/null || true
mkdir -p "$BASE_DIR/day13" "$TEMP_STAGING/configs" "$TEMP_STAGING/logs" "$TEMP_STAGING/data"
echo -e "server_name=shinobee\nbackup_date=$(date +%Y-%m-%d)\nstatus=pending" > "$TEMP_STAGING/configs/server.conf"
echo "$(date '+%Y-%m-%d %H:%M:%S') sshd: session opened for user admin" > "$TEMP_STAGING/logs/audit.log"
dd if=/dev/urandom of="$TEMP_STAGING/data/db_dump.bin" bs=1K count=5 2>/dev/null
echo "# MANIFEST BACKUP HARIAN\nFLAG_PAYLOAD=BEE{african_backup_integrity_verified}" > "$TEMP_STAGING/configs/backup_manifest.txt"
tar -czf "$ARCHIVE" -C "$TEMP_STAGING" configs logs data
rm -rf "$TEMP_STAGING"
chmod 644 "$ARCHIVE"
chown root:"$USER" "$ARCHIVE"
cat > "$BASE_DIR/day13/clue.md" << 'EOF'
# Day 13: Paket Arsip African
African mengemas cadangan sistem di lokasi standar backup.
Arsip terkompresi menunggu verifikasi di `/var/backups/`.
Jangan ekstrak sembarangan. Cek isi arsip dulu, lalu ambil file manifest konfigurasi dari dalamnya.
EOF

# DAY 14: Process Management (Background Process)
echo "[*] Setup Day 14..."
SCRIPT14="/usr/local/bin/humboldt"
pkill -f humboldt 2>/dev/null || true; sleep 1
rm -f "$SCRIPT14" 2>/dev/null || true
rm -rf "$BASE_DIR/day14" 2>/dev/null || true
mkdir -p "$BASE_DIR/day14"
cat > "$SCRIPT14" << 'EOF'
#!/bin/bash
# Humboldt background monitor
while true; do sleep 3600; done
EOF
chmod +x "$SCRIPT14"
setsid "$SCRIPT14" "BEE{humboldt_process_audit_verified}" &>/dev/null &
cat > "$BASE_DIR/day14/clue.md" << 'EOF'
# Day 14: Pengawasan Humboldt
Humboldt memantau setiap aktivitas yang berjalan di sistem.
Sebuah proses monitoring sedang aktif di background.
Gunakan snapshot proses lengkap untuk melihat command line yang sedang ia jalankan.
EOF

# DAY 15: Service Management (systemd Unit)
echo "[*] Setup Day 15..."
UNIT_NAME="magellanic-audit.service"
UNIT_PATH="/etc/systemd/system/$UNIT_NAME"
systemctl stop "$UNIT_NAME" 2>/dev/null || true
systemctl disable "$UNIT_NAME" 2>/dev/null || true
rm -f "$UNIT_PATH" 2>/dev/null || true
rm -rf "$BASE_DIR/day15" 2>/dev/null || true
mkdir -p "$BASE_DIR/day15"
cat > "$UNIT_PATH" << EOF
[Unit]
Description=Magellanic Audit Daemon - BEE{magellanic_service_lifecycle_verified}
After=network.target

[Service]
Type=oneshot
ExecStart=/bin/true
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
if command -v systemctl &>/dev/null; then
    systemctl daemon-reload 2>/dev/null || true
    systemctl enable "$UNIT_NAME" 2>/dev/null || true
fi
chmod 644 "$UNIT_PATH"
cat > "$BASE_DIR/day15/clue.md" << 'EOF'
# Day 15: Mesin Magellanic
Magellanic memastikan mesin vital tetap berjalan.
Sebuah daemon audit telah terdaftar di manajer service sistem.
Periksa statusnya, atau baca langsung file unit-nya di direktori konfigurasi service kustom.
EOF

# ============================================
# ✅ GLOBAL POST-SETUP & VERIFICATION
# ============================================
echo "[*] Menerapkan permission global..."
chown -R "$USER:$USER" "$HOME_DIR"
chmod 750 "$HOME_DIR"
updatedb 2>/dev/null || true

echo "=========================================="
echo "[✅] LinuxZoo Part 1 Setup Selesai!"
echo "[*] 15 Day berhasil dikonfigurasi."
echo "[*] Login sebagai user: $USER | Password: pass123"
echo "[*] Mulai tantangan dari: cd $BASE_DIR/day01"
echo "=========================================="
