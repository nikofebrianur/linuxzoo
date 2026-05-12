#!/bin/bash
set -e

echo "=================================================="
echo "[*] Memulai Setup LinuxZoo Master Script (Day 16-30)"
echo "=================================================="

# --- KONFIGURASI GLOBAL ---
USER_STD="user"
USER_PINGU="pingu"
PASS="pass123"
BASE_ROOT="/home" # Asumsi home directory ada di /home

# --- 1. USER MANAGEMENT & DEPENDENCIES (Global Setup) ---
echo "[*] Melakukan konfigurasi User dan Dependensi Sistem..."

# Fungsi helper untuk membuat user
create_user_if_not_exists() {
    local u=$1
    if ! id "$u" &>/dev/null; then
        useradd -m -s /bin/bash "$u"
        echo "$u:$PASS" | chpasswd
        echo "[+] User '$u' dibuat."
    else
        echo "[i] User '$u' sudah ada."
    fi
}

# Buat User Standar
create_user_if_not_exists "$USER_STD"
create_user_if_not_exists "$USER_PINGU"

# Pastikan grup sudo dan adm ada
for grp in sudo adm; do
    if ! getent group "$grp" >/dev/null; then
        groupadd "$grp"
    fi
    # Tambahkan kedua user ke grup sudo/adm jika belum
    usermod -aG "$grp" "$USER_STD" 2>/dev/null || true
    usermod -aG "$grp" "$USER_PINGU" 2>/dev/null || true
done

# Fix hostname resolution untuk menghindari warning sudo
if ! grep -q "$(hostname)" /etc/hosts 2>/dev/null; then
    echo "127.0.0.1 $(hostname)" >> /etc/hosts 2>/dev/null || true
fi

# Install Dependencies Sekaligus (Hemat waktu apt update)
echo "[*] Menginstal dependensi sistem (ufw, auditd, rsyslog)..."
apt-get update -qq >/dev/null 2>&1 || true
apt-get install -y -qq ufw rsyslog auditd >/dev/null 2>&1 || true

# Enable services
systemctl enable --now rsyslog >/dev/null 2>&1 || true
systemctl enable --now cron >/dev/null 2>&1 || true
# Auditd mungkin perlu restart setelah install
systemctl restart auditd >/dev/null 2>&1 || true

echo "[+] Prasyarat sistem selesai."
echo "--------------------------------------------------"

# --- FUNGSI SETUP PER HARI ---

setup_day_16() {
    echo "[*] Setup Day 16: Galapagos Backup..."
    local USER="$USER_STD"
    local HOME_DIR="$BASE_ROOT/$USER"
    local BASE_DIR="$HOME_DIR/linuxzoo"
    local CONF_DIR="/opt/galap_configs"
    local BAK_FILE="$CONF_DIR/sshd_config.bak"
    local FLAG="BEE{galapagos_safe_edit_backup_verified}"

    # Clean & Prepare
    rm -rf "$BASE_DIR/day16" "$CONF_DIR" 2>/dev/null || true
    mkdir -p "$BASE_DIR/day16/practice" "$CONF_DIR"

    # Clue
    cat > "$BASE_DIR/day16/clue.md" << 'EOF'
# Day 16: Ukiran Galápagos
Galápagos tidak pernah mengukir tanpa menyiapkan cadangan.
Sebelum mengubah konfigurasi utama, ia selalu menyimpan versi asli di tempat yang aman.
Cek direktori konfigurasi tambahan di `/opt/`, dan temukan berkas berakhiran `.bak`.
Jejak ukirannya tersembunyi di baris komentar berkas tersebut.
EOF

    # Flag File
    cat > "$BAK_FILE" << EOF
# Galápagos Backup Snapshot
# Generated: $(date +%Y-%m-%d_%H:%M:%S)
Port 22
PermitRootLogin no
PasswordAuthentication yes
PubkeyAuthentication yes
# AUDIT_MARKER: $FLAG
EOF

    chmod 644 "$BAK_FILE"
    chown root:root "$BAK_FILE"
    chown -R "$USER:$USER" "$HOME_DIR"

    # Verify
    if grep -q "AUDIT_MARKER" "$BAK_FILE"; then
        echo "[✅] Day 16 Selesai."
    else
        echo "[❌] Day 16 Gagal."
    fi
}

setup_day_17() {
    echo "[*] Setup Day 17: Log Analysis..."
    local USER="$USER_STD"
    local HOME_DIR="$BASE_ROOT/$USER"
    local BASE_DIR="$HOME_DIR/linuxzoo"
    local MARKER="little-penguin-audit"
    local PID=$$

    rm -rf "$BASE_DIR/day17" 2>/dev/null || true
    mkdir -p "$BASE_DIR/day17" /var/log/apt

    local LOG_FILES=("/var/log/auth.log" "/var/log/syslog" "/var/log/kern.log" "/var/log/dpkg.log" "/var/log/apt/history.log")
    
    for log in "${LOG_FILES[@]}"; do
        touch "$log" 2>/dev/null || true
        sed -i "/$MARKER/d" "$log" 2>/dev/null || true
        sed -i "/BEE{.*try.*|BEE{.*false.*/d" "$log" 2>/dev/null || true
    done

    cat > "$BASE_DIR/day17/clue.md" << 'EOF'
# Day 17: Buku Harian Little
Little mencatat aktivitas vital di tiga jurnal utama sistem.
Jejaknya tersamar di balik penanda proses khusus.
Jangan terkecoh oleh catatan pergantian paket; fokuslah pada inti operasi, autentikasi, dan kernel.
Kumpulkan potongan yang tersembunyi, susun berurutan, dan bacalah sebagai satu kesatuan.
EOF

    local FLAG_P1="BEE{log_analysis_"
    local FLAG_P2="master_"
    local FLAG_P3="verified}"

    echo "Jan 15 08:14:22 shinobee $MARKER[$PID]: PART_1=$FLAG_P1" >> /var/log/kern.log
    echo "Jan 15 09:30:15 shinobee $MARKER[$PID]: PART_2=$FLAG_P2" >> /var/log/kern.log
    echo "Jan 15 10:45:08 shinobee $MARKER[$PID]: PART_3=$FLAG_P3" >> /var/log/kern.log

    # Decoys
    echo "Jan 15 11:12:33 shinobee dpkg[$PID]: status installed BEE{nice_try_wrong_log}" >> /var/log/dpkg.log
    echo "Jan 15 11:15:44 shinobee apt-history[$PID]: Operation: Install BEE{false_positive_apt}" >> /var/log/apt/history.log

    for log in "${LOG_FILES[@]}"; do
        chmod 644 "$log"
        chown root:root "$log"
    done
    chown -R "$USER:$USER" "$HOME_DIR"
    chmod 750 "$HOME_DIR"

    if grep -q "PART_1=" /var/log/auth.log && grep -q "PART_2=" /var/log/syslog && grep -q "PART_3=" /var/log/kern.log; then
        echo "[✅] Day 17 Selesai."
    else
        echo "[❌] Day 17 Gagal."
    fi
}

setup_day_18() {
    echo "[*] Setup Day 18: Package Audit..."
    local USER="$USER_STD"
    local HOME_DIR="$BASE_ROOT/$USER"
    local BASE_DIR="$HOME_DIR/linuxzoo"
    local APT_CONF="/etc/apt/apt.conf.d/99-white-audit.conf"
    local FLAG="BEE{package_audit_verified}"

    rm -rf "$BASE_DIR/day18" 2>/dev/null || true
    rm -f "$APT_CONF" 2>/dev/null || true
    mkdir -p "$BASE_DIR/day18/practice" /etc/apt/apt.conf.d

    cat > "$BASE_DIR/day18/clue.md" << 'EOF'
# Day 18: Stok White
White tidak menerima pasokan tanpa verifikasi.
Catatan audit pasokan tersimpan di konfigurasi tambahan manajer paket.
Cek direktori konfigurasi snippet, dan temukan berkas berakhiran -audit.conf.
Jejak verifikasi tersembunyi di baris komentar berkas tersebut.
EOF

    cat > "$APT_CONF" << EOF
// White-flippered Audit Configuration
// Generated: $(date +%Y-%m-%d)
// Purpose: Track package verification events
// AUDIT_FLAG: $FLAG
EOF

    chmod 644 "$APT_CONF"
    chown root:root "$APT_CONF"
    chown -R "$USER:$USER" "$HOME_DIR"
    chmod 750 "$HOME_DIR"

    if grep -q "AUDIT_FLAG" "$APT_CONF"; then
        echo "[✅] Day 18 Selesai."
    else
        echo "[❌] Day 18 Gagal."
    fi
}

setup_day_19() {
    echo "[*] Setup Day 19: Secure Crontab..."
    local USER="$USER_STD"
    local HOME_DIR="$BASE_ROOT/$USER"
    local BASE_DIR="$HOME_DIR/linuxzoo"
    local CRON_SCRIPT="/usr/local/bin/royal-audit.sh"
    local SUDOERS_FILE="/etc/sudoers.d/royal-audit"
    local OUTPUT_LOG="$HOME_DIR/.royal_audit.log"

    rm -rf "$BASE_DIR/day19" 2>/dev/null || true
    rm -f "$CRON_SCRIPT" "$SUDOERS_FILE" "$OUTPUT_LOG" 2>/dev/null || true
    
    # Hapus cron lama
    if su - "$USER" -c "crontab -l" 2>/dev/null | grep -q "royal-audit"; then
        su - "$USER" -c "crontab -l" 2>/dev/null | grep -v "royal-audit" | su - "$USER" -c "crontab -" 2>/dev/null || true
    fi

    mkdir -p "$BASE_DIR/day19/practice"

    cat > "$CRON_SCRIPT" << 'SCRIPT'
#!/bin/bash
# Royal Audit Task - Secure Execution
P1="BEE{schedule_"
P2="execution_"
P3="verified}"
LOG="/home/user/.royal_audit.log"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Royal audit executed. FLAG: ${P1}${P2}${P3}" >> "$LOG"
SCRIPT

    chmod 700 "$CRON_SCRIPT"
    chown root:root "$CRON_SCRIPT"

    echo "$USER ALL=(root) NOPASSWD: $CRON_SCRIPT" > "$SUDOERS_FILE"
    chmod 0440 "$SUDOERS_FILE"
    visudo -cf "$SUDOERS_FILE" >/dev/null 2>&1 || { echo "[!] Sudoers validation failed"; exit 1; }

    CRON_ENTRY="0 2 * * * sudo $CRON_SCRIPT"
    echo "$CRON_ENTRY" | su - "$USER" -c "crontab -"

    touch "$OUTPUT_LOG"
    chown "$USER:$USER" "$OUTPUT_LOG"
    chmod 644 "$OUTPUT_LOG"

    cat > "$BASE_DIR/day19/clue.md" << 'EOF'
# Day 19: Jadwal Royal
Royal mempercayakan waktu pada sistem, bukan ingatan.
Tugas audit telah dijadwalkan di crontab-mu, namun waktu default-nya tidak praktis untuk latihan.
Percepat jadwal eksekusi, lalu pantau file log pribadi yang telah ditentukan.
Jejak eksekusi akan meninggalkan tanda khusus saat tugas benar-benar berjalan.
EOF

    systemctl restart cron 2>/dev/null || true

    if [ -f "$CRON_SCRIPT" ] && [ -f "$SUDOERS_FILE" ] && su - "$USER" -c "crontab -l" 2>/dev/null | grep -q "royal-audit.sh"; then
        echo "[✅] Day 19 Selesai."
    else
        echo "[❌] Day 19 Gagal."
    fi
}

setup_day_20() {
    echo "[*] Setup Day 20: Bash Obfuscation..."
    local USER="$USER_STD"
    local HOME_DIR="$BASE_ROOT/$USER"
    local BASE_DIR="$HOME_DIR/linuxzoo"
    local SCRIPT_PATH="$BASE_DIR/day20/eastern-recipe.sh"

    rm -rf "$BASE_DIR/day20" 2>/dev/null || true
    mkdir -p "$BASE_DIR/day20"

    cat > "$SCRIPT_PATH" << 'SCRIPT'
#!/bin/dash
if [ ! -x "$0" ]; then
    echo "[ERROR] Permission tidak valid atau script dipanggil via interpreter langsung."
    exit 1
fi
set -eu
echo "[*] Memulai verifikasi resep Eastern Rockhopper..."
sleep 1
ENC_P1="QkVFe2F1dG9tYXRpb25f"
ENC_P2="cmVjaXBlX3ZlcmlmaWVk"
ENC_P3="fQ=="
FLAG=$(echo -n "${ENC_P1}${ENC_P2}${ENC_P3}" | base64 -d)
echo "[+] Verifikasi selesai."
echo "FLAG: ${FLAG}"
SCRIPT

    chmod 644 "$SCRIPT_PATH"
    chown -R "$USER:$USER" "$BASE_DIR"

    cat > "$BASE_DIR/day20/clue.md" << 'EOF'
# Day 20: Resep Eastern
Eastern tidak meracik bahan tanpa memeriksa alat dan instruksi.
File resep telah disiapkan di direktori hari ini, namun ia belum siap dieksekusi.
Periksa header interpreter, berikan hak jalan yang tepat, lalu jalankan sesuai prosedur.
Sistem hanya akan menyerahkan verifikasi jika resep dijalankan dengan aturan yang benar.
EOF

    if [ -f "$SCRIPT_PATH" ] && [ ! -x "$SCRIPT_PATH" ] && grep -q "#!/bin/dash" "$SCRIPT_PATH"; then
        echo "[✅] Day 20 Selesai."
    else
        echo "[❌] Day 20 Gagal."
    fi
}

setup_day_21() {
    echo "[*] Setup Day 21: Script Validation..."
    local USER="$USER_STD"
    local HOME_DIR="$BASE_ROOT/$USER"
    local BASE_DIR="$HOME_DIR/linuxzoo"
    local SCRIPT_PATH="$BASE_DIR/day21/western-validator.sh"

    rm -rf "$BASE_DIR/day21" 2>/dev/null || true
    mkdir -p "$BASE_DIR/day21"

    cat > "$SCRIPT_PATH" << 'SCRIPT'
#!/bin/
set -eu
echo "[*] Memulai validasi Western Rockhopper..."
sleep 1
P2="Z2luZ190ZXN0aW5n"
P1="QkVFe2RlYnVn"
P3="X3ZlcmlmaWVkfQ=="
FLAG=$(echo -n "${P1}${P2}${P3}" | base64 -d 2>/dev/null
echo "[+] FLAG: ${FLAG}"
SCRIPT

    chmod 644 "$SCRIPT_PATH"
    chown -R "$USER:$USER" "$BASE_DIR"

    cat > "$BASE_DIR/day21/clue.md" << 'EOF'
# Day 21: Celah Western
Western tidak melompat sebelum menguji pijakan.
Script validasi telah disiapkan, namun ia mengandung celah sintaks dan konfigurasi.
Gunakan alat pengujian untuk menemukan dan memperbaiki celah tersebut.
Sistem hanya akan menyerahkan verifikasi jika script lolos semua pemeriksaan dan dijalankan dengan prosedur yang benar.
EOF

    # Note: grep check adjusted because original script had #!/bin/ which is invalid but intentional
    if [ -f "$SCRIPT_PATH" ] && [ ! -x "$SCRIPT_PATH" ]; then
        echo "[✅] Day 21 Selesai."
    else
        echo "[❌] Day 21 Gagal."
    fi
}

setup_day_22() {
    echo "[*] Setup Day 22: UFW Firewall..."
    local USER="$USER_STD"
    local HOME_DIR="$BASE_ROOT/$USER"
    local BASE_DIR="$HOME_DIR/linuxzoo"
    local FLAG="BEE{falkland_firewall_verified}"

    rm -rf "$BASE_DIR/day22" 2>/dev/null || true
    rm -f /var/log/ufw.log 2>/dev/null || true
    truncate -s 0 /var/log/syslog 2>/dev/null || true 

    ufw --force reset >/dev/null 2>&1 || true
    ufw disable >/dev/null 2>&1 || true

    mkdir -p "$BASE_DIR/day22"

    logger -t kernel "[UFW AUDIT] IN=lo OUT= SRC=127.0.0.1 DST=127.0.0.1 LEN=60 PROTO=TCP SPT=40000 DPT=443 AUDIT_FLAG: $FLAG"
    sleep 2

    cat > "$BASE_DIR/day22/clue.md" << 'EOF'
# Day 22: Tembok Falkland
Falkland tidak membangun tembok tanpa mencatat aturan dan kejadiannya.
Log sistem mencatat setiap paket yang disaring oleh firewall, namun pencatatan tidak aktif secara default.
Aktifkan firewall dan logging sistem, kemudian periksa berkas log yang dihasilkan.
Jejak verifikasi audit akan tercatat secara alami saat layanan pencatatan berjalan.
EOF

    if grep -q "AUDIT_FLAG: $FLAG" /var/log/syslog 2>/dev/null || grep -q "AUDIT_FLAG: $FLAG" /var/log/ufw.log 2>/dev/null; then
        echo "[✅] Day 22 Selesai."
    else
        echo "[⚠️] Day 22 Warning: Log entry might take time to appear."
    fi
}

setup_day_23() {
    echo "[*] Setup Day 23: System Hardening..."
    local USER="$USER_STD"
    local HOME_DIR="$BASE_ROOT/$USER"
    local BASE_DIR="$HOME_DIR/linuxzoo"
    local AUDIT_RULES="/etc/audit/rules.d/99-hardening.rules"
    local FLAG="BEE{system_hardening_verified}"

    rm -rf "$BASE_DIR/day23" 2>/dev/null || true
    rm -f "$AUDIT_RULES" 2>/dev/null || true
    mkdir -p "$BASE_DIR/day23" /etc/audit/rules.d

    cat > "$AUDIT_RULES" << EOF
## Custom Hardening Rules for LinuxZoo
-w /etc/passwd -p rwxa -k identity_access
-w /etc/shadow -p rwxa -k shadow_access
-w /etc/sudoers -p rwxa -k sudoers_change
-w /var/log/auth.log -p wa -k auth_log_modification
# HARDENING_AUDIT_FLAG: $FLAG
EOF

    chmod 644 "$AUDIT_RULES"
    chown root:root "$AUDIT_RULES"

    cat > "$BASE_DIR/day23/clue.md" << 'EOF'
# Day 23: Benteng Chilean
Chilean tidak mengandalkan ingatan untuk memantau perubahan kritis.
Sistem mencatat setiap aturan pengawasan di direktori konfigurasi audit.
Periksa berkas aturan yang diterapkan untuk hardening perimeter internal.
Jejak verifikasi auditor tersimpan di baris komentar berkas tersebut.
EOF

    chown -R "$USER:$USER" "$HOME_DIR"
    chmod 750 "$HOME_DIR"

    if [ -f "$AUDIT_RULES" ] && grep -q "HARDENING_AUDIT_FLAG: $FLAG" "$AUDIT_RULES"; then
        echo "[✅] Day 23 Selesai."
    else
        echo "[❌] Day 23 Gagal."
    fi
}

setup_day_24() {
    echo "[*] Setup Day 24: Backup Strategy..."
    local USER="$USER_STD"
    local HOME_DIR="$BASE_ROOT/$USER"
    local BASE_DIR="$HOME_DIR/linuxzoo"
    local SOURCE_DIR="$BASE_DIR/day24/data"
    local BACKUP_DIR="$BASE_DIR/day24/backup"
    local CUSTOM_FILE="otago_integrity.dat"

    rm -rf "$BASE_DIR/day24" 2>/dev/null || true
    mkdir -p "$SOURCE_DIR" "$BACKUP_DIR"

    cat > "$SOURCE_DIR/$CUSTOM_FILE" << 'DATA'
OTAGO BACKUP INTEGRITY RECORD
============================
Timestamp: 2026-04-29T10:00:00+0000
Strategy: 3-2-1 Principle Applied
Status: Pending Verification
DATA

    cd "$SOURCE_DIR"
    sha256sum "$CUSTOM_FILE" > "$CUSTOM_FILE.sha256"
    cd - >/dev/null

    cat > "$BASE_DIR/day24/clue.md" << 'EOF'
# Day 24: Strategi Otago
Otago tidak menyimpan cadangan sembarangan. Ia memverifikasi integritas setiap salinan.
Data sumber telah disiapkan di direktori data. Direktori backup masih kosong.
Buat salinan cadangan menggunakan rsync, verifikasi integritasnya dengan sha256sum -c.
Jika verifikasi lolos (OK), ambil hash SHA-256 dari file data tersebut.
Format flag: BEE{<hash_lengkap>}
EOF

    chmod 644 "$SOURCE_DIR"/*
    chown -R "$USER:$USER" "$BASE_DIR"

    if [ -f "$SOURCE_DIR/$CUSTOM_FILE" ] && [ -f "$SOURCE_DIR/$CUSTOM_FILE.sha256" ]; then
        HASH=$(awk '{print $1}' "$SOURCE_DIR/$CUSTOM_FILE.sha256")
        echo "[✅] Day 24 Selesai. Expected Flag: BEE{$HASH}"
    else
        echo "[❌] Day 24 Gagal."
    fi
}

setup_day_25() {
    echo "[*] Setup Day 25: Incident Response..."
    local USER="$USER_STD"
    local HOME_DIR="$BASE_ROOT/$USER"
    local BASE_DIR="$HOME_DIR/linuxzoo"
    local EVIDENCE_FILE="/tmp/.banded_trace.dat"
    local FLAG="BEE{incident_response_verified}"

    rm -rf "$BASE_DIR/day25" 2>/dev/null || true
    rm -f "$EVIDENCE_FILE" 2>/dev/null || true
    mkdir -p "$BASE_DIR/day25"

    cat > "$EVIDENCE_FILE" << EOF
BANDED INCIDENT TRACE LOG
=========================
Detected: 2026-04-29T08:15:00+0000
Source IP: 192.168.10.55
Protocol: TCP/443
Payload: Suspicious data exfiltration attempt
Status: Pending Verification
INCIDENT_FLAG: $FLAG
EOF

    chmod 644 "$EVIDENCE_FILE"
    chown root:root "$EVIDENCE_FILE"

    cat > "$BASE_DIR/day25/clue.md" << 'EOF'
# Day 25: Jejak Banded
Banded tidak langsung menghapus jejak mencurigakan. Ia mendokumentasi, memverifikasi, lalu mengisolasi.
File trace telah ditinggalkan di direktori sementara sistem.
Gunakan find untuk melokasinya, stat untuk membaca metadata, sha256sum untuk verifikasi integritas.
Setelah terdokumentasi, baca isi file untuk mengambil flag, lalu lakukan isolasi dengan chmod 000.
EOF

    chown -R "$USER:$USER" "$HOME_DIR"
    chmod 750 "$HOME_DIR"

    if [ -f "$EVIDENCE_FILE" ] && grep -q "INCIDENT_FLAG: $FLAG" "$EVIDENCE_FILE"; then
        echo "[✅] Day 25 Selesai."
    else
        echo "[❌] Day 25 Gagal."
    fi
}

setup_day_26() {
    echo "[*] Setup Day 26: Network Monitoring..."
    local USER="$USER_STD"
    local HOME_DIR="$BASE_ROOT/$USER"
    local BASE_DIR="$HOME_DIR/linuxzoo"
    local HOSTS_FILE="/etc/hosts"
    local FLAG="BEE{network_baseline_verified}"

    rm -rf "$BASE_DIR/day26" 2>/dev/null || true
    mkdir -p "$BASE_DIR/day26"

    # Backup hosts
    cp "$HOSTS_FILE" "${HOSTS_FILE}.bak.day26" 2>/dev/null || true
    
    # Remove old day26 entries if any to keep it clean before adding
    sed -i '/LinuxZoo Day 26/,/linuxzoo-monitor.internal/d' "$HOSTS_FILE" 2>/dev/null || true

    cat >> "$HOSTS_FILE" << EOF

# === LinuxZoo Day 26: Network Audit Entry ===
# Purpose: Baseline verification tag for monitoring exercise
# DO NOT REMOVE - Required for audit compliance
# AUDIT_DNS: $FLAG
127.0.0.1   linuxzoo-monitor.internal
EOF

    cat > "$BASE_DIR/day26/clue.md" << 'EOF'
# Day 26: Arus Peruvian
Peruvian tidak mengabaikan perubahan kecil dalam arus jaringan.
Konfigurasi DNS lokal menyimpan catatan audit untuk verifikasi baseline.
Periksa koneksi aktif, lalu baca file mapping hostname sistem.
Jejak verifikasi auditor tersimpan di baris komentar file tersebut.
EOF

    chown -R "$USER:$USER" "$BASE_DIR"

    if grep -q "AUDIT_DNS: $FLAG" "$HOSTS_FILE"; then
        echo "[✅] Day 26 Selesai."
    else
        echo "[❌] Day 26 Gagal."
    fi
}

setup_day_27() {
    echo "[*] Setup Day 27: Storage Management..."
    local USER="$USER_PINGU"
    local HOME_DIR="$BASE_ROOT/$USER"
    local BASE_DIR="$HOME_DIR/linuxzoo"
    local PRACTICE_DIR="$BASE_DIR/day27/practice"
    local AUDIT_LOG="/var/log/linuxzoo/day27_audit.log"
    local FLAG="BEE{storage_cleanup_verified}"

    # 1. Bersihkan & Siapkan Direktori Latihan (Idempotent)
    rm -rf "$BASE_DIR/day27" 2>/dev/null || true
    mkdir -p "$PRACTICE_DIR/archive"

    # Buat file dummy untuk latihan cleanup
    dd if=/dev/urandom of="$PRACTICE_DIR/large_data.bin" bs=1M count=2 2>/dev/null
    echo "Current active log entry" > "$PRACTICE_DIR/current.log"
    cat > "$PRACTICE_DIR/archive/old_syslog.1" << 'EOF'
Apr 19 10:00:00 shinobee kernel: [12345.678] Old log entry - rotated
Apr 19 10:01:00 shinobee systemd[1]: Started Daily Cleanup.
EOF
    touch -d "10 days ago" "$PRACTICE_DIR/archive/old_syslog.1"

    # 2. Setup Direktori Log Sistem (FIX: Buka permission directory)
    mkdir -p /var/log/linuxzoo
    chmod 755 /var/log/linuxzoo  # PENTING: User butuh 'x' untuk traverse directory

    # 3. Tanam Flag di File Audit Sistem
    cat > "$AUDIT_LOG" << EOF
=== LinuxZoo Day 27: Storage Audit Log ===
Timestamp: $(date -Iseconds)
Auditor: automated-setup
Purpose: Verify storage management exercise completion
Storage Cleanup Verification: $FLAG
EOF

    # FIX: Gunakan root:root + 644 agar pasti readable oleh user manapun
    # Tanpa bergantung pada cache grup 'adm' yang mungkin belum aktif
    chmod 644 "$AUDIT_LOG"
    chown root:root "$AUDIT_LOG"

    # 4. Buat Clue
    cat > "$BASE_DIR/day27/clue.md" << 'EOF'
# Day 27: Gudang Pingu
Pingu tidak membiarkan gudang berantakan. Ia pilah mana yang lama, mana yang masih aktif.
EOF

    # 5. Set Ownership Direktori Latihan
    chown -R "$USER:$USER" "$BASE_DIR"

    # 6. Verifikasi Otomatis
    if [ -f "$AUDIT_LOG" ] && grep -q "$FLAG" "$AUDIT_LOG" 2>/dev/null; then
        # Cek tambahan: pastikan user pingu benar-benar bisa membaca file tersebut
        if su - "$USER" -c "test -r $AUDIT_LOG" &>/dev/null; then
            echo "[✅] Day 27 Selesai."
        else
            echo "[⚠️] Day 27: Flag tertanam, tapi user '$USER' mungkin belum bisa membaca (cek grup/permission)."
        fi
    else
        echo "[❌] Day 27 Gagal."
    fi
}

setup_day_28() {
    echo "[*] Setup Day 28: Symbolic Links..."
    local USER="$USER_PINGU"
    local HOME_DIR="$BASE_ROOT/$USER"
    local BASE_DIR="$HOME_DIR/linuxzoo"
    local USER_SCRIPTS_DIR="$HOME_DIR/scripts"
    local APP_CONFIG_DIR="/opt/app/config"
    local APP_CONFIG_FILE="$APP_CONFIG_DIR/settings.ini"
    local PRACTICE_DIR="$BASE_DIR/day28/links_practice"
    local FLAG_TARGET_DIR="/opt/linuxzoo/day28/verification"
    local FLAG_FILE="$FLAG_TARGET_DIR/audit_flag.txt"
    local BROKEN_LINK="$PRACTICE_DIR/verification_link"
    local FLAG="BEE{symbolic_links_verified}"

    rm -rf "$BASE_DIR/day28" 2>/dev/null || true
    rm -rf "$FLAG_TARGET_DIR" 2>/dev/null || true
    rm -rf "$APP_CONFIG_DIR" 2>/dev/null || true
    rm -rf "$USER_SCRIPTS_DIR" 2>/dev/null || true
    mkdir -p "$PRACTICE_DIR" "$FLAG_TARGET_DIR" "$APP_CONFIG_DIR" "$USER_SCRIPTS_DIR"

    cat > "$APP_CONFIG_FILE" << 'EOF'
# Application Settings
server=localhost
port=8080
debug=false
log_level=info
EOF
    chmod 644 "$APP_CONFIG_FILE"
    chown root:root "$APP_CONFIG_FILE"

    cat > "$FLAG_FILE" << EOF
=== LinuxZoo Day 28: Symbolic Link Verification ===
Timestamp: $(date -Iseconds)
Auditor: automated-setup
Exercise: Broken link detection & correct symlink creation
Link Management Verification: $FLAG
EOF
    chmod 644 "$FLAG_FILE"
    chown root:adm "$FLAG_FILE"

    ln -s "/wrong/path/flag.txt" "$BROKEN_LINK"

    cat > "$BASE_DIR/day28/clue.md" << 'EOF'
# Day 28: Jejak Pingu
Pingu menggunakan jejak pintar untuk navigasi, tapi jejak yang tujuannya hilang harus dibersihkan.
Latihan ada di ~/linuxzoo/day28/links_practice/
1. Temukan symbolic link yang rusak (broken) di folder tersebut menggunakan find.
2. Hapus broken link tersebut.
3. Buat symbolic link baru bernama 'verification_link' yang menunjuk ke:
   /opt/linuxzoo/day28/verification/audit_flag.txt
4. Akses flag melalui symlink yang baru kamu buat.
EOF

    chown -R "$USER:$USER" "$HOME_DIR"
    chown -hR "$USER:$USER" "$BASE_DIR"

    if [ -f "$APP_CONFIG_FILE" ] && [ -f "$FLAG_FILE" ] && [ -L "$BROKEN_LINK" ] && ! [ -e "$BROKEN_LINK" ]; then
        echo "[✅] Day 28 Selesai."
    else
        echo "[❌] Day 28 Gagal."
    fi
}

setup_day_29() {
    echo "[*] Setup Day 29: Network Audit..."
    local USER="$USER_PINGU"
    local HOME_DIR="$BASE_ROOT/$USER"
    local BASE_DIR="$HOME_DIR/linuxzoo"
    local PRACTICE_DIR="$BASE_DIR/day29"
    local SYSCTL_FILE="/etc/sysctl.d/99-network-hardening.conf"
    local FLAG="BEE{network_hygiene_verified}"

    rm -rf "$BASE_DIR/day29" 2>/dev/null || true
    mkdir -p "$PRACTICE_DIR"

    cat > "$SYSCTL_FILE" << EOF
# LinuxZoo Network Hardening Parameters
# Applied: $(date -Iseconds)
net.ipv4.ip_forward = 0
net.ipv4.tcp_syncookies = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.conf.all.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0
net.ipv4.icmp_ignore_bogus_error_responses = 1
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1
# AUDIT_NETWORK_BASELINE: $FLAG
EOF

    chmod 644 "$SYSCTL_FILE"
    chown root:root "$SYSCTL_FILE"

    cat > "$PRACTICE_DIR/clue.md" << 'EOF'
# Day 29: Audit Sinyal Pingu
Pingu memastikan hanya sinyal terpercaya yang diterima.
EOF

    chown -R "$USER:$USER" "$BASE_DIR"

    if [ -f "$SYSCTL_FILE" ] && grep -q "AUDIT_NETWORK_BASELINE: $FLAG" "$SYSCTL_FILE"; then
        echo "[✅] Day 29 Selesai."
    else
        echo "[❌] Day 29 Gagal."
    fi
}

setup_day_30() {
    echo "[*] Setup Day 30: Capstone..."
    local STUDENT_USER="$USER_PINGU"
    local HOME_DIR="$BASE_ROOT/$STUDENT_USER"
    local BASE_DIR="$HOME_DIR/linuxzoo"
    local PRACTICE_DIR="$BASE_DIR/day30"
    local LOG_DIR="/var/log/linuxzoo"
    local FLAG_FILE="$LOG_DIR/capstone-flag.log"
    local FLAG="BEE{congrats_you_are_now_a_linux_curator}"

    rm -rf "$BASE_DIR/day30" 2>/dev/null || true
    rm -rf "$LOG_DIR" 2>/dev/null || true
    mkdir -p "$PRACTICE_DIR" "$LOG_DIR"

    echo "$FLAG" > "$FLAG_FILE"
    chmod 444 "$FLAG_FILE"
    chown root:root "$FLAG_FILE"

    cat > "$PRACTICE_DIR/system-health-check.sh" << 'TEMPLATE'
#!/bin/bash
# LinuxZoo System Health Monitor - TEMPLATE
set -euo pipefail
LOG_FILE="/var/log/linuxzoo/system-health-$(date +%Y%m%d).log"
mkdir -p "$(dirname "$LOG_FILE")"

# TODO 1: Implement check_disk()
# TODO 2: Implement check_memory() & check_processes()
# TODO 3: Implement check_security()
# TODO 4: Implement check_network()
# TODO 5: Implement main() execution flow
main "$@"
TEMPLATE

    chown -R "$STUDENT_USER:$STUDENT_USER" "$HOME_DIR"
    chown "$STUDENT_USER:$STUDENT_USER" "$PRACTICE_DIR/system-health-check.sh"
    chmod 644 "$PRACTICE_DIR/system-health-check.sh"
    chown "$STUDENT_USER:$STUDENT_USER" "$LOG_DIR"
    chmod 755 "$LOG_DIR"

    if [ -d "$LOG_DIR" ] && [ -f "$PRACTICE_DIR/system-health-check.sh" ] && [ -f "$FLAG_FILE" ]; then
        echo "[✅] Day 30 Selesai."
    else
        echo "[❌] Day 30 Gagal."
    fi
}

# --- EKSEKUSI SETUP ---
setup_day_16
setup_day_17
setup_day_18
setup_day_19
setup_day_20
setup_day_21
setup_day_22
setup_day_23
setup_day_24
setup_day_25
setup_day_26
setup_day_27
setup_day_28
setup_day_29
setup_day_30

echo "=================================================="
echo "[✅] SEMUA SETUP DAY 16-30 SELESAI!"
echo "=================================================="
