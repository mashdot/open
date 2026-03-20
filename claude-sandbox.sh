#!/usr/bin/env bash

# claude-sandbox - Run Claude Code in a firejail sandbox
#
# Usage: claude-sandbox.sh [--with-build-tools] [claude args...]
#
# Provides filesystem isolation while allowing Claude to work autonomously.
# Claude can only access the current directory and its own configuration.
# Network access is enabled for API calls and MCP tools (e.g., ref.tools).
#
# Options:
#   --with-build-tools  Include gcc/g++/make/cmake and related binaries
#
# Notes:
#   ~/.ssh is NOT whitelisted — git-over-SSH won't work inside the sandbox.
#   Use HTTPS remotes, or accept the tradeoff of exposing private keys by
#   adding --whitelist/--read-only for ~/.ssh yourself.

set -euo pipefail

# Parse flags before passing through to claude
WITH_BUILD_TOOLS=0
PASSTHROUGH_ARGS=()
for arg in "$@"; do
    if [[ "$arg" == "--with-build-tools" ]]; then
        WITH_BUILD_TOOLS=1
    else
        PASSTHROUGH_ARGS+=("$arg")
    fi
done

# Check dependencies
if ! command -v firejail >/dev/null 2>&1; then
    echo "Error: firejail is not installed." >&2
    echo "  Arch: sudo pacman -S firejail" >&2
    echo "  Debian/Ubuntu: sudo apt install firejail" >&2
    echo "  Fedora: sudo dnf install firejail" >&2
    exit 1
fi

if ! command -v claude >/dev/null 2>&1; then
    echo "Error: claude CLI is not installed." >&2
    exit 1
fi

CURRENT_DIR="$(pwd)"

# Refuse to sandbox overly broad directories
if [[ "$CURRENT_DIR" == "$HOME" || "$CURRENT_DIR" == "/" ]]; then
    echo "Error: refusing to sandbox from ${CURRENT_DIR} (too broad — cd into a project directory)" >&2
    exit 1
fi

CLAUDE_PATH="$(readlink -f "$(which claude)")"

FIREJAIL_ARGS=(
    # Security hardening
    --caps.drop=all
    --nonewprivs
    --noroot
    --nogroups
    --nosound
    --no3d
    --private-tmp
    --private-dev
    --protocol=unix,inet,inet6
    --seccomp
    --nodbus
    --disable-mnt
    --hostname=sandbox
    --rlimit-nproc=200
    --rlimit-as=4294967296

    # Restrict /etc to essentials
    --private-etc=resolv.conf,hosts,passwd,group,nsswitch.conf,ssl,ca-certificates,localtime,hostname,ssh

    # Allowed binaries - shell and claude
    --private-bin=bash,sh,claude

    # Core utilities
    --private-bin=ls,cat,mkdir,cp,mv,rm,rmdir,touch,chmod,ln
    --private-bin=find,grep,egrep,fgrep,rg,sed,awk,cut,sort,uniq,head,tail,wc
    --private-bin=which,dirname,basename,pwd,echo,printf,env,test,true,false
    --private-bin=readlink,realpath,file,stat,du,df
    --private-bin=tr,tee,less,more,diff,patch,xargs,date,sleep,uname,id

    # Archive utilities
    --private-bin=tar,gzip,gunzip,bzip2,bunzip2,xz,unxz,zip,unzip

    # Version control
    --private-bin=git,ssh

    # Node.js
    --private-bin=node,npm,npx

    # Python
    --private-bin=python,python3,pip,pip3

    # Network
    --private-bin=curl

    # Filesystem whitelist
    --whitelist="${CURRENT_DIR}"
    --read-write="${CURRENT_DIR}"

    # Claude data
    --whitelist="${HOME}/.local/share/claude"
    --read-write="${HOME}/.local/share/claude"

    # Git config (read-only so sandbox can't alter identity/aliases)
    --whitelist="${HOME}/.gitconfig"
    --read-only="${HOME}/.gitconfig"

    # Package manager caches redirected to ephemeral /tmp to prevent cross-session poisoning
    --env=npm_config_cache=/tmp/npm-cache
    --env=PIP_CACHE_DIR=/tmp/pip-cache
)

# Claude configuration (if exists)
# Whitelisted read-write for conversation state, but sensitive config files
# are locked read-only to prevent prompt-injection persistence attacks.
[[ -d "${HOME}/.claude" ]] && FIREJAIL_ARGS+=(
    --whitelist="${HOME}/.claude"
    --read-write="${HOME}/.claude"
)
[[ -f "${HOME}/.claude/CLAUDE.md" ]] && FIREJAIL_ARGS+=(--read-only="${HOME}/.claude/CLAUDE.md")
[[ -f "${HOME}/.claude/settings.json" ]] && FIREJAIL_ARGS+=(--read-only="${HOME}/.claude/settings.json")
[[ -f "${HOME}/.claude/settings.local.json" ]] && FIREJAIL_ARGS+=(--read-only="${HOME}/.claude/settings.local.json")

[[ -f "${HOME}/.claude.json" ]] && FIREJAIL_ARGS+=(
    --whitelist="${HOME}/.claude.json"
    --read-only="${HOME}/.claude.json"
)

# Optionally include compiler toolchain (disabled by default to reduce attack surface)
if [[ $WITH_BUILD_TOOLS -eq 1 ]]; then
    FIREJAIL_ARGS+=(--private-bin=make,cmake,gcc,g++,cc,c++,ld,as,ar,strip,cc1,cc1plus,collect2)
    echo "Starting Claude in sandbox (${CURRENT_DIR}) [with build tools]"
else
    echo "Starting Claude in sandbox (${CURRENT_DIR})"
fi

# --dangerously-skip-permissions is intentional: the firejail sandbox replaces
# Claude's built-in permission layer with OS-level filesystem isolation.
exec firejail "${FIREJAIL_ARGS[@]}" "${CLAUDE_PATH}" --dangerously-skip-permissions "${PASSTHROUGH_ARGS[@]}"
