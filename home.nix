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
    libreoffice-fresh
    vlc
    nodejs
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
    ]))
    libnotify
    hunspell
    hunspellDicts.en_US
    antigravity
    claude-code

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

    # tools for AI agents
    agent-browser
  ];

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
    ".agents/skills/brainstorming".source = "${obraSuperpowersRepo}/skills/brainstorming";
    ".agents/skills/dispatching-parallel-agents".source = "${obraSuperpowersRepo}/skills/dispatching-parallel-agents";
    ".agents/skills/finishing-a-development-branch".source = "${obraSuperpowersRepo}/skills/finishing-a-development-branch";
    ".agents/skills/receiving-code-review".source = "${obraSuperpowersRepo}/skills/receiving-code-review";
    ".agents/skills/requesting-code-review".source = "${obraSuperpowersRepo}/skills/requesting-code-review";
    ".agents/skills/writing-plans".source = "${obraSuperpowersRepo}/skills/writing-plans";
    ".agents/skills/executing-plans".source = "${obraSuperpowersRepo}/skills/executing-plans";
    ".agents/skills/systematic-debugging".source = "${obraSuperpowersRepo}/skills/systematic-debugging";
    ".agents/skills/test-driven-development".source = "${obraSuperpowersRepo}/skills/test-driven-development";
    ".agents/skills/using-git-worktrees".source = "${obraSuperpowersRepo}/skills/using-git-worktrees";
    ".agents/skills/using-superpowers".source = "${obraSuperpowersRepo}/skills/using-superpowers";
    ".agents/skills/subagent-driven-development".source = "${obraSuperpowersRepo}/skills/subagent-driven-development";
    ".agents/skills/verification-before-completion".source = "${obraSuperpowersRepo}/skills/verification-before-completion";
    ".agents/skills/writing-skills".source = "${obraSuperpowersRepo}/skills/writing-skills";
    
    # Agent-Browser skill
    ".agents/skills/agent-browser".source = "${vercelAgentBrowserRepo}/skills/agent-browser";

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