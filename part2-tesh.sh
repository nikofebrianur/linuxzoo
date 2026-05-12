#!/bin/bash
# =============================================================================
# LinuxZoo Test Suite - Day 16 to Day 30
# Menguji apakah user dapat mengakses dan mendapatkan flag sesuai challenge
# =============================================================================

set -o pipefail

# Warna output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Konfigurasi
USER_STD="user"
USER_PINGU="pingu"
PASS="pass123"
BASE_ROOT="/home"
TOTAL_TESTED=0
TOTAL_PASSED=0

# Helper Functions
log_info()    { echo -e "${YELLOW}[INFO]${NC} $1"; }
log_pass()    { echo -e "${GREEN}[PASS]${NC} $1"; ((TOTAL_PASSED++)); }
log_fail()    { echo -e "${RED}[FAIL]${NC} $1"; }
log_header()  { echo -e "\n${YELLOW}=== $1 ===${NC}"; }

run_as() {
    local user=$1
    local cmd=$2
    su - "$user" -c "$cmd" 2>/dev/null
}

run_as_sudo() {
    local user=$1
    local cmd=$2
    # Menggunakan sudo dengan password pass123
    echo "$PASS" | su - "$user" -c "echo '$PASS' | sudo -S $cmd" 2>/dev/null
}

extract_flag() {
    local text=$1
    echo "$text" | grep -oE 'BEE\{[^}]+\}' | head -1
}

# =============================================================================
# TEST CASES PER DAY
# =============================================================================

# --- DAY 16: Galapagos Backup ---
test_day_16() {
    log_header "Testing Day 16: Galapagos Backup"
    local result
    result=$(run_as "$USER_STD" "cat /opt/galap_configs/sshd_config.bak 2>/dev/null")
    local flag=$(extract_flag "$result")
    
    if [[ -n "$flag" ]]; then
        log_pass "Day 16: Flag ditemukan -> $flag"
    else
        log_fail "Day 16: Gagal mengambil flag dari backup file"
    fi
    ((TOTAL_TESTED++))
}

# --- DAY 17: Log Analysis ---
test_day_17() {
    log_header "Testing Day 17: Log Analysis"
    local p1 p2 p3 flag
    
    p1=$(run_as "$USER_STD" "grep 'PART_1=' /var/log/auth.log 2>/dev/null" | grep -oE 'BEE\{[^_]+')
    p2=$(run_as "$USER_STD" "grep 'PART_2=' /var/log/syslog 2>/dev/null" | grep -oE '[^=]+$' | tr -d ' ')
    p3=$(run_as "$USER_STD" "grep 'PART_3=' /var/log/kern.log 2>/dev/null" | grep -oE '[^=]+$' | tr -d ' ')
    
    # Simple concat check
    if [[ "$p1" == "BEE{log_analysis" && "$p2" == "master_" && "$p3" == "verified}" ]]; then
        flag="BEE{log_analysis_master_verified}"
        log_pass "Day 17: Flag terakit -> $flag"
    else
        log_fail "Day 17: Gagal merakit flag dari log parts"
    fi
    ((TOTAL_TESTED++))
}

# --- DAY 18: Package Audit ---
test_day_18() {
    log_header "Testing Day 18: Package Audit"
    local result flag
    result=$(run_as "$USER_STD" "cat /etc/apt/apt.conf.d/99-white-audit.conf 2>/dev/null")
    flag=$(extract_flag "$result")
    
    if [[ -n "$flag" ]]; then
        log_pass "Day 18: Flag ditemukan -> $flag"
    else
        log_fail "Day 18: Gagal mengambil flag dari apt config"
    fi
    ((TOTAL_TESTED++))
}

# --- DAY 19: Secure Crontab ---
test_day_19() {
    log_header "Testing Day 19: Secure Crontab"
    # Student harus: edit crontab ke */1, tunggu, lalu cat log
    # Untuk test: kita trigger manual script-nya via sudo
    
    local log_file="/home/$USER_STD/.royal_audit.log"
    
    # Trigger script via sudo (simulasi cron berjalan)
    run_as_sudo "$USER_STD" "/usr/local/bin/royal-audit.sh" >/dev/null 2>&1
    sleep 1
    
    local result flag
    result=$(run_as "$USER_STD" "cat $log_file 2>/dev/null")
    flag=$(extract_flag "$result")
    
    if [[ -n "$flag" ]]; then
        log_pass "Day 19: Flag ditemukan di log -> $flag"
    else
        log_fail "Day 19: Gagal mendapatkan flag (cron/script belum jalan?)"
    fi
    ((TOTAL_TESTED++))
}

# --- DAY 20: Bash Obfuscation ---
test_day_20() {
    log_header "Testing Day 20: Bash Obfuscation"
    local script="$BASE_ROOT/$USER_STD/linuxzoo/day20/eastern-recipe.sh"
    
    # Student harus: fix shebang, chmod +x, lalu run
    # Untuk test: kita lakukan fix dan run
    run_as_sudo "$USER_STD" "sed -i 's|#!/bin/dash|#!/bin/bash|' $script" 2>/dev/null
    run_as_sudo "$USER_STD" "chmod +x $script" 2>/dev/null
    
    local result flag
    result=$(run_as "$USER_STD" "$script 2>/dev/null")
    flag=$(extract_flag "$result")
    
    if [[ -n "$flag" ]]; then
        log_pass "Day 20: Flag terdekripsi -> $flag"
    else
        log_fail "Day 20: Gagal menjalankan script/dekripsi flag"
    fi
    ((TOTAL_TESTED++))
}

# --- DAY 21: Script Validation ---
test_day_21() {
    log_header "Testing Day 21: Script Validation"
    local script="$BASE_ROOT/$USER_STD/linuxzoo/day21/western-validator.sh"
    
    # Student harus: bash -n, fix syntax (tutup bracket base64), fix shebang, chmod +x, run
    # Fix 1: Tutup command substitution yang kurang
    run_as_sudo "$USER_STD" "sed -i 's|base64 -d 2>/dev/null$|base64 -d 2>/dev/null)|' $script" 2>/dev/null
    # Fix 2: Shebang
    run_as_sudo "$USER_STD" "sed -i 's|#!/bin/|#!/bin/bash|' $script" 2>/dev/null
    # Fix 3: Permission
    run_as_sudo "$USER_STD" "chmod +x $script" 2>/dev/null
    
    local result flag
    result=$(run_as "$USER_STD" "$script 2>/dev/null")
    flag=$(extract_flag "$result")
    
    if [[ -n "$flag" ]]; then
        log_pass "Day 21: Flag terdekripsi -> $flag"
    else
        log_fail "Day 21: Gagal menjalankan script setelah fix"
    fi
    ((TOTAL_TESTED++))
}

# --- DAY 22: UFW Firewall ---
test_day_22() {
    log_header "Testing Day 22: UFW Firewall"
    # Flag ada di syslog via logger, user bisa grep
    local result flag
    result=$(run_as "$USER_STD" "grep 'AUDIT_FLAG:' /var/log/syslog 2>/dev/null | tail -1")
    flag=$(extract_flag "$result")
    
    if [[ -n "$flag" ]]; then
        log_pass "Day 22: Flag ditemukan di syslog -> $flag"
    else
        log_fail "Day 22: Gagal menemukan flag di log sistem"
    fi
    ((TOTAL_TESTED++))
}

# --- DAY 23: System Hardening ---
test_day_23() {
    log_header "Testing Day 23: System Hardening"
    local result flag
    result=$(run_as "$USER_STD" "cat /etc/audit/rules.d/99-hardening.rules 2>/dev/null")
    flag=$(extract_flag "$result")
    
    if [[ -n "$flag" ]]; then
        log_pass "Day 23: Flag ditemukan di audit rules -> $flag"
    else
        log_fail "Day 23: Gagal mengambil flag dari audit config"
    fi
    ((TOTAL_TESTED++))
}

# --- DAY 24: Backup Strategy ---
test_day_24() {
    log_header "Testing Day 24: Backup Strategy"
    local src_dir="$BASE_ROOT/$USER_STD/linuxzoo/day24/data"
    
    # Student: rsync, verify sha256, lalu hash file -> BEE{hash}
    # Untuk test: hitung sha256 dari source file
    local hash
    hash=$(run_as "$USER_STD" "sha256sum $src_dir/otago_integrity.dat 2>/dev/null" | awk '{print $1}')
    
    if [[ -n "$hash" && "$hash" =~ ^[a-f0-9]{64}$ ]]; then
        local expected_flag="BEE{$hash}"
        log_pass "Day 24: Hash valid -> Flag: $expected_flag"
    else
        log_fail "Day 24: Gagal menghitung SHA256 atau format tidak valid"
    fi
    ((TOTAL_TESTED++))
}

# --- DAY 25: Incident Response ---
test_day_25() {
    log_header "Testing Day 25: Incident Response"
    local evidence="/tmp/.banded_trace.dat"
    local result flag
    
    # Student: find, stat, sha256sum, cat, lalu chmod 000
    result=$(run_as "$USER_STD" "cat $evidence 2>/dev/null")
    flag=$(extract_flag "$result")
    
    if [[ -n "$flag" ]]; then
        log_pass "Day 25: Flag ditemukan di evidence -> $flag"
        # Test containment (opsional)
        run_as_sudo "$USER_STD" "chmod 000 $evidence" 2>/dev/null && log_info "Day 25: Containment (chmod 000) berhasil"
    else
        log_fail "Day 25: Gagal membaca evidence file"
    fi
    ((TOTAL_TESTED++))
}

# --- DAY 26: Network Monitoring ---
test_day_26() {
    log_header "Testing Day 26: Network Monitoring"
    local result flag
    result=$(run_as "$USER_STD" "grep 'AUDIT_DNS:' /etc/hosts 2>/dev/null")
    flag=$(extract_flag "$result")
    
    if [[ -n "$flag" ]]; then
        log_pass "Day 26: Flag ditemukan di /etc/hosts -> $flag"
    else
        log_fail "Day 26: Gagal menemukan flag di hosts file"
    fi
    ((TOTAL_TESTED++))
}

# --- DAY 27: Storage Management (User: pingu) ---
test_day_27() {
    log_header "Testing Day 27: Storage Management"
    local audit_log="/var/log/linuxzoo/day27_audit.log"
    local result flag
    
    # Student: find old files, cleanup, lalu cat audit log
    result=$(run_as "$USER_PINGU" "cat $audit_log 2>/dev/null")
    flag=$(extract_flag "$result")
    
    if [[ -n "$flag" ]]; then
        log_pass "Day 27: Flag ditemukan di audit log -> $flag"
    else
        log_fail "Day 27: Gagal membaca audit log sistem"
    fi
    ((TOTAL_TESTED++))
}

# --- DAY 28: Symbolic Links (User: pingu) ---
test_day_28() {
    log_header "Testing Day 28: Symbolic Links"
    local practice_dir="$BASE_ROOT/$USER_PINGU/linuxzoo/day28/links_practice"
    local flag_target="/opt/linuxzoo/day28/verification/audit_flag.txt"
    local link_name="verification_link"
    local result flag
    
    # Student: find broken, rm, ln -s baru, cat via symlink
    # Test: langsung buat symlink benar dan cat
    run_as_sudo "$USER_PINGU" "rm -f $practice_dir/$link_name" 2>/dev/null
    run_as "$USER_PINGU" "ln -s $flag_target $practice_dir/$link_name 2>/dev/null"
    
    result=$(run_as "$USER_PINGU" "cat $practice_dir/$link_name 2>/dev/null")
    flag=$(extract_flag "$result")
    
    if [[ -n "$flag" ]]; then
        log_pass "Day 28: Flag diakses via symlink -> $flag"
    else
        log_fail "Day 28: Gagal mengakses flag via symbolic link"
    fi
    ((TOTAL_TESTED++))
}

# --- DAY 29: Network Audit (User: pingu) ---
test_day_29() {
    log_header "Testing Day 29: Network Audit"
    local sysctl_file="/etc/sysctl.d/99-network-hardening.conf"
    local result flag
    
    result=$(run_as "$USER_PINGU" "cat $sysctl_file 2>/dev/null")
    flag=$(extract_flag "$result")
    
    if [[ -n "$flag" ]]; then
        log_pass "Day 29: Flag ditemukan di sysctl config -> $flag"
    else
        log_fail "Day 29: Gagal mengambil flag dari hardening config"
    fi
    ((TOTAL_TESTED++))
}

# --- DAY 30: Capstone (User: pingu) ---
test_day_30() {
    log_header "Testing Day 30: Capstone"
    local flag_file="/var/log/linuxzoo/capstone-flag.log"
    local result flag
    
    # Capstone: student isi script, run, flag muncul
    # Untuk test: langsung baca flag file (karena flag sudah ditanam)
    result=$(run_as "$USER_PINGU" "cat $flag_file 2>/dev/null")
    flag=$(extract_flag "$result")
    
    if [[ -n "$flag" ]]; then
        log_pass "Day 30: Capstone flag -> $flag"
    else
        log_fail "Day 30: Gagal membaca capstone flag"
    fi
    ((TOTAL_TESTED++))
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
    echo "============================================================"
    echo "  LinuxZoo Automated Test Suite (Day 16-30)"
    echo "  Users: '$USER_STD' (Day 16-26), '$USER_PINGU' (Day 27-30)"
    echo "============================================================"
    
    # Cek user ada
    if ! id "$USER_STD" &>/dev/null || ! id "$USER_PINGU" &>/dev/null; then
        echo -e "${RED}[ERROR] User 'user' atau 'pingu' tidak ditemukan!${NC}"
        echo "Jalankan setup script terlebih dahulu."
        exit 1
    fi
    
    # Run tests Day 16-26 (user)
    test_day_16
    test_day_17
    test_day_18
    test_day_19
    test_day_20
    test_day_21
    test_day_22
    test_day_23
    test_day_24
    test_day_25
    test_day_26
    
    # Run tests Day 27-30 (pingu)
    test_day_27
    test_day_28
    test_day_29
    test_day_30
    
    # Summary
    echo -e "\n============================================================"
    echo "  TEST SUMMARY"
    echo "============================================================"
    echo -e "Total Tested : $TOTAL_TESTED"
    echo -e "${GREEN}Passed     : $TOTAL_PASSED${NC}"
    echo -e "${RED}Failed     : $((TOTAL_TESTED - TOTAL_PASSED))${NC}"
    
    if [[ $TOTAL_PASSED -eq $TOTAL_TESTED ]]; then
        echo -e "\n${GREEN}🎉 ALL TESTS PASSED! LinuxZoo setup verified. 🎉${NC}"
        exit 0
    else
        echo -e "\n${YELLOW}⚠️  Some tests failed. Please review setup.${NC}"
        exit 1
    fi
}

# Run main
main "$@"
