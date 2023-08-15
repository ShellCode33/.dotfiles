// I don't want margins, I want websites to be full screen, even if it can be used for fingerprinting
user_pref("privacy.resistFingerprinting.letterboxing", false);

// Allow search engine requests from the search bar
user_pref("keyword.enabled", true);

// Use KeePassXC, not the built in password manager
user_pref("signon.rememberSignons", false);

// DoH
user_pref("network.trr.mode", 3);
user_pref("network.trr.uri", "https://dns.quad9.net/dns-query");
user_pref("network.trr.bootstrapAddr", "9.9.9.9"); // Quad9 as well
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

