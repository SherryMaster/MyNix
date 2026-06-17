{ config, pkgs, lib, ... }:

let
    anthropicSkillRepo = pkgs.fetchFromGitHub{
        owner = "anthropics";
        repo = "skills";
        rev = "main";
        hash = "sha256-GMXFJSePrpEvhzMQ82YI9Z10BDkuFK/lXUDELclvQ4c="; 
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

    agent-browser
  ];

  home.file = {
    # Antropic skills
    ".agents/skills/frontend-design".source = "${anthropicSkillRepo}/skills/frontend-design";
    ".agents/skills/pptx".source = "${anthropicSkillRepo}/skills/pptx";
    ".agents/skills/pdf".source = "${anthropicSkillRepo}/skills/pdf";
    ".agents/skills/docx".source = "${anthropicSkillRepo}/skills/docx";
    ".agents/skills/xlsx".source = "${anthropicSkillRepo}/skills/xlsx";

    ".agents/skills/agent-browser".source = "${vercelAgentBrowserRepo}/skills/agent-browser";
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