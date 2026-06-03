<p align="center">
  <img src="header.svg" alt="Frida Mobile Setup Banner" width="800">
</p>

# Frida-Mobile-Setup 📱🛡️

A comprehensive automated setup for Mobile Pentesting on **Android** and **iOS**. This repository provides scripts to automate certificate injection, configure proxies, and bypass SSL pinning using Frida.

## 🚀 Features
- **Universal SSL Pinning Bypass:** Multi-layered Frida script targeting Android (Java) and iOS (Objective-C).
- **Automated Android Cert Injection:** Downloads and installs Burp Suite CA as a System Trusted credential (bypassing Android 7+ restrictions).
- **Cross-Platform Support:** Single script handles both platforms with auto-detection.
- **Connectivity Bypass:** Fakes "Connected" status in `ConnectivityManager` (Android) to resolve "No Internet" errors.
- **Persistent Proxy & DNS:** Configures standard interception defaults.

## 📁 Repository Structure
```text
Frida-Mobile-Setup/
├── setup.sh       # Environment setup (Proxy, Certs, Frida-Server)
├── bypass.js      # Universal SSL & Connectivity Bypass (Android/iOS)
├── run_bypass.sh  # Helper to launch ANY app with Frida
└── README.md      # Documentation
```

## 🛠️ Installation & Usage

### 1. Initial Environment Setup
Connect your device via USB and run the setup script:
```bash
./setup.sh
```
*Note: For iOS, ensure the device is jailbroken and `frida-server` is installed via Cydia/Sileo.*

### 2. Bypassing Any Application
Launch any app by its package name (Android) or Bundle ID (iOS). This will bypass SSL pinning and connectivity checks:
```bash
# Android Example:
./run_bypass.sh com.android.chrome

# iOS Example:
./run_bypass.sh com.apple.mobilesafari
```

## 🍏 iOS Specific Instructions

### Certificate Installation
Automatic injection is not supported on iOS due to trust store encryption.
1. Configure your device to use Burp Suite as a proxy.
2. Navigate to `http://burp` in Safari.
3. Download and install the Configuration Profile.
4. Go to **Settings > General > About > Certificate Trust Settings** and enable "Full Trust" for the Burp CA.

### Frida Setup
Ensure you have the latest `frida-server` installed on your jailbroken device. You can verify connectivity with:
```bash
frida-ls-devices
```

## 🤖 Android Technical Workflow
The `setup.sh` script performs a volatile system injection using a `tmpfs` bind-mount. This allows us to write to the read-only `/system/etc/security/cacerts/` directory without permanently modifying the system image. It also blocks **QUIC (UDP/443)** to force all traffic through the HTTP proxy.

## ⚖️ Disclaimer
This project is for educational and authorized security testing purposes only.
