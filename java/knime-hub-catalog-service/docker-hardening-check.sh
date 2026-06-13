#!/bin/sh
# docker-hardening-check.sh
# Run inside a container to assess its security hardening.
# Note that some checks might be specific to my machine and exact devcontainer setup (e.g. docker-indocker), and may
# lead to false negatives in other configurations.

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

pass()  { printf "  ${GREEN}[PASS]${RESET} %s\n" "$1"; }
warn()  { printf "  ${YELLOW}[WARN]${RESET} %s\n" "$1"; }
fail()  { printf "  ${RED}[FAIL]${RESET} %s\n" "$1"; }
info()  { printf "  ${CYAN}[INFO]${RESET} %s\n" "$1"; }
header(){ printf "\n${BOLD}=== %s ===${RESET}\n" "$1"; }

# ---------------------------------------------------------------------------
header "1. Docker Socket"
# ---------------------------------------------------------------------------
# Strategy: a socket is dangerous if it controls a daemon whose storage root
# is bind-mounted FROM outside this container (i.e. it's the host daemon).
# A DinD inner daemon stores data on a regular VM/host block device that was
# NOT bind-mounted in — that's contained and safe.
#
# Detection logic per socket:
#   1. Is the socket present and live?
#   2. Ask the daemon for its DockerRootDir.
#   3. Look up that path in /proc/mounts.
#      - If the backing entry has a device path like /dev/vdX, /dev/sdX,
#        /dev/nvme*, or virtio* it's a real block device → inner DinD daemon.
#      - If the backing entry is an overlay, fuse, or has a mount source that
#        is itself a container path (e.g. starts with /var/lib/docker/... or
#        is of type fakeowner/virtiofs) → likely host socket bind-mounted in.
#      - If the root dir itself appears as a bind mount from outside → host socket.

is_dind_socket() {
    socket="$1"
    # Get the Docker root dir from the daemon
    if command -v curl >/dev/null 2>&1; then
        root_dir=$(curl -s --unix-socket "$socket" http://localhost/info 2>/dev/null \
            | grep -o '"DockerRootDir":"[^"]*"' \
            | sed 's/"DockerRootDir":"//;s/"//')
    elif command -v docker >/dev/null 2>&1; then
        root_dir=$(docker info --format '{{.DockerRootDir}}' 2>/dev/null)
    fi

    [ -z "$root_dir" ] && return 1  # can't determine — assume not DinD

    # Look up the mount entry for the root dir
    mount_entry=$(grep " $root_dir " /proc/mounts 2>/dev/null | tail -1)
    [ -z "$mount_entry" ] && mount_entry=$(grep " $root_dir\b" /proc/mounts 2>/dev/null | tail -1)

    if [ -n "$mount_entry" ]; then
        dev=$(echo "$mount_entry" | awk '{print $1}')
        fstype=$(echo "$mount_entry" | awk '{print $3}')

        # Block devices indicate a real disk (VM disk in Docker Desktop, or
        # a physical disk on Linux) — this is the inner DinD daemon's storage
        case "$dev" in
            /dev/vd*|/dev/sd*|/dev/nvme*|/dev/xvd*|/dev/hd*)
                return 0  # inner DinD — safe
                ;;
        esac

        # fakeowner / virtiofs are Docker Desktop's virtual FS for bind mounts
        # from the Mac host into the VM. If the docker root is on one of these,
        # the host's docker storage is being exposed — treat as host socket.
        case "$fstype" in
            fakeowner|virtiofs|fuse*)
                return 1  # host socket
                ;;
        esac

        # overlay on top of something else — could go either way, be cautious
        case "$fstype" in
            overlay)
                return 1
                ;;
        esac
    fi

    # Fallback: if root dir is the standard DinD path and nothing looks wrong
    case "$root_dir" in
        /var/lib/docker)
            return 0  # standard DinD path, probably fine
            ;;
    esac

    return 1  # can't confirm DinD — treat as potentially unsafe
}

SOCKET_PATHS="/var/run/docker.sock /run/docker.sock"
found_socket=0
for s in $SOCKET_PATHS; do
    if [ -e "$s" ]; then
        found_socket=1
        # Check if it's actually connectable
        live=0
        if command -v curl >/dev/null 2>&1; then
            resp=$(curl -s --unix-socket "$s" http://localhost/version 2>/dev/null)
            echo "$resp" | grep -q "Version" && live=1
        elif command -v docker >/dev/null 2>&1; then
            docker info >/dev/null 2>&1 && live=1
        fi

        if [ "$live" -eq 0 ]; then
            warn "Socket file exists at $s but is not responding (may be a proxy or stopped daemon)"
            continue
        fi

        # Socket is live — now determine if it's DinD or host
        if is_dind_socket "$s"; then
            pass "Docker socket at $s is live but scoped to inner DinD daemon (not host)"
            # Still report the root dir for transparency
            if command -v docker >/dev/null 2>&1; then
                root=$(docker info --format '{{.DockerRootDir}}' 2>/dev/null)
                info "  Inner daemon DockerRootDir: $root"
            fi
        else
            fail "Docker socket at $s appears to be the HOST daemon — container escape possible!"
            info "  Tip: use 'docker-in-docker' feature, not 'docker-outside-of-docker'"
        fi
    fi
done
[ "$found_socket" -eq 0 ] && pass "Docker socket not mounted"

# ---------------------------------------------------------------------------
header "2. Privileged Mode & Capabilities"
# ---------------------------------------------------------------------------

# Check for full capability set (privileged mode indicator)
if [ -f /proc/self/status ]; then
    cap_eff=$(grep '^CapEff:' /proc/self/status | awk '{print $2}')
    if [ "$cap_eff" = "000001ffffffffff" ] || [ "$cap_eff" = "0000003fffffffff" ]; then
        fail "Full capability set detected — container is likely running --privileged"
    else
        pass "Capability set is restricted (CapEff: $cap_eff)"
    fi

    # Check for specific dangerous capabilities
    # Parse CapEff as hex and test individual bits
    cap_int=$(printf "%d" "0x${cap_eff}" 2>/dev/null)

    check_cap() {
        bit=$1; name=$2
        if [ -n "$cap_int" ] && [ $(( (cap_int >> bit) & 1 )) -eq 1 ]; then
            warn "Capability present: $name"
        fi
    }

    check_cap 21 "CAP_SYS_ADMIN (very dangerous — allows remounting, namespaces)"
    check_cap 12 "CAP_NET_ADMIN (can manipulate network interfaces)"
    check_cap 27 "CAP_SYS_PTRACE (can ptrace host processes if pid namespace shared)"
    check_cap 7  "CAP_SETUID (can change to arbitrary UIDs)"
    check_cap 6  "CAP_SETGID (can change to arbitrary GIDs)"
fi

# ---------------------------------------------------------------------------
header "3. Running as Root"
# ---------------------------------------------------------------------------

uid=$(id -u)
if [ "$uid" -eq 0 ]; then
    warn "Running as root (UID 0) inside the container"
    info "Prefer a non-root user via USER in Dockerfile or --user flag"
else
    pass "Running as non-root user (UID $uid)"
fi

# ---------------------------------------------------------------------------
header "4. Sensitive Mounts"
# ---------------------------------------------------------------------------

SENSITIVE_PATHS="
/etc/shadow
/etc/sudoers
/root
/home
/proc/sysrq-trigger
/sys/firmware
/boot
"

for p in $SENSITIVE_PATHS; do
    p=$(echo "$p" | tr -d '[:space:]')
    [ -z "$p" ] && continue
    if [ -e "$p" ]; then
        warn "Sensitive path accessible: $p"
    fi
done

# Check /proc for host-level exposure
if [ -f /proc/1/environ ]; then
    # In a container, PID 1 is the container entrypoint
    # If we can see many PIDs, the pid namespace may be shared
    pid_count=$(ls /proc | grep -c '^[0-9]' 2>/dev/null || echo 0)
    if [ "$pid_count" -gt 50 ]; then
        warn "High PID count ($pid_count) — host PID namespace may be shared (--pid=host)"
    else
        pass "PID count looks container-scoped ($pid_count visible processes)"
    fi
fi

# ---------------------------------------------------------------------------
header "5. Mounted Volumes (from /proc/mounts)"
# ---------------------------------------------------------------------------

info "All mounts visible inside this container:"
if [ -f /proc/mounts ]; then
    # Filter out noise (cgroups, proc, sys, overlay image layers, tmpfs)
    grep -v '^\(overlay\|proc\|sysfs\|devpts\|tmpfs\|cgroup\|mqueue\|shm\|devtmpfs\)' /proc/mounts \
        | grep -v ' /proc ' | grep -v ' /sys ' | grep -v ' /dev ' \
        | while read -r dev mountpoint fstype opts _; do
            printf "    %-35s %-12s %s\n" "$mountpoint" "$fstype" "$opts"
        done
    # Highlight anything that looks like a host path bind mount
    echo ""
    info "Possible host bind-mounts (non-overlay, non-virtual):"
    grep -v '^\(overlay\|proc\|sysfs\|devpts\|tmpfs\|cgroup\|mqueue\|shm\|devtmpfs\)' /proc/mounts \
        | grep ' / ' -v \
        | grep -v ' /proc\b' | grep -v ' /sys\b' | grep -v ' /dev\b' \
        | while read -r dev mountpoint fstype opts _; do
            if [ "$fstype" = "ext4" ] || [ "$fstype" = "xfs" ] || [ "$fstype" = "btrfs" ] || [ "$fstype" = "bind" ] || echo "$opts" | grep -q "bind"; then
                warn "Bind mount: $mountpoint ($fstype, $opts)"
            else
                info "  $mountpoint ($fstype)"
            fi
        done
else
    warn "/proc/mounts not readable"
fi

# ---------------------------------------------------------------------------
header "6. Writable Filesystem"
# ---------------------------------------------------------------------------

if touch /test-write-$$ 2>/dev/null; then
    rm -f /test-write-$$
    warn "Root filesystem is writable — consider --read-only"
else
    pass "Root filesystem is read-only"
fi

# ---------------------------------------------------------------------------
header "7. Seccomp & AppArmor"
# ---------------------------------------------------------------------------

# Seccomp
if [ -f /proc/self/status ]; then
    seccomp=$(grep '^Seccomp:' /proc/self/status | awk '{print $2}')
    case "$seccomp" in
        0) warn "Seccomp is disabled (mode 0)" ;;
        1) pass "Seccomp strict mode enabled" ;;
        2) pass "Seccomp filter mode enabled" ;;
        *) info "Seccomp status unknown ($seccomp)" ;;
    esac
fi

# AppArmor
if [ -f /proc/self/attr/current ]; then
    aa=$(cat /proc/self/attr/current 2>/dev/null)
    if [ "$aa" = "unconfined" ] || [ -z "$aa" ]; then
        warn "AppArmor profile: unconfined"
    else
        pass "AppArmor profile active: $aa"
    fi
fi

# ---------------------------------------------------------------------------
header "8. Network Exposure"
# ---------------------------------------------------------------------------

if command -v ip >/dev/null 2>&1; then
    iface_count=$(ip link show 2>/dev/null | grep -c '^[0-9]')
    info "Network interfaces: $iface_count"
    ip -br addr show 2>/dev/null | while read -r line; do
        info "  $line"
    done
elif [ -f /proc/net/if_inet6 ] || [ -f /proc/net/fib_trie ]; then
    info "Network interfaces (from /proc/net/dev):"
    awk 'NR>2 {print "  " $1}' /proc/net/dev 2>/dev/null
fi

# Host network namespace check
# docker0 being visible does NOT mean --network=host when running DinD —
# the inner daemon creates its own docker0 bridge inside the container.
# The real signal for --network=host is seeing the host's physical/VM
# interfaces (e.g. eth0 with a host-range IP, or the host's lo address).
if ip link show 2>/dev/null | grep -q 'docker0'; then
    # Check if this looks like an inner DinD bridge or a leaked host bridge
    # by seeing whether we also have a normal container eth0
    if ip link show 2>/dev/null | grep -q 'eth0'; then
        pass "docker0 visible but eth0 also present — inner DinD bridge, not host network"
    else
        warn "docker0 visible without eth0 — possible --network=host, investigate further"
    fi
else
    pass "docker0 bridge not visible (not using host network)"
fi

# ---------------------------------------------------------------------------
printf "\n${BOLD}=== Done ===${RESET}\n\n"
printf "Legend: ${GREEN}[PASS]${RESET} good  ${YELLOW}[WARN]${RESET} review  ${RED}[FAIL]${RESET} serious issue  ${CYAN}[INFO]${RESET} informational\n\n"
