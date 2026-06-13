{ config, pkgs, ... }:

let
    anthropicSkillRepo = pkgs.fetchFromGitHub{
        owner = "anthropics";
        repo = "skills";
        rev = "main";
        hash = "sha256-GMXFJSePrpEvhzMQ82YI9Z10BDkuFK/lXUDELclvQ4c="; 
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
    
    # Chrome with your custom Wayland flags
    (google-chrome.override {
      commandLineArgs = [
        "--enable-features=NativeNotifications"
        "--ozone-platform-hint=auto"
        "--enable-wayland-ime"
      ];
    })

    # Command Line Tools
    fastfetch
    htop
    btop
    ncdu
  ];

  home.file = {
    # Antropic skills
    ".agents/skills/frontend-design".source = "${anthropicSkillRepo}/skills/frontend-design";
    ".agents/skills/pptx".source = "${anthropicSkillRepo}/skills/pptx";
    ".agents/skills/pdf".source = "${anthropicSkillRepo}/skills/pdf";
    ".agents/skills/docx".source = "${anthropicSkillRepo}/skills/docx";
    ".agents/skills/xlsx".source = "${anthropicSkillRepo}/skills/xlsx";
    ".agents/skills/webapp-testing".source = "${anthropicSkillRepo}/skills/webapp-testing";
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