/* 
   UNIVERSAL MOBILE SSL PINNING & CONNECTIVITY BYPASS
   Platforms: Android (Java) & iOS (Objective-C)
   Targets: TrustManager, OkHttp, WebView, TrustKit, SecTrust, and more.
*/

// --- ANDROID BYPASS (Java) ---
if (Java.available) {
    Java.perform(function() {
        var array_list = Java.use("java.util.ArrayList");

        console.log("\n[!] Starting Android SSL & Connectivity Bypass...");

        // --- 1. FAKE CONNECTIVITY (Fixes "No Internet Connection" errors) ---
        try {
            var ConnectivityManager = Java.use('android.net.ConnectivityManager');
            var NetworkInfo = Java.use('android.net.NetworkInfo');

            ConnectivityManager.getActiveNetworkInfo.implementation = function() {
                return NetworkInfo.$new(0, 0, "WIFI", "CONNECTED");
            };

            ConnectivityManager.getNetworkInfo.overload('int').implementation = function(type) {
                return NetworkInfo.$new(0, 0, "WIFI", "CONNECTED");
            };
            console.log("[+] Hooked ConnectivityManager");
        } catch (e) {
            console.log("[-] ConnectivityManager hook failed");
        }

        // --- 2. TrustManagerImpl Bypass (System Level) ---
        try {
            var TrustManagerImpl = Java.use('com.android.org.conscrypt.TrustManagerImpl');
            var overloads = TrustManagerImpl.checkServerTrusted.overloads;
            for (var i = 0; i < overloads.length; i++) {
                overloads[i].implementation = function() {
                    return array_list.$new();
                };
            }
            console.log("[+] Hooked TrustManagerImpl");
        } catch (e) {}

        // --- 3. OkHttp 3 & 4 Bypass ---
        try {
            var CertificatePinner = Java.use('okhttp3.CertificatePinner');
            CertificatePinner.check.overload('java.lang.String', 'java.util.List').implementation = function(str, list) {
                console.log("[!] Bypassed OkHttp3/4 Pinning: " + str);
                return;
            };
            console.log("[+] Hooked OkHttp3/4");
        } catch (e) {}

        // --- 4. WebView Bypass ---
        try {
            var WebViewClient = Java.use('android.webkit.WebViewClient');
            WebViewClient.onReceivedSslError.implementation = function(view, handler, error) {
                console.log("[!] Bypassed WebView SSL Error");
                handler.proceed();
            };
            console.log("[+] Hooked WebViewClient");
        } catch (e) {}

        // --- 5. Network Security Config (Android 7+) ---
        try {
            var NetworkSecurityConfig = Java.use('android.security.net.config.NetworkSecurityConfig');
            NetworkSecurityConfig.isNetworkSecurityConfigSpecified.implementation = function() {
                return false;
            };
            console.log("[+] Hooked NetworkSecurityConfig");
        } catch (e) {}

        // --- 6. OpenSSL / Cronet / Flutter Pinning ---
        try {
            var X509TrustManager = Java.use('javax.net.ssl.X509TrustManager');
            var SSLContext = Java.use('javax.net.ssl.SSLContext');
            var TrustManagers = [Java.registerClass({
                name: 'com.target.UniversalTrustManager',
                implements: [X509TrustManager],
                methods: {
                    checkClientTrusted: function(chain, authType) {},
                    checkServerTrusted: function(chain, authType) {},
                    getAcceptedIssuers: function() { return []; }
                }
            }).$new()];

            SSLContext.init.overload('[Ljavax.net.ssl.KeyManager;', '[Ljavax.net.ssl.TrustManager;', 'java.security.SecureRandom').implementation = function(km, tm, sr) {
                this.init(km, TrustManagers, sr);
            };
            console.log("[+] Hooked SSLContext");
        } catch (e) {}

        console.log("[***] ANDROID UNIVERSAL BYPASS READY [***]\n");
    });
}

// --- iOS BYPASS (Objective-C) ---
if (ObjC.available) {
    console.log("\n[!] Starting iOS SSL Pinning Bypass...");

    // SecTrustEvaluate
    try {
        var SecTrustEvaluate = Module.findExportByName("Security", "SecTrustEvaluate");
        if (SecTrustEvaluate) {
            Interceptor.replace(SecTrustEvaluate, new NativeCallback(function(trust, result) {
                console.log("[!] Bypassed SecTrustEvaluate");
                Memory.writeU32(result, 1); // kSecTrustResultProceed
                return 0; // errSecSuccess
            }, 'int', ['pointer', 'pointer']));
            console.log("[+] Hooked SecTrustEvaluate");
        }
    } catch (e) {
        console.log("[-] SecTrustEvaluate hook failed");
    }

    // SecTrustEvaluateWithError (iOS 12+)
    try {
        var SecTrustEvaluateWithError = Module.findExportByName("Security", "SecTrustEvaluateWithError");
        if (SecTrustEvaluateWithError) {
            Interceptor.replace(SecTrustEvaluateWithError, new NativeCallback(function(trust, error) {
                console.log("[!] Bypassed SecTrustEvaluateWithError");
                return 1; // True
            }, 'int', ['pointer', 'pointer']));
            console.log("[+] Hooked SecTrustEvaluateWithError");
        }
    } catch (e) {}

    // SSLSetSessionOption
    try {
        var SSLSetSessionOption = Module.findExportByName("Security", "SSLSetSessionOption");
        if (SSLSetSessionOption) {
            Interceptor.replace(SSLSetSessionOption, new NativeCallback(function(context, option, value) {
                if (option === 3) { // kSSLSessionOptionBreakOnServerAuth
                    console.log("[!] Bypassed SSLSetSessionOption (BreakOnServerAuth)");
                    return 0;
                }
                return this(context, option, value);
            }, 'int', ['pointer', 'int', 'int']));
            console.log("[+] Hooked SSLSetSessionOption");
        }
    } catch (e) {}

    // Alamofire / AFNetworking (common patterns)
    try {
        var AFSecurityPolicy = ObjC.classes.AFSecurityPolicy;
        if (AFSecurityPolicy) {
            AFSecurityPolicy['- evaluateServerTrust:forDomain:'].implementation = ObjC.implement(AFSecurityPolicy['- evaluateServerTrust:forDomain:'], function(handle, selector, trust, domain) {
                console.log("[!] Bypassed AFSecurityPolicy evaluateServerTrust");
                return 1;
            });
            console.log("[+] Hooked AFSecurityPolicy");
        }
    } catch (e) {}

    console.log("[***] iOS UNIVERSAL BYPASS READY [***]\n");
}
