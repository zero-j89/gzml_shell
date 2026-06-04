#!/bin/sh
# apply-profile.sh <profile_dir> <cfg_dir>
# Atomically copies profile config files into the active config directory.
profile="$1"
cfg="$2"
[ -d "$profile" ] || { echo "Profile not found: $profile"; exit 1; }
[ -f "${profile}/settings.json" ] && \
    cp "${profile}/settings.json" "${cfg}settings.json.noctalia-tmp" && \
    mv -f "${cfg}settings.json.noctalia-tmp" "${cfg}settings.json" || true
[ -f "${profile}/colors.json" ] && \
    cp "${profile}/colors.json" "${cfg}colors.json.noctalia-tmp" && \
    mv -f "${cfg}colors.json.noctalia-tmp" "${cfg}colors.json" || true
[ -f "${profile}/plugins.json" ] && \
    cp "${profile}/plugins.json" "${cfg}plugins.json.noctalia-tmp" && \
    mv -f "${cfg}plugins.json.noctalia-tmp" "${cfg}plugins.json" || true
