#!/bin/bash
# Universal Frida Bypass Runner
# This script launches any app with the SSL pinning bypass

PACKAGE_NAME=${1:-com.android.chrome}
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "[*] Launching Frida bypass for: $PACKAGE_NAME"
echo "[*] Using script: $SCRIPT_DIR/bypass.js"

frida -U -l "$SCRIPT_DIR/bypass.js" -f "$PACKAGE_NAME"
