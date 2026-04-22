#!/bin/bash
# ============================================
# LinuxZoo Part 1: Auto-Validator & Debugger
# Mensimulasikan langkah student per Day 01-15
# ============================================

USER="user"
HOME="/home/$USER"
PASS=0
FAIL=0

echo "🚀 Memulai Validasi Flow Student (Day 01-15)..."
echo "================================================"

# Helper: Jalankan command sebagai user & cek flag
check_as_user() {
    local day=$1
    local cmd=$2
    # su - user -c sudah menjalankan login shell (otomatis source .bashrc/.profile)
    local output=$(su - "$USER" -c "bash -l -c \"$cmd\"" 2>&1)
    
    if echo "$output" | grep -q "BEE{"; then
        echo "[✅ PASS] Day $day"
        ((PASS++))
    else
        echo "[❌ FAIL] Day $day"
        echo "   🛠 Command: $cmd"
        echo "   📉 Output/Error: $output"
        ((FAIL++))
    fi
}

# Helper: Jalankan command sebagai root (untuk permission/switch user)
check_as_root() {
    local day=$1
    local cmd=$2
    local output=$(eval "$cmd" 2>&1)
    
    if echo "$output" | grep -q "BEE{"; then
        echo "[✅ PASS] Day $day"
        ((PASS++))
    else
        echo "[❌ FAIL] Day $day"
        echo "   🛠 Command: $cmd"
        echo "   📉 Output/Error: $output"
        ((FAIL++))
    fi
}

# ==========================================
# DAY-BY-DAY VALIDATION
# ==========================================

# D01: Navigasi Hidden Folder
check_as_user 01 "cat ~/linuxzoo/day01/.jejak_emperor/flag.txt"

# D02: Dokumentasi (--help)
check_as_user 02 "adelie-guide --help | grep BEE"

# D03: Manipulasi File (Concat 3 part)
check_as_user 03 "cat ~/linuxzoo/day03/.sarang_gentoo/part1.txt ~/linuxzoo/day03/.sarang_gentoo/part2.txt ~/linuxzoo/day03/.sarang_gentoo/part3.txt"

# D04: Pencarian Data (Grep di file locate)
check_as_user 04 "grep BEE /opt/archives/chinstrap_logs.txt"

# D05: Pipeline Log (Wildcard grep)
check_as_user 05 "grep king /var/log/auth_king_*.log 2>/dev/null"

# D06: Hidden Config File (~/.bashrc)
check_as_user 06 "grep BEE ~/.bashrc"

# D07: User Switch (Simulasi su - rockhopper -> cat)
# runuser menghindari prompt password interaktif
check_as_root 07 "runuser -u rockhopper -- cat /home/rockhopper/.access_log"

# D08: Permission Change (chmod 000 -> 644 -> cat -> kembalikan ke 000)
check_as_root 08 "chmod 644 /opt/northern_vault/access.key; cat /opt/northern_vault/access.key; chmod 000 /opt/northern_vault/access.key"

# D09: SSH Key Comment
check_as_user 09 "grep BEE ~/.ssh/hoiho_key.pub"

# D10: Env Variables Concat (sudah di-load via login shell)
check_as_user 10 "echo \${ZOO_ROUTE_START}\${ZOO_ROUTE_END}"

# D11: FHS /etc/motd
check_as_user 11 "grep BEE /etc/motd"

# D12: Text Processing Pipeline (grep -> awk -> sort -> tr)
check_as_user 12 "grep 'erect\[' /var/log/erect_audit.log | awk -F'=' '{print \$2}' | sort | tr -d '\n'"

# D13: Tar Extract & Read Manifest
check_as_root 13 "mkdir -p /tmp/val_d13 && tar -xzf /var/backups/african_archive.tar.gz -C /tmp/val_d13 && cat /tmp/val_d13/configs/backup_manifest.txt && rm -rf /tmp/val_d13"

# D14: Process Monitoring (ps aux | grep)
check_as_user 14 "ps aux | grep humboldt | grep -v grep | grep BEE"

# D15: Service Management (Baca unit file)
check_as_user 15 "grep BEE /etc/systemd/system/magellanic-audit.service"

# ==========================================
# FINAL REPORT
# ==========================================
echo "================================================"
echo "🏁 HASIL AKHIR: $PASS Pass | $FAIL Fail"
echo "================================================"
if [ $FAIL -eq 0 ]; then
    echo "🎉 SEMUA FLOW LULUS! Room siap deploy ke student."
else
    echo "⚠️ Ada $FAIL task yang gagal. Lihat error di atas untuk debugging."
    echo "💡 Tip: Pastikan setup_all.sh sudah dijalankan dengan sudo, lalu coba ulang script ini."
fi
