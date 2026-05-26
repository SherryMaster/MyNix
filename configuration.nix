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
  home-manager = builtins.fetchTarball "https://github.com/nix-community/home-manager/archive/release-25.11.tar.gz";
  
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
  nodejs
  jdk11
  docker-compose
  apacheKafka
  spark
  (python3.withPackages (ps: with ps; [ 
      pip 
      virtualenv
      pyspark
  ]))
  waydroid
  waydroid-helper
  unzip
  piper
  wasistlos
  libnotify
  hunspell
  hunspellDicts.en_US
  unstable.cisco-packet-tracer_9
  unstable.godot
  
  # 1. Create the executable wrapper that drops network access
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

  # 2. Create the Desktop Shortcut to run that custom command
  (makeDesktopItem {
    name = "packettracer-offline-gui";
    desktopName = "Cisco Packet Tracer (Offline)";
    exec = "packettracer-offline %f"; 
    icon = "cisco-packet-tracer-9"; 
    terminal = false;
    type = "Application";
    categories = [ "Network" ];
  })
  
  (pkgs.writeShellScriptBin "opencode" ''
      exec ${pkgs.nodejs}/bin/npx -y opencode-ai@latest "$@"
  '')
  
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

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  virtualisation.virtualbox.host.enable = true;
  virtualisation.virtualbox.host.enableExtensionPack = true;
  virtualisation.waydroid.enable = true;
  
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

  systemd.services.waydroid-container = {
    serviceConfig = { Delegate = true; };
    preStart = ''
      mkdir -p /var/lib/waydroid
      touch /var/lib/waydroid/waydroid_base.prop
      sed -i '/gralloc.gbm.device/d' /var/lib/waydroid/waydroid_base.prop
      sed -i '/ro.hardware.gralloc/d' /var/lib/waydroid/waydroid_base.prop
      sed -i '/ro.hardware.egl/d' /var/lib/waydroid/waydroid_base.prop
      echo "gralloc.gbm.device=/dev/dri/renderD128" >> /var/lib/waydroid/waydroid_base.prop
      echo "ro.hardware.gralloc=gbm" >> /var/lib/waydroid/waydroid_base.prop
      echo "ro.hardware.egl=mesa" >> /var/lib/waydroid/waydroid_base.prop
    '';
  };

  networking.firewall.trustedInterfaces = [ "waydroid0" ];

  systemd.services.init-waydroid-images = {
    description = "Declarative download and installation of Android 11 images for Waydroid";
    before = [ "waydroid-container.service" ];
    wantedBy = [ "multi-user.target" ];
    path = with pkgs; [ wget unzip ]; 
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      mkdir -p /var/lib/waydroid/images
      if [ ! -f /var/lib/waydroid/images/system.img ] || [ ! -f /var/lib/waydroid/images/vendor.img ]; then
        echo "Waydroid Android 11 images missing. Starting automated installation..."
        cd /tmp
        if [ ! -f system11.zip ]; then
          echo "Downloading Android 11 system image..."
          wget -O system11.zip "https://sourceforge.net/projects/waydroid/files/images/system/lineage/waydroid_x86_64/lineage-18.1-20250621-GAPPS-waydroid_x86_64-system.zip/download"
        fi
        if [ ! -f vendor11.zip ]; then
          echo "Downloading Android 11 vendor image..."
          wget -O vendor11.zip "https://sourceforge.net/projects/waydroid/files/images/vendor/waydroid_x86_64/lineage-18.1-20250621-MAINLINE-waydroid_x86_64-vendor.zip/download"
        fi
        echo "Extracting images to /var/lib/waydroid/images/..."
        unzip -o system11.zip -d /var/lib/waydroid/images/
        unzip -o vendor11.zip -d /var/lib/waydroid/images/
        rm system11.zip vendor11.zip
        echo "Waydroid Android 11 environment provisioned successfully."
      else
        echo "Waydroid Android 11 images are already present. Skipping download."
      fi
    '';
  };

  systemd.services.init-waydroid-houdini = {
    description = "Declarative installation of libhoudini translation layer for Waydroid";
    after = [ "init-waydroid-images.service" ];
    before = [ "waydroid-container.service" ];
    wantedBy = [ "multi-user.target" ];
    path = with pkgs; [ python3 python3Packages.pip python3Packages.virtualenv lzip unzip wget git coreutils waydroid bash ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      if [ ! -d /var/lib/waydroid/overlay/system/lib/arm ] && [ ! -d /var/lib/waydroid/overlay/system/lib64/arm64 ]; then
        echo "libhoudini ARM translation layer missing. Launching runtime environment..."
        cd /tmp
        rm -rf waydroid_script
        git clone https://github.com/casualsnek/waydroid_script.git
        cd waydroid_script
        python3 -m venv venv
        ./venv/bin/pip install -r requirements.txt
        ./venv/bin/python3 main.py install libhoudini
        cd /tmp
        rm -rf waydroid_script
        echo "libhoudini installed successfully."
      else
        echo "libhoudini translation layers are already active. Skipping script runtime."
      fi
    '';
  };

  systemd.services.waydroid-properties = {
    description = "Apply custom engine configurations for Delta Roblox execution";
    after = [ "waydroid-container.service" ];
    requires = [ "waydroid-container.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      sleep 3
      ${pkgs.waydroid}/bin/waydroid prop set persist.waydroid.fake_touch com.roblox.client
    '';
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

  system.stateVersion = "25.11"; 
}