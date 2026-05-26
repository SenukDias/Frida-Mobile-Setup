<p align="center">
  <img src="header.svg" alt="Frida Mobile Setup Banner" width="800">
</p>

# Frida-Mobile-Setup 📱🛡️

A comprehensive automated setup for Mobile Pentesting on Android Emulators. This repository provides scripts to automate the installation of Burp Suite certificates into the System store, configure global proxies, block QUIC to force interception, and bypass SSL pinning using Frida.

## 🚀 Features
- **Automated Cert Injection:** Downloads and installs Burp Suite CA as a System Trusted credential (bypassing Android 7+ restrictions).
- **Universal SSL Pinning Bypass:** Multi-layered Frida script targeting Conscrypt, OkHttp 3/4, TrustKit, WebView, and more.
- **Connectivity Bypass:** Fakes "Connected" status in `ConnectivityManager` to resolve "No Internet" errors during interception.
- **Persistent Proxy & DNS:** Configures `10.0.2.2:9090` and `8.8.8.8` globally on the device.
- **QUIC Blocking:** Prevents Google services from bypassing the HTTP proxy via UDP/443.

## 📁 Repository Structure
```text
Frida-Mobile-Setup/
├── setup.sh       # Main environment setup (Proxy, Certs, DNS, Frida-Server)
├── bypass.js      # Universal SSL & Connectivity Bypass (Frida)
├── run_bypass.sh  # Helper to launch ANY app with Frida
└── README.md          # Documentation
```

## 🛠️ Installation & Usage

### 1. Initial Environment Setup
Run this once after starting your emulator to prepare the certificate and Frida-server:
```bash
./setup.sh
```

### 2. Bypassing Any Application
Launch any app by its package name. This will bypass SSL pinning and "No Internet" detection:
```bash
# General Usage:
./run_bypass.sh <package_name>

# Example (Chrome):
./run_bypass.sh com.android.chrome

# Example (Specific App):
./run_bypass.sh com.example.app
```

## 📸 Technical Workflow

### Environment Initialization
The `setup.sh` script performs a volatile system injection using a `tmpfs` bind-mount. This allows us to write to the read-only `/system/etc/security/cacerts/` directory without permanently modifying the system image.

### SSL Pinning Bypass
The `bypass.js` script targets several key Android components:
- `TrustManagerImpl.checkServerTrusted`
- `okhttp3.CertificatePinner`
- `android.webkit.WebViewClient`
- `OpenSSLSocketImpl`

## ⚠️ Troubleshooting

### "No response received from remote server" (Burp Error)
If you see a Burp Suite error page in your mobile browser:
1. **Intercept is ON:** Ensure `Proxy > Intercept` is **OFF** in Burp Suite.
2. **Burp Outbound Blocked:** Ensure your host machine has internet access and Burp isn't blocked by a firewall.
3. **DNS Issue:** The `setup.sh` script sets the device DNS to `8.8.8.8`. If your network blocks external DNS, you may need to edit `setup.sh` to use your local DNS.

### "Unusual Traffic" / CAPTCHA (Google Error)
Google detects Burp's request headers:
- Disable all `Proxy > Proxy settings > Match and replace` rules.
- Test with `https://bing.com` or `https://example.com` to verify interception works.

### Frida Errno 2 (File not found)
- Ensure you are running the scripts from the **root** of the repository:
  `cd Frida-Mobile-Setup && ./run_bypass.sh`
- Do not run them from inside a `scripts/` folder.

## ⚖️ Disclaimer
This project is for educational and authorized security testing purposes only.

---

