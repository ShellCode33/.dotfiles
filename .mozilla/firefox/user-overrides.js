// I don't want margins, I want websites to be full screen, even if it can be used for fingerprinting
user_pref("privacy.resistFingerprinting.letterboxing", false);

// Allow search engine requests from the search bar
user_pref("keyword.enabled", true);

// Use KeePassXC, not the built in password manager
user_pref("signon.rememberSignons", false);

// Proxy related (yes I use a local proxy by default, see https://github.com/ShellCode33/ArchLinux-Hardened/blob/master/docs/NETWORKING.md
user_pref("network.proxy.type", 1);
user_pref("network.proxy.share_proxy_settings", true);
user_pref("network.proxy.socks_remote_dns", true);
user_pref("network.proxy.http", "127.0.0.1");
user_pref("network.proxy.http_port", 8080);
user_pref("network.proxy.ssl", "127.0.0.1");
user_pref("network.proxy.ssl_port", 8080);

// DoH
user_pref("network.trr.mode", 3);
user_pref("network.trr.uri", "https://dns.quad9.net/dns-query");
user_pref("network.trr.custom_uri", "https://dns.quad9.net/dns-query");
user_pref("network.dns.skipTRR-when-parental-control-enabled", false);

// Make cert exceptions session only
user_pref("security.certerrors.permanentOverride", false);

// Always show the bookmarks toolbar
user_pref("browser.toolbars.bookmarks.visibility", "always");

// Annoying
user_pref("datareporting.policy.dataSubmissionPolicyBypassNotification", true);
user_pref("extensions.pocket.enabled", false);
user_pref("identity.fxaccounts.enabled", false);
user_pref("browser.preferences.moreFromMozilla", false);
user_pref("browser.tabs.firefox-view", false);

