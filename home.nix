{ config, pkgs, lib, ... }:

let
    anthropicSkillRepo = pkgs.fetchFromGitHub{
        owner = "anthropics";
        repo = "skills";
        rev = "main";
        hash = "sha256-GMXFJSePrpEvhzMQ82YI9Z10BDkuFK/lXUDELclvQ4c="; 
    };

    obraSuperpowersRepo = pkgs.fetchFromGitHub {
        owner = "obra";
        repo = "superpowers";
        rev = "main"; 
        hash = "sha256-P/FD8HTQO+QzvMe3A/B2v2vjs8T6ZmIYH3MPp79dSzo=";
    };

    vercelAgentBrowserRepo = pkgs.fetchFromGitHub {
        owner = "vercel-labs";
        repo = "agent-browser";
        rev = "main";
        hash = "sha256-XDTGYcDodP4hQ7fx3dAV2FYhHKIqLuiGz6+gPfgp8Rg="; 
    };

    vercelAgentSkillsRepo = pkgs.fetchFromGitHub {
        owner = "vercel-labs";
        repo = "agent-skills";
        rev = "main";
        hash = "sha256-LSFC0Zxc4Lgisu5/r6qBF1R0X36hePkVPfbvbx48YdY="; 
    };

    browserUseRepo = pkgs.fetchFromGitHub {
        owner = "browser-use";
        repo = "browser-use";
        rev = "main";
        sha256 = "1szyxzszz3ysrn0sknp75i79v0p0rmjplzn5w422c9n6yb72vzsy";
    };

    # Custom Python packages for browser-use (not in nixpkgs)
    # NB: underscore names because Nix let bindings don't allow hyphens
    uuid7 = pkgs.python3.pkgs.buildPythonPackage rec {
      pname = "uuid7";
      version = "0.1.0";
      src = pkgs.fetchurl {
        url = "https://files.pythonhosted.org/packages/5c/19/7472bd526591e2192926247109dbf78692e709d3e56775792fec877a7720/uuid7-0.1.0.tar.gz";
        hash = "sha256-jFeqMu50VtPMaMlcRTC8VxZG3vrAGJXPxzVFRJiUpjw=";
      };
      format = "pyproject";
      nativeBuildInputs = with pkgs.python3.pkgs; [ setuptools ];
      doCheck = false;
    };

    bubus = pkgs.python3.pkgs.buildPythonPackage rec {
      pname = "bubus";
      version = "1.5.6";
      src = pkgs.fetchurl {
        url = "https://files.pythonhosted.org/packages/2d/85/aa72d1ffced7402fe41805519dab9935e9ce2bce18a10a55f2273ba8ba59/bubus-1.5.6.tar.gz";
        hash = "sha256-GlRW8KV26GYTp71m6BmJG2d3eDILbikQlOM5sNnfLg0=";
      };
      format = "pyproject";
      nativeBuildInputs = with pkgs.python3.pkgs; [ hatchling ];
      propagatedBuildInputs = (with pkgs.python3.pkgs; [
        aiofiles anyio portalocker pydantic
      ]) ++ [ pkgs.python3.pkgs."typing-extensions" uuid7 ];
      doCheck = false;
    };

    cdp_use = pkgs.python3.pkgs.buildPythonPackage rec {
      pname = "cdp-use";
      version = "1.4.5";
      src = pkgs.fetchurl {
        url = "https://files.pythonhosted.org/packages/f7/7a/c549417e8c5e4dface6d5d828cd7dc72502dcea33a99f5324abf5a853ce9/cdp_use-1.4.5.tar.gz";
        hash = "sha256-DaOjLfRjNqA/9aIrxrxELNfS8tUKEY/UhW8p039tJqA=";
      };
      format = "pyproject";
      nativeBuildInputs = with pkgs.python3.pkgs; [ hatchling ];
      propagatedBuildInputs = (with pkgs.python3.pkgs; [
        httpx websockets
      ]) ++ [ pkgs.python3.pkgs."typing-extensions" ];
      doCheck = false;
    };

    fetch_use = pkgs.python3.pkgs.buildPythonPackage rec {
      pname = "fetch-use";
      version = "0.4.0";
      src = pkgs.fetchurl {
        url = "https://files.pythonhosted.org/packages/5d/2d/66784fa8b66a04f170ad8f6598688b30b3a194dad4185b36d53da4ae1505/fetch_use-0.4.0.tar.gz";
        hash = "sha256-lRGYfUkH7G2sUB4h1mlG0QCY9mtdIbwqukGJzYG6GJo=";
      };
      format = "pyproject";
      nativeBuildInputs = with pkgs.python3.pkgs; [ hatchling ];
      doCheck = false;
    };

    browser_use_sdk = pkgs.python3.pkgs.buildPythonPackage rec {
      pname = "browser-use-sdk";
      version = "3.4.2";
      src = pkgs.fetchurl {
        url = "https://files.pythonhosted.org/packages/1d/f0/e897f4b75d76c96017f0cff4d7264426ae5f7e26ad68656e2731b9c166a7/browser_use_sdk-3.4.2.tar.gz";
        hash = "sha256-vgULyAOzHsTp8j39cdncXxFg197AuWIyeRXK90OhAgg=";
      };
      format = "pyproject";
      nativeBuildInputs = with pkgs.python3.pkgs; [ hatchling ];
      propagatedBuildInputs = with pkgs.python3.pkgs; [ httpx pydantic ];
      doCheck = false;
    };

    browser_harness = pkgs.python3.pkgs.buildPythonPackage rec {
      pname = "browser-harness";
      version = "0.1.4";
      src = pkgs.fetchurl {
        url = "https://files.pythonhosted.org/packages/dd/96/a50549ee42ee79cb2de718cecbc162cd710c6bb4cd680bedb014c2983ca9/browser_harness-0.1.4.tar.gz";
        hash = "sha256-Znd5vnun4Z9nbwz5NlPyjzQO9p+mb3O1aqsSnNHD0T8=";
      };
      format = "pyproject";
      nativeBuildInputs = with pkgs.python3.pkgs; [ setuptools ];
      propagatedBuildInputs = (with pkgs.python3.pkgs; [
        pillow websockets
      ]) ++ [ fetch_use cdp_use ];
      dontCheckRuntimeDeps = 1;
      doCheck = false;
      # Subprocess daemon needs PYTHONPATH since Nix wrappers use site.addsitedir()
      postFixup = ''
        wrapProgram $out/bin/browser-harness \
          --set PYTHONPATH "$(grep -o "'[^']*python3\.[0-9]*/site-packages'" $out/bin/.browser-harness-wrapped | tr -d "'" | paste -sd:)"
      '';
    };

    browser_use = pkgs.python3.pkgs.buildPythonPackage rec {
      pname = "browser-use";
      version = "0.13.3";
      src = pkgs.fetchurl {
        url = "https://files.pythonhosted.org/packages/3c/dd/c4f16a3a7f4cf4607b6736960d2174eefa82b9e05124b1ce25f34c8424b3/browser_use-0.13.3.tar.gz";
        hash = "sha256-uItneyI00cdgH24FyE+1dncjv0xexO0SqxuIDtgiGBE=";
      };
      format = "pyproject";
      nativeBuildInputs = with pkgs.python3.pkgs; [ hatchling ];
      propagatedBuildInputs = (with pkgs.python3.pkgs; [
        aiohttp anyio click rich httpx psutil pydantic
        requests pillow openai anthropic mcp
        posthog screeninfo groq ollama
        markdownify cloudpickle pyotp pypdf reportlab
        websockets inquirerpy
      ]) ++ (let py = pkgs.python3.pkgs; in [
        py."python-dotenv"
        py."typing-extensions"
        py."google-genai"
        py."python-docx"
        py."google-api-python-client"
        py."google-auth"
        py."google-auth-oauthlib"
      ]) ++ [ uuid7 bubus cdp_use browser_use_sdk browser_harness ];
      dontCheckRuntimeDeps = 1;
      doCheck = false;
      postFixup = ''
        wrapProgram $out/bin/browser-use \
          --set PYTHONPATH "$(grep -o "'[^']*python3\.[0-9]*/site-packages'" $out/bin/.browser-use-wrapped | tr -d "'" | paste -sd:)"
        wrapProgram $out/bin/browser \
          --set PYTHONPATH "$(grep -o "'[^']*python3\.[0-9]*/site-packages'" $out/bin/.browser-wrapped | tr -d "'" | paste -sd:)"
        wrapProgram $out/bin/browseruse \
          --set PYTHONPATH "$(grep -o "'[^']*python3\.[0-9]*/site-packages'" $out/bin/.browseruse-wrapped | tr -d "'" | paste -sd:)"
        wrapProgram $out/bin/bu \
          --set PYTHONPATH "$(grep -o "'[^']*python3\.[0-9]*/site-packages'" $out/bin/.bu-wrapped | tr -d "'" | paste -sd:)"
      '';
    };
in
{
  # Define your user details
  home.username = "sherry";
  home.homeDirectory = "/home/sherry";

  # You can keep this at the version when you first install Home Manager
  home.stateVersion = "24.05";

  # --- YOUR USER PACKAGES ---
  # These are applications that only 'sherry' needs. 
  # If you delete a line here and rebuild, it completely vanishes from your system.
  home.packages = with pkgs; [
    vscode
    alacritty
    zoom-us
    jetbrains.pycharm
    jetbrains.rider
    inkscape
    krita
    libreoffice-fresh
    vlc
    nodejs
    melonloader-installer
    (python3.withPackages (ps: with ps; [ 
      pip 
      virtualenv 
      pyspark
      numpy
      matplotlib
      opencv-python
      jupyter
      ipykernel
      ultralytics
      pyside6

      # Office skills dependencies
      pypdf
      pdfplumber
      reportlab
      pdf2image
      pytesseract
      pandas
      openpyxl
      pillow
      markitdown
      python-docx
    ]))
    libnotify
    hunspell
    hunspellDicts.en_US
    antigravity
    unityhub
    dotnet-sdk

    (pkgs.writeShellScriptBin "opencode" ''
        exec ${pkgs.nodejs}/bin/npx -y opencode-ai@latest "$@"
    '')

    # opencode-desktop: always fetch latest from GitHub releases
    (pkgs.writeShellScriptBin "opencode-desktop" ''
        set -euo pipefail
        CACHE_DIR="$HOME/.local/share/opencode-desktop"
        mkdir -p "$CACHE_DIR"

        LATEST_VERSION=$(${pkgs.curl}/bin/curl -fsSL https://api.github.com/repos/anomalyco/opencode/releases/latest | ${pkgs.jq}/bin/jq -r '.tag_name')
        CURRENT_VERSION=""
        [ -f "$CACHE_DIR/.version" ] && CURRENT_VERSION=$(cat "$CACHE_DIR/.version")

        if [ "$LATEST_VERSION" != "$CURRENT_VERSION" ]; then
          echo "opencode-desktop: updating ''${CURRENT_VERSION:-none} -> $LATEST_VERSION"
          ARCH=$(uname -m)
          if [ "$ARCH" = "x86_64" ]; then
            ASSET="opencode-desktop-linux-x86_64.AppImage"
          elif [ "$ARCH" = "aarch64" ]; then
            ASSET="opencode-desktop-linux-arm64.AppImage"
          else
            echo "Unsupported architecture: $ARCH" >&2; exit 1
          fi
          URL="https://github.com/anomalyco/opencode/releases/download/$LATEST_VERSION/$ASSET"
          rm -f "$CACHE_DIR/opencode-desktop.AppImage"
          ${pkgs.curl}/bin/curl -fSL "$URL" -o "$CACHE_DIR/opencode-desktop.AppImage"
          chmod +x "$CACHE_DIR/opencode-desktop.AppImage"
          echo "$LATEST_VERSION" > "$CACHE_DIR/.version"
        fi

        exec ${pkgs.appimage-run}/bin/appimage-run "$CACHE_DIR/opencode-desktop.AppImage" "$@"
    '')

    # claude-code: always fetch latest native binary from Anthropic's download servers
    (pkgs.writeShellScriptBin "claude" ''
        set -euo pipefail
        CACHE_DIR="$HOME/.local/share/claude-code"
        mkdir -p "$CACHE_DIR"

        ARCH=$(uname -m)
        if [ "$ARCH" = "x86_64" ]; then
          PLATFORM="linux-x64"
        elif [ "$ARCH" = "aarch64" ]; then
          PLATFORM="linux-arm64"
        else
          echo "Unsupported architecture: $ARCH" >&2; exit 1
        fi

        LATEST_VERSION=$(${pkgs.curl}/bin/curl -fsSL https://downloads.claude.ai/claude-code-releases/latest)
        CURRENT_VERSION=""
        [ -f "$CACHE_DIR/.version" ] && CURRENT_VERSION=$(cat "$CACHE_DIR/.version")

        if [ "$LATEST_VERSION" != "$CURRENT_VERSION" ]; then
          echo "claude-code: updating ''${CURRENT_VERSION:-none} -> $LATEST_VERSION"
          MANIFEST=$(${pkgs.curl}/bin/curl -fsSL "https://downloads.claude.ai/claude-code-releases/$LATEST_VERSION/manifest.json")
          CHECKSUM=$(echo "$MANIFEST" | ${pkgs.jq}/bin/jq -r ".platforms[\"$PLATFORM\"].checksum // empty")
          if [ -z "$CHECKSUM" ] || [[ ! "$CHECKSUM" =~ ^[a-f0-9]{64}$ ]]; then
            echo "Platform $PLATFORM not found in manifest" >&2; exit 1
          fi
          ${pkgs.curl}/bin/curl -fSL "https://downloads.claude.ai/claude-code-releases/$LATEST_VERSION/$PLATFORM/claude" -o "$CACHE_DIR/claude.new"
          ACTUAL=$(sha256sum "$CACHE_DIR/claude.new" | cut -d' ' -f1)
          if [ "$ACTUAL" != "$CHECKSUM" ]; then
            echo "Checksum verification failed" >&2; rm -f "$CACHE_DIR/claude.new"; exit 1
          fi
          chmod +x "$CACHE_DIR/claude.new"
          mv -f "$CACHE_DIR/claude.new" "$CACHE_DIR/claude"
          echo "$LATEST_VERSION" > "$CACHE_DIR/.version"
        fi

        exec "$CACHE_DIR/claude" "$@"
    '')

    # ocgo: always fetch latest from GitHub releases
    # Small Go CLI for using OpenCode Go subscription from Claude Code or Codex CLI.
    # After `home-manager switch`, run `ocgo setup` once to store your API key,
    # then use `ocgo launch claude --model <model>` to run Claude Code via
    # the local OpenCode Go proxy (listens on 127.0.0.1:3456).
    (pkgs.writeShellScriptBin "ocgo" ''
        set -euo pipefail
        CACHE_DIR="$HOME/.local/share/ocgo"
        mkdir -p "$CACHE_DIR"

        LATEST_VERSION=$(${pkgs.curl}/bin/curl -fsSL https://api.github.com/repos/emanuelcasco/ocgo/releases/latest | ${pkgs.jq}/bin/jq -r '.tag_name')
        CURRENT_VERSION=""
        [ -f "$CACHE_DIR/.version" ] && CURRENT_VERSION=$(cat "$CACHE_DIR/.version")

        if [ "$LATEST_VERSION" != "$CURRENT_VERSION" ]; then
          echo "ocgo: updating ''${CURRENT_VERSION:-none} -> $LATEST_VERSION"
          ARCH=$(uname -m)
          case "$ARCH" in
            x86_64)  PLATFORM="linux_x86_64" ;;
            aarch64) PLATFORM="linux_arm64" ;;
            *) echo "Unsupported architecture: $ARCH" >&2; exit 1 ;;
          esac

          VERSION_NO_V="''${LATEST_VERSION#v}"
          ASSET="ocgo_''${VERSION_NO_V}_''${PLATFORM}.tar.gz"
          BASE_URL="https://github.com/emanuelcasco/ocgo/releases/download/$LATEST_VERSION"

          ${pkgs.curl}/bin/curl -fSL "$BASE_URL/checksums.txt" -o "$CACHE_DIR/checksums.txt.new"
          EXPECTED=$(${pkgs.gnugrep}/bin/grep -F "$ASSET" "$CACHE_DIR/checksums.txt.new" | head -1 | cut -d' ' -f1)
          if [ -z "$EXPECTED" ]; then
            echo "Could not find checksum for $ASSET" >&2
            rm -f "$CACHE_DIR/checksums.txt.new"
            exit 1
          fi
          ${pkgs.curl}/bin/curl -fSL "$BASE_URL/$ASSET" -o "$CACHE_DIR/ocgo.tar.gz.new"
          ACTUAL=$(sha256sum "$CACHE_DIR/ocgo.tar.gz.new" | cut -d' ' -f1)
          if [ "$ACTUAL" != "$EXPECTED" ]; then
            echo "Checksum verification failed (expected $EXPECTED, got $ACTUAL)" >&2
            rm -f "$CACHE_DIR/ocgo.tar.gz.new" "$CACHE_DIR/checksums.txt.new"
            exit 1
          fi

          ${pkgs.gnutar}/bin/tar -xzf "$CACHE_DIR/ocgo.tar.gz.new" -C "$CACHE_DIR" --strip-components=1 --exclude='._*'
          chmod +x "$CACHE_DIR/ocgo"
          rm -f "$CACHE_DIR/ocgo.tar.gz.new" "$CACHE_DIR/checksums.txt.new"
          echo "$LATEST_VERSION" > "$CACHE_DIR/.version"
        fi

        exec "$CACHE_DIR/ocgo" "$@"
    '')

    # Games
    rrootage
    powermanga
    prismlauncher
    
    # Chrome with your custom Wayland flags
    (google-chrome.override {
      commandLineArgs = [
        "--enable-features=NativeNotifications"
        "--ozone-platform-hint=auto"
        "--enable-wayland-ime"
      ];
    })

    # tlauncher with custom LD_LIBRARY_PATH to include JRE's native libs and runtime dependencies
    (pkgs.stdenv.mkDerivation {
      pname = "tlauncher";
      version = "2.924";
      
      src = pkgs.fetchurl {
        url = "https://github.com/DUB1401/TLauncher-Flatpak/releases/download/v2.924/TLauncher.jar";
        sha256 = "a818894a2b092c658fabe4a5f929b5a1f1906c7522feee8b796cad706123297c";
      };

      dontUnpack = true;

      nativeBuildInputs = [ pkgs.makeWrapper ];

      installPhase = let
        runtimeLibs = with pkgs; [
          glfw
          libpulseaudio
          libGL
          openal
          stdenv.cc.cc.lib
          vulkan-loader
          udev
          libx11
          libxext
          libxcursor
          libxrandr
          libxxf86vm
          libxrender
          libxtst
          libxi
          libxcomposite
          libxdamage
          libxfixes
          libxft
          fontconfig
          freetype
          zlib
          gtk3
          glib
          cairo
          pango
          gdk-pixbuf
          atk
          libxt
          libxmu
          libxinerama
          alsa-lib
        ];
        driverLink = pkgs.addDriverRunpath.driverLink;
        libPath = "${driverLink}/lib:${pkgs.lib.makeLibraryPath runtimeLibs}";
      in ''
        mkdir -p $out/share/tlauncher
        cp $src $out/share/tlauncher/TLauncher.jar

        mkdir -p $out/bin
        cat > $out/bin/tlauncher <<WRAPPER
        #!/bin/sh
        # Set LD_LIBRARY_PATH for bundled JRE's native libs
        export LD_LIBRARY_PATH="${libPath}:\$LD_LIBRARY_PATH"
        exec ${pkgs.jdk21}/bin/java -jar $out/share/tlauncher/TLauncher.jar "\$@"
        WRAPPER
        chmod +x $out/bin/tlauncher

        mkdir -p $out/share/applications
        cat > $out/share/applications/tlauncher.desktop <<EOF
        [Desktop Entry]
        Type=Application
        Name=TLauncher
        Comment=Minecraft Launcher
        Exec=$out/bin/tlauncher
        Icon=minecraft
        Terminal=false
        Categories=Game;
        EOF
      '';
    })

    # Command Line Tools
    fastfetch
    htop
    btop
    ncdu
    gh
    uv
    xkill

    # tools for AI agents
    agent-browser

    # Office skills dependencies
    poppler-utils   # pdftotext, pdfimages, pdftoppm (PDF/docx/pptx skills)
    qpdf            # CLI PDF merge/split/rotate (PDF skill)
    pandoc          # Document text extraction (DOCX skill)
    tesseract       # OCR engine for scanned PDFs (PDF skill)

    # Vision-based browser automation via browser-use
    browser_use     # CLI: browser-use <<'PY' ... PY
  ];

  # NODE_PATH so require('docx') and require('pptxgenjs') work for office skills
  home.sessionVariables = {
    NODE_PATH = "${config.home.homeDirectory}/.npm-global/lib/node_modules";
  };

  home.file = {

    #--------------------------
    #      SKILLS & AGENTS
    #--------------------------

    # Antropic skills
    ".agents/skills/frontend-design".source = "${anthropicSkillRepo}/skills/frontend-design";
    ".agents/skills/pptx".source = "${anthropicSkillRepo}/skills/pptx";
    ".agents/skills/pdf".source = "${anthropicSkillRepo}/skills/pdf";
    ".agents/skills/docx".source = "${anthropicSkillRepo}/skills/docx";
    ".agents/skills/xlsx".source = "${anthropicSkillRepo}/skills/xlsx";

    # Obra Superpowers skills
    # ".agents/skills/brainstorming".source = "${obraSuperpowersRepo}/skills/brainstorming";
    # ".agents/skills/dispatching-parallel-agents".source = "${obraSuperpowersRepo}/skills/dispatching-parallel-agents";
    # ".agents/skills/finishing-a-development-branch".source = "${obraSuperpowersRepo}/skills/finishing-a-development-branch";
    # ".agents/skills/receiving-code-review".source = "${obraSuperpowersRepo}/skills/receiving-code-review";
    # ".agents/skills/requesting-code-review".source = "${obraSuperpowersRepo}/skills/requesting-code-review";
    # ".agents/skills/writing-plans".source = "${obraSuperpowersRepo}/skills/writing-plans";
    # ".agents/skills/executing-plans".source = "${obraSuperpowersRepo}/skills/executing-plans";
    # ".agents/skills/systematic-debugging".source = "${obraSuperpowersRepo}/skills/systematic-debugging";
    # ".agents/skills/test-driven-development".source = "${obraSuperpowersRepo}/skills/test-driven-development";
    # ".agents/skills/using-git-worktrees".source = "${obraSuperpowersRepo}/skills/using-git-worktrees";
    # ".agents/skills/using-superpowers".source = "${obraSuperpowersRepo}/skills/using-superpowers";
    # ".agents/skills/subagent-driven-development".source = "${obraSuperpowersRepo}/skills/subagent-driven-development";
    # ".agents/skills/verification-before-completion".source = "${obraSuperpowersRepo}/skills/verification-before-completion";
    # ".agents/skills/writing-skills".source = "${obraSuperpowersRepo}/skills/writing-skills";
    
    # Vercel Agent skills
    ".agents/skills/web-design-guidelines".source = "${vercelAgentSkillsRepo}/skills/web-design-guidelines";

    # Agent-Browser skill
    ".agents/skills/agent-browser".source = "${vercelAgentBrowserRepo}/skills/agent-browser";

    # Browser-Use skill
    ".agents/skills/browser-use".source = "${browserUseRepo}/skills/browser-use";

    #--------------------------
    #     DESKTOP INTEGRATION
    #--------------------------

    # Desktop entry for opencode-desktop (auto-updating)
    ".local/share/applications/opencode-desktop.desktop".text = ''
      [Desktop Entry]
      Type=Application
      Name=OpenCode Desktop
      Exec=opencode-desktop %U
      Icon=opencode-desktop
      Terminal=false
      Categories=Development;IDE;
      MimeType=x-scheme-handler/opencode;
      StartupWMClass=opencode-desktop
    '';

    # Icons from the nixpkgs package (will be replaced on first run)
    ".local/share/icons/hicolor/128x128/apps/opencode-desktop.png".source = 
      "${pkgs.opencode-desktop}/share/icons/hicolor/128x128/apps/opencode-desktop.png";
    ".local/share/icons/hicolor/64x64/apps/opencode-desktop.png".source = 
      "${pkgs.opencode-desktop}/share/icons/hicolor/64x64/apps/opencode-desktop.png";
    ".local/share/icons/hicolor/32x32/apps/opencode-desktop.png".source = 
      "${pkgs.opencode-desktop}/share/icons/hicolor/32x32/apps/opencode-desktop.png";
  };

  # --- USER PROGRAMS & DOTFILES ---
  programs.git = {
    enable = true;
    settings = {
      user.name = "Shaheer Ahmed"; 
      user.email = "sherrymaster2@gmail.com";
    };
  };

  # Enable cliphist for Wayland clipboard history
  services.cliphist = {
    enable = true;
  };

  # Let Home Manager manage its own installation
  programs.home-manager.enable = true;
}
