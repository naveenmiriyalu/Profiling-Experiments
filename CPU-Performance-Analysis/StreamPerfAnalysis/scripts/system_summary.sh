#!/usr/bin/env bash
set -u

output_file="${1:-system_summary_$(hostname)_$(date -u +%Y%m%dT%H%M%SZ).txt}"

exec > >(tee "$output_file") 2>&1

section() {
    printf '\n===== %s =====\n' "$1"
}

run() {
    printf '\n$'
    printf ' %q' "$@"
    printf '\n'
    "$@" 2>&1 || true
}

section "Run metadata"
run date -u
run hostname
run uname -a

section "Operating system"
if [[ -r /etc/os-release ]]; then
    run cat /etc/os-release
fi

section "CPU summary"
run lscpu

section "CPU, core, socket, and NUMA mapping"
run lscpu -e=CPU,NODE,SOCKET,CORE,ONLINE

section "Cache summary"
run lscpu -C
for index in /sys/devices/system/cpu/cpu0/cache/index*; do
    [[ -d "$index" ]] || continue
    printf '%s: level=%s type=%s size=%s shared_cpu_list=%s\n' \
        "$(basename "$index")" \
        "$(<"$index/level")" \
        "$(<"$index/type")" \
        "$(<"$index/size")" \
        "$(<"$index/shared_cpu_list")"
done

section "NUMA topology"
if command -v numactl >/dev/null 2>&1; then
    run numactl --hardware
else
    echo "numactl is not installed"
fi

section "Memory capacity"
run free -h
run grep -E 'MemTotal|HugePages|Hugepagesize' /proc/meminfo

section "DIMM population and configured speed"
if [[ $EUID -eq 0 ]]; then
    dmidecode --type 17 2>/dev/null |
        grep -E '^[[:space:]]+(Size|Locator|Bank Locator|Type|Speed|Configured Memory Speed|Rank):' || true
elif sudo -n true 2>/dev/null; then
    sudo -n dmidecode --type 17 2>/dev/null |
        grep -E '^[[:space:]]+(Size|Locator|Bank Locator|Type|Speed|Configured Memory Speed|Rank):' || true
else
    echo "Run this script with sudo to include DIMM details"
fi

section "CPU frequency controls"
for item in scaling_driver scaling_governor scaling_min_freq scaling_max_freq; do
    path="/sys/devices/system/cpu/cpu0/cpufreq/$item"
    [[ -r "$path" ]] && printf '%s: %s\n' "$item" "$(<"$path")"
done

section "Compiler and analysis tools"
for tool in gcc clang numactl numastat perf pcm-memory pcm-power likwid-perfctr vtune; do
    if command -v "$tool" >/dev/null 2>&1; then
        printf '%-18s %s\n' "$tool" "$(command -v "$tool")"
    else
        printf '%-18s %s\n' "$tool" "NOT FOUND"
    fi
done

printf '\nSummary saved to: %s\n' "$output_file"
