#!/bin/bash

################################################################################
# FRIDA MOBILE SETUP - MASTER INSTALLATION SCRIPT
# Author: senukdias
# Repository: Frida-Mobile-Setup
################################################################################

# --- Configuration ---
BURP_HOST="127.0.0.1"
BURP_PORT="9090"
ADB_DEVICE="emulator-5554"
FRIDA_VERSION="17.9.10"

echo "[*] Starting Frida-Mobile-Setup Installation..."

# 1. BURP CERTIFICATE INSTALLATION
echo "[*] Step 1: Installing Burp Suite CA Certificate..."
# Using --noproxy to ensure we don't try to go through Burp to get the cert
curl -s --noproxy "*" -o cacert.der http://${BURP_HOST}:${BURP_PORT}/cert
if [ $? -ne 0 ]; then
    echo "[!] Error: Burp Suite not detected on ${BURP_HOST}:${BURP_PORT}"
    echo "    Make sure Burp is running and the listener 127.0.0.1:9090 is active."
    exit 1
fi

openssl x509 -inform DER -in cacert.der -out cacert.pem
HASH=$(openssl x509 -inform PEM -subject_hash_old -in cacert.pem | head -1)
CERT_FILE="${HASH}.0"
mv cacert.pem "$CERT_FILE"

# Inject into System Store with improved robustness
cat << 'EOF' > inject_cert.sh
CERT_FILE=$1
umount -l /system/etc/security/cacerts 2>/dev/null
mkdir -p /data/local/tmp/cacerts_backup
rm -f /data/local/tmp/cacerts_backup/*
cp /system/etc/security/cacerts/* /data/local/tmp/cacerts_backup/ 2>/dev/null || true
mount -t tmpfs tmpfs /system/etc/security/cacerts
cp /data/local/tmp/cacerts_backup/* /system/etc/security/cacerts/ 2>/dev/null || true
cp /sdcard/$CERT_FILE /system/etc/security/cacerts/
chown root:root /system/etc/security/cacerts/*
chmod 644 /system/etc/security/cacerts/*
chcon u:object_r:system_file:s0 /system/etc/security/cacerts/*
rm -rf /data/local/tmp/cacerts_backup
EOF

adb -s "$ADB_DEVICE" push "$CERT_FILE" /sdcard/ > /dev/null
adb -s "$ADB_DEVICE" push inject_cert.sh /data/local/tmp/ > /dev/null
adb -s "$ADB_DEVICE" shell "su -c 'sh /data/local/tmp/inject_cert.sh $CERT_FILE'"

rm cacert.der "$CERT_FILE" inject_cert.sh
echo "[+] Burp Certificate installed as System Trusted."

# 2. FRIDA SERVER INSTALLATION
echo "[*] Step 2: Installing/Updating Frida-Server ($FRIDA_VERSION)..."
ARCH=$(adb -s "$ADB_DEVICE" shell uname -m | tr -d '\r')
FRIDA_NAME="frida-server-$FRIDA_VERSION-android-$ARCH"

if [ ! -f "$FRIDA_NAME" ]; then
    echo "[*] Downloading Frida-Server..."
    curl -L -o "$FRIDA_NAME.xz" "https://github.com/frida/frida/releases/download/$FRIDA_VERSION/$FRIDA_NAME.xz"
    xz -d "$FRIDA_NAME.xz"
fi

adb -s "$ADB_DEVICE" push "$FRIDA_NAME" /data/local/tmp/frida-server
adb -s "$ADB_DEVICE" shell "chmod +x /data/local/tmp/frida-server"

# Restart Frida-server in background
echo "[*] Restarting Frida-server..."
adb -s "$ADB_DEVICE" shell "su -c 'killall frida-server 2>/dev/null || true'"
# Using a more standard Android backgrounding pattern
adb -s "$ADB_DEVICE" shell "su -c '(/data/local/tmp/frida-server >/dev/null 2>&1 &)'"
sleep 2

# Verify
FRIDA_PID=$(adb -s "$ADB_DEVICE" shell "ps -A | grep frida-server" | awk '{print $2}')
if [ -n "$FRIDA_PID" ]; then
    echo "[+] Frida-Server is running (PID: $FRIDA_PID)."
else
    echo "[!] Error: Frida-Server failed to start."
fi

# 3. NETWORK CONFIGURATION
echo "[*] Step 3: Configuring Network..."
# Use global DNS for the device
adb -s "$ADB_DEVICE" shell "su -c 'setprop net.dns1 8.8.8.8 && setprop net.dns2 8.8.4.4'"
# Force proxy
adb -s "$ADB_DEVICE" shell "settings put global http_proxy 10.0.2.2:9090"
# Block QUIC
adb -s "$ADB_DEVICE" shell "su -c 'iptables -F && iptables -I OUTPUT -p udp --dport 443 -j REJECT'"
echo "[+] Proxy, DNS, and Firewall configured."

echo ""
echo "################################################################################"
echo "# INSTALLATION COMPLETE"
echo "################################################################################"
