# https://discourse.nixos.org/t/declare-firefox-extensions-and-settings/36265
let
  lock = Value: {
    inherit Value;
    Status = "locked";
  };
in
  {
    pkgs,
    lib,
    ...
  }: {
    # Enable SearchEngines policy
    # https://hedgedoc.grimmauld.de/s/rVnTq0-Rs#
    nixpkgs.overlays = lib.singleton (final: prev: {
      firefox = prev.firefox.overrideAttrs (old: {
        nativeBuildInputs =
          (old.nativeBuildInputs or [])
          ++ (with final; [zip unzip gnused]);
        buildCommand = let
          omni = "$out/lib/firefox/browser/omni.ja";
          modify = "modules/policies/schema.sys.mjs";
        in ''
          ${old.buildCommand}
          if test -L ${omni}; then
            install -m644 $(realpath ${omni}) ${omni}
          fi
          pushd $(mktemp -d)
          unzip ${omni} ${modify} || test $? -eq 2
          sed -i 's/"enterprise_only"\s*:\s*true,//' ${modify}
          zip -0DX ${omni} ${modify}
          popd
        '';
      });
    });
    programs = {
      firefox = {
        package = pkgs.firefox;
        enable = true;
        languagePacks = ["en-GB" "de" "ja"];

        # ---- POLICIES ----
        # Check about:policies#documentation or https://mozilla.github.io/policy-templates/
        policies = {
          DisableTelemetry = true;
          DisableFirefoxStudies = true;
          EnableTrackingProtection = {
            Value = true;
            Locked = true;
            Cryptomining = true;
            Fingerprinting = true;
          };
          DisablePocket = true;
          DisableFirefoxAccounts = true;
          DisableAccounts = true;
          DisableFirefoxScreenshots = false;
          DisableSetDesktopBackground = true;
          OverrideFirstRunPage = "";
          OverridePostUpdatePage = "";
          DontCheckDefaultBrowser = true;
          DisplayBookmarksToolbar = "never";
          DisplayMenuBar = "default-off";
          SearchBar = "separate";
          FirefoxHome = {
            Search = false;
            TopSites = false;
            SponsoredTopSites = false;
            Highlights = false;
            Pocket = false;
            SponsoredPocket = false;
            Snippets = false;
            Locked = false;
          };

          # ---- EXTENSIONS ----
          # cat ~/.mozilla/firefox/*.default/addons.json | from json
          # | get addons | select name id sourceURI
          # | each {|addon| update sourceURI ($addon.sourceURI | str replace --regex '/[^/]*.xpi' '/latest.xpi')}
          # | save addons.json
          # Alternatively: Check about:support for extension/add-on ID strings.
          ExtensionSettings = builtins.listToAttrs (map (ex: {
              name = ex.id;
              value = {
                install_url = ex.sourceURI;
                installation_mode = "normal_installed";
              };
            }) (
              lib.importJSON ./addons.json
              ++ map (ex: {
                id = "rowserext-${ex}@liftm.de";
                sourceURI = "file://${pkgs.rowserext}/${ex}.xpi";
              }) [] #["lionel" "join-on-time"] # won't work for now, because devedition is out
            ));

          # ---- PREFERENCES ----
          Preferences = {
            "browser.contentblocking.category" = lock "strict";
            "extensions.pocket.enabled" = lock false;
            "browser.topsites.contile.enabled" = lock false;
            #"browser.formfill.enable" = lock false;
            "browser.search.suggest.enabled" = lock false;
            "browser.search.suggest.enabled.private" = lock false;
            "browser.urlbar.suggest.searches" = lock false;
            "browser.urlbar.showSearchSuggestionsFirst" = lock false;
            "browser.newtabpage.activity-stream.feeds.section.topstories" = lock false;
            "browser.newtabpage.activity-stream.feeds.snippets" = lock false;
            "browser.newtabpage.activity-stream.section.highlights.includePocket" = lock false;
            "browser.newtabpage.activity-stream.section.highlights.includeBookmarks" = lock false;
            "browser.newtabpage.activity-stream.section.highlights.includeDownloads" = lock false;
            "browser.newtabpage.activity-stream.section.highlights.includeVisited" = lock false;
            "browser.newtabpage.activity-stream.showSponsored" = lock false;
            "browser.newtabpage.activity-stream.system.showSponsored" = lock false;
            "browser.newtabpage.activity-stream.showSponsoredTopSites" = lock false;
            "browser.sessionstore.warnOnQuit" = true;
            "dom.private-attribution.submission.enabled" = lock false;
            # "xpinstall.signatures.required" = lock false; # Meh, can't install my custom extensions otherwise. only works on esr/devedition
            "browser.urlbar.update2.engineAliasRefresh" = true; # easy modifying of search engines from about:preferences

            "browser.ctrlTab.sortByRecentlyUsed" = true;
            "network.captive-portal-service.enabled" = false;
            "browser.newtabpage.activity-stream.improvesearch.topSiteSearchShortcuts.havePinned" = lock "[]";
            "browser.newtabpage.activity-stream.improvesearch.topSiteSearchShortcuts.searchEngines" = lock "[]";
            "browser.newtabpage.pinned" = lock "[]";

            # arken
            "toolkit.telemetry.coverage.opt-out" = lock true;
            "toolkit.coverage.opt-out" = lock true;
            "browser.newtabpage.activity-stream.feeds.telemetry" = lock false;
            "browser.newtabpage.activity-stream.telemetry" = lock false;
            "browser.urlbar.speculativeConnect.enabled" = false;
            "browser.urlbar.showSearchTerms.enabled" = false;
          };
          SearchEngines = {
            Remove = ["Bing" "@bing" "bing" "Google" "Wikipedia (en)" "Amazon" "Amazon.co.jp" "Amazon.de"];
            Add = [
              {
                Alias = "wde";
                Name = "Wikipedia Durchsuchen";
                URLTemplate = "https://www.wikipedia.org/search-redirect.php?family=wikipedia&search={searchTerms}&language=de&go=Go";
                # IconURL = "https://www.example.org/favicon.ico";
                # Method = "GET";
                # PostData = "name=value&q={searchTerms}";
                # SuggestURLTemplate = "https://www.example.org/suggestions/q={searchTerms}";
              }
              {
                Alias = "wen";
                Name = "Search Wikipedia";
                URLTemplate = "https://www.wikipedia.org/search-redirect.php?family=wikipedia&search={searchTerms}&language=en&go=Go";
              }
              {
                Alias = "wja";
                Name = "Wikipediaで検索";
                URLTemplate = "https://www.wikipedia.org/search-redirect.php?family=wikipedia&search={searchTerms}&language=ja&go=Go";
              }
              {
                Alias = "jisho";
                Name = "辞書 Dictionary";
                URLTemplate = "https://jisho.org/search?keyword={searchTerms}";
              }
              {
                Alias = "wad";
                Name = "Wadoku 辞書 Wörterbuch";
                URLTemplate = "https://www.wadoku.de/search/{searchTerms}";
              }
              {
                Alias = "wa";
                Name = "Wolfram Alpha";
                URLTemplate = "https://www.wolframalpha.com/input?i={searchTerms}";
              }
              {
                Alias = "anidb";
                Name = "AniDB";
                URLTemplate = "https://anidb.net/perl-bin/animedb.pl?adb.search={searchTerms}&show=search&do.search=1&cleanurl=1";
              }
              {
                Alias = "d";
                Name = "DuckDuckGo (policied)";
                URLTemplate = "https://duckduckgo.com/?t=ffab&q={searchTerms}&ia=web";
              }
              {
                Alias = "g";
                Name = "Google (policied)";
                URLTemplate = "https://google.com/search?q={searchTerms}&lr=lang_en";
              }
              {
                Alias = "leo";
                Name = "Leo Dictionary";
                URLTemplate = "https://dict.leo.org/german-english/{searchTerms}";
              }
              {
                Alias = "ud";
                Name = "Urban Dictionary";
                URLTemplate = "https://www.urbandictionary.com/define.php?term={searchTerms}";
              }
              {
                Alias = "nixo";
                Name = "NixOS Options";
                URLTemplate = "https://search.nixos.org/options?channel=unstable&from=0&size=50&sort=relevance&type=packages&query={searchTerms}";
              }
              {
                Alias = "nixp";
                Name = "NixOS Packages";
                URLTemplate = "https://search.nixos.org/packages?channel=unstable&from=0&size=50&sort=relevance&type=packages&query={searchTerms}";
              }
            ];
          };
          Default = "DuckDuckGo";
          PreventInstalls = true;
        };
      };
    };
  }
