#!/usr/bin/env bash
set -euo pipefail

echo "===== Intel System Summary ====="

CPU_MODEL=$(lscpu | awk -F: '/Model name/ {gsub(/^[ \t]+/,"",$2); print $2; exit}')
SOCKETS=$(lscpu | awk -F: '/Socket\(s\)/ {gsub(/[ \t]/,"",$2); print $2; exit}')
CORES_PER_SOCKET=$(lscpu | awk -F: '/Core\(s\) per socket/ {gsub(/[ \t]/,"",$2); print $2; exit}')
THREADS_PER_CORE=$(lscpu | awk -F: '/Thread\(s\) per core/ {gsub(/[ \t]/,"",$2); print $2; exit}')
TOTAL_CORES=$((SOCKETS * CORES_PER_SOCKET))
TOTAL_THREADS=$(nproc --all)
MAX_MHZ=$(lscpu | awk -F: '/CPU max MHz/ {gsub(/^[ \t]+/,"",$2); print $2; exit}')
AVG_MHZ=$(awk '/cpu MHz/ {sum+=$4; count++} END {if (count) printf "%.1f", sum/count; else print "Unknown"}' /proc/cpuinfo)
TOTAL_MEM_GIB=$(awk '/MemTotal/ {printf "%.1f", $2/1024/1024}' /proc/meminfo)

printf "CPU model               : %s\n" "$CPU_MODEL"
printf "Sockets                 : %s\n" "$SOCKETS"
printf "Cores per socket        : %s\n" "$CORES_PER_SOCKET"
printf "Total physical cores    : %s\n" "$TOTAL_CORES"
printf "Threads per core        : %s\n" "$THREADS_PER_CORE"
printf "Total logical CPUs      : %s\n" "$TOTAL_THREADS"
printf "Average current MHz     : %s\n" "$AVG_MHZ"
printf "Maximum MHz reported    : %s\n" "${MAX_MHZ:-Unknown}"

echo
echo "===== DRAM Capacity and NUMA Topology ====="
printf "OS-visible DRAM         : %s GiB\n" "$TOTAL_MEM_GIB"

if command -v numactl >/dev/null 2>&1; then
    numactl --hardware
else
    echo "numactl is not installed"
fi

echo
echo "===== EDAC Memory Controllers ====="
EDAC_ROOT=/sys/devices/system/edac/mc
if [[ -d "$EDAC_ROOT" ]]; then
    mapfile -t EDAC_CONTROLLERS < <(find "$EDAC_ROOT" -maxdepth 1 -type d -name 'mc*' | sort -V)
    printf "Linux EDAC controllers exposed: %d\n" "${#EDAC_CONTROLLERS[@]}"
    printf "  %s\n" "${EDAC_CONTROLLERS[@]}"
else
    echo "EDAC memory-controller topology is not exposed"
fi

echo
echo "===== DIMM, Channel, and Theoretical Bandwidth ====="

if ! command -v dmidecode >/dev/null 2>&1; then
    echo "dmidecode is not installed" >&2
    exit 1
fi

if [[ $EUID -eq 0 ]]; then
    DMI_COMMAND=(dmidecode -t memory)
elif sudo -n true 2>/dev/null; then
    DMI_COMMAND=(sudo -n dmidecode -t memory)
else
    echo "Run as root or configure sudo access for dmidecode" >&2
    exit 1
fi

"${DMI_COMMAND[@]}" 2>/dev/null | awk -v sockets="$SOCKETS" '
function clear_record() {
    size_mib=0
    locator=""
    bank=""
    socket=""
    channel=""
    configured_speed=0
    rated_speed=0
}

function emit_record(    speed,key) {
    if (size_mib <= 0 || locator == "")
        return

    speed = configured_speed ? configured_speed : rated_speed
    if (socket == "")
        socket="unknown"
    if (channel == "")
        channel="unknown"

    dimm_count++
    total_mib += size_mib
    socket_mib[socket] += size_mib

    key=socket SUBSEP channel
    seen_channel[key]=1

    if (speed > 0) {
        if (!(key in channel_speed) || speed < channel_speed[key])
            channel_speed[key]=speed
        if (!(socket in min_speed) || speed < min_speed[socket])
            min_speed[socket]=speed
        if (speed > max_speed[socket])
            max_speed[socket]=speed
    }

    printf "DIMM %-2d Socket=%-7s Channel=%-7s Size=%7.1f GiB Speed=%-7s MT/s Locator=%s Bank=%s\n",         dimm_count, socket, channel, size_mib/1024, speed ? speed : "Unknown", locator, bank
}

BEGIN {
    dimm_count=0
    total_mib=0
    clear_record()
}

/^Handle / {
    emit_record()
    clear_record()
}

/^[ \t]*Size:/ {
    line=$0
    sub(/^[ \t]*Size:[ \t]*/, "", line)

    if (line ~ /No Module Installed/) {
        size_mib=0
    } else {
        split(line,a,/ +/)
        value=a[1]
        unit=a[2]
        if (unit == "TB" || unit == "TiB")
            size_mib=value * 1024 * 1024
        else if (unit == "GB" || unit == "GiB")
            size_mib=value * 1024
        else if (unit == "MB" || unit == "MiB")
            size_mib=value
    }
}

/^[ \t]*Locator:/ {
    locator=$0
    sub(/^[ \t]*Locator:[ \t]*/, "", locator)

    if (match(locator,/CPU[0-9]+/))
        socket=substr(locator,RSTART+3,RLENGTH-3)
    else if (match(locator,/P[1-9][0-9]*-/)) {
        platform_socket=substr(locator,RSTART+1,RLENGTH-2)
        socket=platform_socket-1
    }

    if (match(locator,/DIMM_[A-Z]/))
        channel=substr(locator,RSTART+5,1)
    else if (match(locator,/DIMM[A-Z]/))
        channel=substr(locator,RSTART+4,1)
}

/^[ \t]*Bank Locator:/ {
    bank=$0
    sub(/^[ \t]*Bank Locator:[ \t]*/, "", bank)
}

/^[ \t]*Configured Memory Speed:/ {
    line=$0
    sub(/^[ \t]*Configured Memory Speed:[ \t]*/, "", line)
    split(line,a,/ +/)
    if (a[1] ~ /^[0-9]+$/)
        configured_speed=a[1]
}

/^[ \t]*Speed:/ {
    line=$0
    sub(/^[ \t]*Speed:[ \t]*/, "", line)
    split(line,a,/ +/)
    if (a[1] ~ /^[0-9]+$/)
        rated_speed=a[1]
}

END {
    emit_record()

    print ""
    print "===== Memory Summary From dmidecode ====="
    printf "Populated DIMMs         : %d\n", dimm_count
    printf "Installed DRAM         : %.1f GiB\n", total_mib/1024

    for (key in seen_channel) {
        split(key,parts,SUBSEP)
        socket=parts[1]
        channel_count[socket]++

        if (key in channel_speed)
            socket_bw[socket] += channel_speed[key] * 8 / 1000
        else
            unknown_speed_channels[socket]++
    }

    total_bw=0
    for (socket=0; socket<sockets; socket++) {
        printf "\nSocket %d installed DRAM: %.1f GiB\n", socket, socket_mib[socket]/1024
        printf "Socket %d populated channels: %d\n", socket, channel_count[socket]

        if (min_speed[socket] > 0) {
            if (min_speed[socket] == max_speed[socket])
                printf "Socket %d configured speed: %d MT/s\n", socket, min_speed[socket]
            else
                printf "Socket %d configured speed range: %d-%d MT/s (check mixed configuration)\n",                     socket, min_speed[socket], max_speed[socket]
        }

        if (unknown_speed_channels[socket] == 0 && channel_count[socket] > 0) {
            printf "Socket %d theoretical bandwidth: %.1f GB/s\n", socket, socket_bw[socket]
            total_bw += socket_bw[socket]
        } else {
            printf "Socket %d theoretical bandwidth: unavailable\n", socket
        }
    }

    print ""
    if (total_bw > 0)
        printf "Theoretical system bandwidth: %.1f GB/s\n", total_bw
    else
        print "Theoretical system bandwidth: unavailable"

    print ""
    print "Formula: sum over populated channels (configured MT/s x 8 bytes / 1000)"
    print "Note: channel detection depends on the DIMM locator naming scheme."
}'
