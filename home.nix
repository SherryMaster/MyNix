{ config, pkgs, ... }:

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
    # GUI Applications
    kdePackages.kate
    vscode
    alacritty
    zoom-us
    jetbrains.pycharm
    libreoffice-fresh
    vlc
    
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
  ];

  # --- USER PROGRAMS & DOTFILES ---
  programs.git = {
    enable = true;
    settings = {
      user.name = "Shaheer Ahmed"; 
      user.email = "sherrymaster2@gmail.com";
    };
  };

  # Let Home Manager manage its own installation
  programs.home-manager.enable = true;
}