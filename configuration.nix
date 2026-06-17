# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:

let
  nix-flatpak = builtins.fetchTarball "https://github.com/gmodena/nix-flatpak/archive/refs/tags/v0.7.0.tar.gz";

  # Define the unstable channel declaratively
  unstable = import (builtins.fetchTarball "https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz") {
    config = config.nixpkgs.config;
  };
  
  # Fetch Home Manager source (Pinned to match your system version)
  home-manager = builtins.fetchTarball "https://github.com/nix-community/home-manager/archive/release-26.05.tar.gz";
  
in
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      # Import the fetched nix-flatpak module
      "${nix-flatpak}/modules/nixos.nix"
      # Import Home Manager module
      "${home-manager}/nixos"
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  networking.firewall.trustedInterfaces = [ "waydroid0" ];

  # Enable Bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  # Enable input daemon for Nintendo Switch Pro Controllers & Joy-Cons
  services.joycond.enable = true;

  # Set your time zone.
  time.timeZone = "Asia/Karachi";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Enable the X11 windowing system.
  # You can disable this if you're only using the Wayland session.
  services.xserver.enable = true;

  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # enable flatpak service
  services.flatpak.enable = true;

  # Configure the Flathub repository
  services.flatpak.remotes = lib.mkOptionDefault [
    {
      name = "flathub";
      location = "https://dl.flathub.org/repo/flathub.pakrepo";
    }
  ];

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.sherry = {
    isNormalUser = true;
    shell = pkgs.zsh;
    description = "Shaheer Ahmed";
    extraGroups = [ "networkmanager" "wheel" "docker" "vboxusers"];
    linger = true;
    # Note: packages have been moved to home.nix!
  };

  # --- HOME MANAGER CONFIGURATION ---
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.users.sherry = import ./home.nix;
  # ----------------------------------

  fonts.packages = with pkgs; [
    nerd-fonts.fira-code
    nerd-fonts.meslo-lg
  ];

  # I left Zsh here at the system level so NixOS correctly registers it in /etc/shells
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
    ohMyZsh = {
      enable = true;
      plugins = [ "git" "sudo" "history" "z" ];
      theme = "jonathan"; 
    };
  };

  # Install firefox.
  programs.firefox.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
  
  # Allow insecure packages
  nixpkgs.config = {
    allowInsecurePredicate = pkg: pkg.pname == "ciscoPacketTracer8";
  };

  environment.extraInit = ''
  # Make sure Flatpak application paths are included in XDG_DATA_DIRS
  export XDG_DATA_DIRS="$XDG_DATA_DIRS:/var/lib/flatpak/exports/share:$HOME/.local/share/flatpak/exports/share"
  '';

  environment.sessionVariables = {
    SAL_USE_VCLPLUGIN = "qt6";
    SPARK_HOME = "${pkgs.spark}";
    LD_LIBRARY_PATH = lib.mkForce (lib.makeLibraryPath (with pkgs; [
      gtk3 glib cairo pango gdk-pixbuf atk
      libx11 libxext libxcursor libxrandr libxxf86vm libxrender libxtst libxi
      libxcomposite libxdamage libxfixes libxft
      xorg.libXt xorg.libXmu xorg.libXinerama
      fontconfig freetype zlib
      glfw libpulseaudio libGL openal vulkan-loader udev alsa-lib
      stdenv.cc.cc.lib
    ]));
  };

  # System-level dependencies and complex custom derivations stay here
  environment.systemPackages = with pkgs; [
  # --- C/C++ Global Toolchain ---
  gcc           
  gnumake       
  cmake         
  gdb           
  clang-tools   
  # ------------------------------
  nix-your-shell
  wget
  jq
  jdk11
  docker-compose
  apacheKafka
  spark
  ffmpeg
  waydroid-helper
  unzip
  piper
  karere
  unstable.cisco-packet-tracer_9
  unstable.godot

  # -- Games --
  # keep system-level games here only if needed for all users
  
  
  (pkgs.writeShellScriptBin "packettracer-offline" ''
      PT_BIN=(${unstable.cisco-packet-tracer_9}/bin/*)
      exec systemd-run \
        --user \
        --wait \
        --property=PrivateNetwork=yes \
        --setenv=DISPLAY="''${DISPLAY:-}" \
        --setenv=WAYLAND_DISPLAY="''${WAYLAND_DISPLAY:-}" \
        --setenv=XDG_RUNTIME_DIR="''${XDG_RUNTIME_DIR:-}" \
        --setenv=XAUTHORITY="''${XAUTHORITY:-}" \
        --setenv=DBUS_SESSION_BUS_ADDRESS="''${DBUS_SESSION_BUS_ADDRESS:-}" \
        "''${PT_BIN[0]}" "$@"
  '')

  (makeDesktopItem {
    name = "packettracer-offline-gui";
    desktopName = "Cisco Packet Tracer (Offline)";
    exec = "packettracer-offline %f"; 
    icon = "cisco-packet-tracer-9"; 
    terminal = false;
    type = "Application";
    categories = [ "Network" ];
  })
  

  
  (pkgs.stdenv.mkDerivation {
      pname = "m913-ctl";
      version = "latest";
      src = pkgs.fetchFromGitHub {
        owner = "Qehbr";
        repo = "m913-ctl";
        rev = "main"; 
        hash = "sha256-ajThk3yoIXeIXmu4KhOHSCLAp0U/cTSA8R/LLifocgY="; 
      };
      nativeBuildInputs = [ pkgs.cmake pkgs.pkg-config ];
      buildInputs = [ pkgs.libusb1 ];
    })
    
  (pkgs.stdenv.mkDerivation {
      pname = "m913-ctl-gui";
      version = "latest";
      src = pkgs.fetchFromGitHub {
        owner = "brunofin";
        repo = "m913-ctl-gui";
        rev = "main";
        hash = "sha256-uEXCNlX0ok5g6QU8OhwYMvoS88QF8RXYFvliyD1dt04=";
      };
      nativeBuildInputs = [ pkgs.makeWrapper pkgs.wrapGAppsHook4 pkgs.gobject-introspection ];
      buildInputs = [ pkgs.gtk4 pkgs.libadwaita ];
      installPhase = ''
        mkdir -p $out/bin $out/opt/m913-ctl-gui
        cp -r m913_gui run.py $out/opt/m913-ctl-gui/
        makeWrapper ${pkgs.python3.withPackages (p: [ p.pygobject3 ])}/bin/python3 $out/bin/m913-ctl-gui \
          --add-flags "$out/opt/m913-ctl-gui/run.py" \
          "''${gappsWrapperArgs[@]}"
      '';
    })
 ];

  services.ratbagd.enable = true;
  services.flatpak.packages = [
    "org.vinegarhq.Sober"
    "org.freedownloadmanager.Manager"
  ];

  services.flatpak.update.auto = {
    enable = true;
    onCalendar = "daily"; # Runs a systemd timer daily. You can also use "weekly"
  };

  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTR{idVendor}=="25a7", ATTR{idProduct}=="fa07", MODE="0666"
    SUBSYSTEM=="usb", ATTR{idVendor}=="25a7", ATTR{idProduct}=="fa08", MODE="0666"
  '';

  services.flatpak.overrides = {
    "org.freedownloadmanager.Manager".Context.filesystems = [
      "/mnt/Soft"
      "/mnt/Data" 
    ];
  };

  services.hardware.openrgb = {
    enable = true;
    package = pkgs.openrgb-with-all-plugins; 
  };

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
  };

  virtualisation.virtualbox.host.enable = true;
  virtualisation.virtualbox.host.enableExtensionPack = true;
  
  virtualisation.docker.enable = false;
  virtualisation.docker.autoPrune = {
    enable = true;
    dates = "weekly";
  };
  virtualisation.docker.daemon.settings = {
    dns = [ "8.8.8.8" "8.8.4.4" ];
  };
  virtualisation.docker.rootless = {
    enable = true;
    setSocketVariable = true;
  };

  programs.nix-ld.enable = true;

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true; 
    dedicatedServer.openFirewall = true; 
    localNetworkGameTransfers.openFirewall = true; 
  };

  programs.gamemode.enable = true;
  programs.gamescope.enable = true;

  virtualisation.waydroid.enable = true;
  virtualisation.waydroid.package = pkgs.waydroid-nftables;
  systemd.services.waydroid-container.wantedBy = [ "multi-user.target" ];

  fileSystems."/mnt/Soft" = {
    device = "/dev/disk/by-uuid/EA282ACC282A9799";
    fsType = "ntfs-3g";
    options = [ "rw" "uid=1000" "gid=100" "nofail" "x-systemd.device-timeout=5s" ];
  };

  fileSystems."/mnt/Data" = {
    device = "/dev/disk/by-uuid/1C1839B518398EB0";
    fsType = "ntfs-3g";
    options = [ "rw" "uid=1000" "gid=100" "nofail" "x-systemd.device-timeout=5s" ];
  };

  systemd.tmpfiles.rules = [
    "Z /etc/nixos 0775 root wheel - -"
  ];

  # --- REMOTE ACCESS SETUP (Sunshine, Avahi, Tailscale) ---
  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true; # Optimizes screen capture performance
    openFirewall = true; # Automatically opens required streaming ports
  };

  services.avahi = {
    enable = true;
    publish = {
      enable = true;
      userServices = true;
    };
  };

  services.tailscale.enable = true; 
  # --------------------------------------------------------

  system.stateVersion = "25.11"; 
}