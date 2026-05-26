/* 
   UNIVERSAL ANDROID SSL PINNING & CONNECTIVITY BYPASS
   Targets: TrustManager, OkHttp, WebView, TrustKit, ConnectivityManager, and more.
*/

Java.perform(function() {
    var array_list = Java.use("java.util.ArrayList");

    console.log("\n[!] Starting Universal SSL & Connectivity Bypass...");

    // --- 1. FAKE CONNECTIVITY (Fixes "No Internet Connection" errors) ---
    try {
        var ConnectivityManager = Java.use('android.net.ConnectivityManager');
        var NetworkInfo = Java.use('android.net.NetworkInfo');

        ConnectivityManager.getActiveNetworkInfo.implementation = function() {
            console.log("[!] Bypassed ConnectivityManager.getActiveNetworkInfo (Fake Internet)");
            return NetworkInfo.$new(0, 0, "WIFI", "CONNECTED");
        };

        ConnectivityManager.getNetworkInfo.overload('int').implementation = function(type) {
            console.log("[!] Bypassed ConnectivityManager.getNetworkInfo (Fake Internet)");
            return NetworkInfo.$new(0, 0, "WIFI", "CONNECTED");
        };
    } catch (e) {
        console.log("[-] ConnectivityManager hook failed (usually fine for newer Android)");
    }

    // --- 2. TrustManagerImpl Bypass (System Level) ---
    try {
        var TrustManagerImpl = Java.use('com.android.org.conscrypt.TrustManagerImpl');
        var overloads = TrustManagerImpl.checkServerTrusted.overloads;
        for (var i = 0; i < overloads.length; i++) {
            overloads[i].implementation = function() {
                console.log("[!] Bypassed TrustManagerImpl.checkServerTrusted (Triggered)");
                return array_list.$new();
            };
        }
    } catch (e) {}

    // --- 3. OkHttp 3 & 4 Bypass ---
    try {
        var CertificatePinner = Java.use('okhttp3.CertificatePinner');
        CertificatePinner.check.overload('java.lang.String', 'java.util.List').implementation = function(str, list) {
            console.log("[!] Bypassed OkHttp3/4 Pinning: " + str);
            return;
        };
    } catch (e) {}

    // --- 4. WebView Bypass ---
    try {
        var WebViewClient = Java.use('android.webkit.WebViewClient');
        WebViewClient.onReceivedSslError.implementation = function(view, handler, error) {
            console.log("[!] Bypassed WebView SSL Error");
            handler.proceed();
        };
    } catch (e) {}

    // --- 5. Network Security Config (Android 7+) ---
    try {
        var NetworkSecurityConfig = Java.use('android.security.net.config.NetworkSecurityConfig');
        NetworkSecurityConfig.isNetworkSecurityConfigSpecified.implementation = function() {
            return false;
        };
    } catch (e) {}

    // --- 6. OpenSSL / Cronet / Flutter Pinning ---
    // (Injecting common return true/void patterns for native-like libraries)
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
            console.log("[!] Bypassed SSLContext.init (Triggered)");
            this.init(km, TrustManagers, sr);
        };
    } catch (e) {}

    console.log("[***] UNIVERSAL BYPASS READY [***]\n");
});
