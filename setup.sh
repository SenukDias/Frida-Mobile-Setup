#!/bin/bash

################################################################################
# FRIDA MOBILE SETUP - UNIVERSAL INSTALLATION SCRIPT (Android & iOS)
# Author: senukdias
# Repository: Frida-Mobile-Setup
################################################################################

# --- Configuration ---
BURP_HOST="127.0.0.1"
BURP_PORT="9090"
FRIDA_VERSION="17.9.10"

echo "[*] Starting Frida-Mobile-Setup Installation..."

# --- Detect Platform ---
echo "[*] Detecting connected devices..."
ADB_DEVICES=$(adb devices | grep -w "device" | awk '{print $1}')
IOS_DEVICES=$(frida-ls-devices 2>/dev/null | grep "usb" | awk '{print $1}')

if [ -n "$ADB_DEVICES" ]; then
    PLATFORM="android"
    DEVICE_ID=$(echo "$ADB_DEVICES" | head -n 1)
    echo "[+] Found Android Device: $DEVICE_ID"
elif [ -n "$IOS_DEVICES" ]; then
    PLATFORM="ios"
    DEVICE_ID=$(echo "$IOS_DEVICES" | head -n 1)
    echo "[+] Found iOS Device: $DEVICE_ID"
else
    echo "[!] No devices found via ADB or Frida. Please connect a device via USB."
    exit 1
fi

# --- 1. BURP CERTIFICATE INSTALLATION ---
install_burp_cert() {
    echo "[*] Step 1: Preparing Burp Suite CA Certificate..."
    curl -s --noproxy "*" -o cacert.der http://${BURP_HOST}:${BURP_PORT}/cert
    if [ $? -ne 0 ]; then
        echo "[!] Error: Burp Suite not detected on ${BURP_HOST}:${BURP_PORT}"
        echo "    Make sure Burp is running and the listener is active."
        exit 1
    fi

    openssl x509 -inform DER -in cacert.der -out cacert.pem
    HASH=$(openssl x509 -inform PEM -subject_hash_old -in cacert.pem | head -1)
    CERT_FILE="${HASH}.0"
    mv cacert.pem "$CERT_FILE"

    if [ "$PLATFORM" == "android" ]; then
        echo "[*] Injecting cert into Android System Store (tmpfs mount)..."
        cat << 'EOF' > inject_cert.sh
CERT_FILE=$1
# Ensure we are root
if [ "$(id -u)" -ne 0 ]; then echo "Not root!"; exit 1; fi
umount -l /system/etc/security/cacerts 2>/dev/null
mkdir -p /data/local/tmp/cacerts_backup
cp /system/etc/security/cacerts/* /data/local/tmp/cacerts_backup/ 2>/dev/null
mount -t tmpfs tmpfs /system/etc/security/cacerts
cp /data/local/tmp/cacerts_backup/* /system/etc/security/cacerts/
cp /sdcard/$CERT_FILE /system/etc/security/cacerts/
chown root:root /system/etc/security/cacerts/*
chmod 644 /system/etc/security/cacerts/*
chcon u:object_r:system_file:s0 /system/etc/security/cacerts/*
EOF
        adb -s "$DEVICE_ID" push "$CERT_FILE" /sdcard/ > /dev/null
        adb -s "$DEVICE_ID" push inject_cert.sh /data/local/tmp/ > /dev/null
        adb -s "$DEVICE_ID" shell "su 0 sh /data/local/tmp/inject_cert.sh $CERT_FILE"
        echo "[+] Android: Burp Certificate installed as System Trusted."
    else
        echo "[!] iOS: Automatic System Cert injection is not supported."
        echo "    Please manually install the certificate:"
        echo "    1. Navigate to http://burp on the device."
        echo "    2. Download and install the Profile."
        echo "    3. Go to Settings > General > About > Certificate Trust Settings and enable full trust for Burp CA."
    fi
    rm -f cacert.der "$CERT_FILE" inject_cert.sh
}

# --- 2. FRIDA SERVER INSTALLATION ---
install_frida() {
    if [ "$PLATFORM" == "android" ]; then
        echo "[*] Step 2: Installing/Updating Frida-Server ($FRIDA_VERSION) for Android..."
        ABI=$(adb -s "$DEVICE_ID" shell getprop ro.product.cpu.abi | tr -d '\r')
        case $ABI in
            x86) ARCH="x86" ;;
            x86_64) ARCH="x86_64" ;;
            armeabi-v7a|armeabi) ARCH="arm" ;;
            arm64-v8a) ARCH="arm64" ;;
            *) ARCH=$ABI ;;
        esac
        
        FRIDA_NAME="frida-server-$FRIDA_VERSION-android-$ARCH"
        if [ ! -f "$FRIDA_NAME" ]; then
            echo "[*] Downloading Frida-Server for $ARCH..."
            curl -L -o "$FRIDA_NAME.xz" "https://github.com/frida/frida/releases/download/$FRIDA_VERSION/$FRIDA_NAME.xz"
            xz -d "$FRIDA_NAME.xz"
        fi

        adb -s "$DEVICE_ID" push "$FRIDA_NAME" /data/local/tmp/frida-server
        adb -s "$DEVICE_ID" shell "chmod +x /data/local/tmp/frida-server"
        adb -s "$DEVICE_ID" shell "su 0 killall frida-server 2>/dev/null || true"
        # Start frida-server in the background properly
        adb -s "$DEVICE_ID" shell "su 0 /data/local/tmp/frida-server" &
        sleep 3
        
        if adb -s "$DEVICE_ID" shell "ps -A | grep frida-server" >/dev/null; then
            echo "[+] Android: Frida-Server is running."
        else
            echo "[!] Android: Frida-Server failed to start."
        fi
    else
        echo "[*] Step 2: Checking Frida on iOS..."
        if frida-ps -U >/dev/null 2>&1; then
            echo "[+] iOS: Frida is ready on the device."
        else
            echo "[!] iOS: Frida not detected. Ensure frida-server is installed via Cydia/Sileo."
        fi
    fi
}

# --- 3. NETWORK CONFIGURATION ---
configure_network() {
    echo "[*] Step 3: Configuring Network..."
    if [ "$PLATFORM" == "android" ]; then
        adb -s "$DEVICE_ID" shell "settings put global http_proxy 10.0.2.2:$BURP_PORT"
        adb -s "$DEVICE_ID" shell "su 0 iptables -I OUTPUT -p udp --dport 443 -j REJECT 2>/dev/null"
        echo "[+] Android: Proxy set to 10.0.2.2:$BURP_PORT, QUIC blocked."
    else
        echo "[!] iOS: Manual proxy configuration required."
        echo "    Set Proxy to your host IP on port $BURP_PORT in Wi-Fi settings."
    fi
}

install_burp_cert
install_frida
configure_network

echo ""
echo "################################################################################"
echo "# INSTALLATION COMPLETE FOR $PLATFORM"
echo "################################################################################"
