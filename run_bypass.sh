#!/bin/bash
# Universal Frida Bypass Runner for Android & iOS
# This script launches any app with the SSL pinning bypass

PACKAGE_NAME=$1
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ -z "$PACKAGE_NAME" ]; then
    echo "Usage: ./run_bypass.sh <package_name_or_bundle_id>"
    echo "Example (Android): ./run_bypass.sh com.android.chrome"
    echo "Example (iOS):     ./run_bypass.sh com.apple.mobilesafari"
    exit 1
fi

echo "[*] Launching Frida bypass for: $PACKAGE_NAME"
echo "[*] Using universal script: $SCRIPT_DIR/bypass.js"

# Detect if any device is connected
frida-ls-devices | grep -q "usb"
if [ $? -ne 0 ]; then
    echo "[!] Error: No USB device detected via Frida."
    exit 1
fi

# Attempt to launch the app
frida -U -l "$SCRIPT_DIR/bypass.js" -f "$PACKAGE_NAME"
