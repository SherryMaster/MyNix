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
  
in
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      # Import the fetched nix-flatpak module
      "${nix-flatpak}/modules/nixos.nix"
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
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
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

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.sherry = {
    isNormalUser = true;
    shell = pkgs.zsh;
    description = "Shaheer Ahmed";
    extraGroups = [ "networkmanager" "wheel" "docker" "vboxusers"];
    packages = with pkgs; [
      kdePackages.kate
    #  thunderbird
    ];
    linger = true;
  };

  fonts.packages = with pkgs; [
    nerd-fonts.fira-code
    nerd-fonts.meslo-lg
  ];

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    
    # These plugins are game-changers
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;

    # Oh My Zsh framework
    ohMyZsh = {
      enable = true;
      plugins = [
        "git"      # Git aliases and status
        "sudo"     # Press ESC twice to add 'sudo' to your command
        "history"  # Better history management
        "z"        # Jump to frequently used directories quickly
      ];
      
      # 'agnoster' is a classic, beautiful theme that uses Powerline fonts
      theme = "jonathan"; # maran, simonoff, bureau, jonathan
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
    # Forces LibreOffice to use GTK3 or Qt5/6 positioning and styling
    # Use "gtk3" for GNOME/XFCE or "kf5" / "qt6" for KDE Plasma
    SAL_USE_VCLPLUGIN = "qt6";

    # Declare SPARK_HOME globally
    SPARK_HOME = "${pkgs.spark}";
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
  # --- C/C++ Global Toolchain ---
  gcc           # GNU Compiler Collection
  gnumake       # Make build automation
  cmake         # CMake build system
  gdb           # GNU Debugger
  clang-tools   # Provides clangd for IDE autocompletion
  # ------------------------------
  nix-your-shell
  wget
  fastfetch
  (google-chrome.override {
      commandLineArgs = [
        "--enable-features=NativeNotifications"
        "--ozone-platform-hint=auto"
        "--enable-wayland-ime"
      ];
    })
  git
  vscode
  alacritty
  zoom-us
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
  jetbrains.pycharm
  htop
  btop
  waydroid
  waydroid-helper
  unzip
  piper
  wasistlos
  libreoffice-fresh
  libnotify
  hunspell
  hunspellDicts.en_US
  ciscoPacketTracer8
  vlc
  unstable.godot
  (pkgs.writeShellScriptBin "packettracer-offline" ''
      exec ${pkgs.util-linux}/bin/unshare -r -n ${pkgs.ciscoPacketTracer8}/bin/packettracer8 "$@"
  '')

  # 2. Create the Desktop Shortcut to run that custom command
  (makeDesktopItem {
    name = "packettracer-offline-gui";
    desktopName = "Cisco Packet Tracer (Offline)";
    exec = "packettracer-offline %f"; 
    icon = "cisco-packet-tracer-8"; 
    terminal = false;
    type = "Application";
    categories = [ "Network" ];
  })
  (pkgs.writeShellScriptBin "opencode" ''
      exec ${pkgs.nodejs}/bin/npx -y opencode-ai@latest "$@"
  '')
  (pkgs.writeShellScriptBin "agy" ''
      # Define the exact path to the actual downloaded Go binary
      AGY_BIN="$HOME/.local/bin/agy"
      
      # Check if the actual binary exists, bypassing the wrapper's PATH
      if [ ! -f "$AGY_BIN" ]; then
          echo "Antigravity CLI not found locally. Installing via official script..."
          ${pkgs.curl}/bin/curl -fsSL https://antigravity.google/cli/install.sh | bash
          
          # Fallback if the installer places it in the gemini directory instead
          if [ ! -f "$AGY_BIN" ] && [ -f "$HOME/.gemini/antigravity-cli/bin/agy" ]; then
              AGY_BIN="$HOME/.gemini/antigravity-cli/bin/agy"
          fi
      fi
      
      # Execute the absolute path to prevent infinite loops
      exec "$AGY_BIN" "$@"
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
           # Create an executable wrapper using a Python environment that includes pygobject3
  (pkgs.stdenv.mkDerivation {
      pname = "m913-ctl-gui";
      version = "latest";

      src = pkgs.fetchFromGitHub {
        owner = "brunofin";
        repo = "m913-ctl-gui";
        rev = "main";
        hash = "sha256-uEXCNlX0ok5g6QU8OhwYMvoS88QF8RXYFvliyD1dt04=";
      };

      nativeBuildInputs = [ 
        pkgs.makeWrapper 
        pkgs.wrapGAppsHook4 
        pkgs.gobject-introspection 
      ];
      
      buildInputs = [ 
        pkgs.gtk4 
        pkgs.libadwaita 
      ];

      installPhase = ''
        mkdir -p $out/bin $out/opt/m913-ctl-gui
        
        # Copy the python source files
        cp -r m913_gui run.py $out/opt/m913-ctl-gui/
        
        # Create an executable wrapper using a Python environment that includes pygobject3
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

  # Udev rules to allow non-root user configuration of the M913
  services.udev.extraRules = ''
    # Redragon M913 Impact Elite (2.4GHz Wireless)
    SUBSYSTEM=="usb", ATTR{idVendor}=="25a7", ATTR{idProduct}=="fa07", MODE="0666"
    # Redragon M913 Impact Elite (Wired)
    SUBSYSTEM=="usb", ATTR{idVendor}=="25a7", ATTR{idProduct}=="fa08", MODE="0666"
  '';

  # Grant Free Download Manager access to mounted drives
  services.flatpak.overrides = {
    "org.freedownloadmanager.Manager".Context.filesystems = [
      "/mnt/Soft"
      "/mnt/Data" # Adding your other drive here too just in case!
    ];
  };

  services.hardware.openrgb = {
    enable = true;
    package = pkgs.openrgb-with-all-plugins; # Includes extra lighting effect tools
  };

  # Allow exprimental features
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Enable the VirtualBox host daemon and kernel modules
  virtualisation.virtualbox.host.enable = true;

  # OPTIONAL BUT RECOMMENDED: Enable Oracle Extension Pack for USB 2.0/3.0 and webcam support.
  virtualisation.virtualbox.host.enableExtensionPack = true;

  # Enable Waydroid
  virtualisation.waydroid.enable = true;
  
  # Enable the Docker daemon
  virtualisation.docker.enable = false;

  # Auto-Pruning (Save Disk Space)
  virtualisation.docker.autoPrune = {
    enable = true;
    dates = "weekly";
  };

  virtualisation.docker.daemon.settings = {
    dns = [ "8.8.8.8" "8.8.4.4" ];
  };

  # Start docker in rootless for security
  virtualisation.docker.rootless = {
    enable = true;
    setSocketVariable = true; # Points the 'docker' CLI to the rootless socket
  };

  systemd.services.waydroid-container = {
    serviceConfig = {
      Delegate = true;
    };
    preStart = ''
      mkdir -p /var/lib/waydroid
      touch /var/lib/waydroid/waydroid_base.prop
      
      # Clean out old entries if they exist
      sed -i '/gralloc.gbm.device/d' /var/lib/waydroid/waydroid_base.prop
      sed -i '/ro.hardware.gralloc/d' /var/lib/waydroid/waydroid_base.prop
      sed -i '/ro.hardware.egl/d' /var/lib/waydroid/waydroid_base.prop
      
      # Force-feed the correct graphics properties
      echo "gralloc.gbm.device=/dev/dri/renderD128" >> /var/lib/waydroid/waydroid_base.prop
      echo "ro.hardware.gralloc=gbm" >> /var/lib/waydroid/waydroid_base.prop
      echo "ro.hardware.egl=mesa" >> /var/lib/waydroid/waydroid_base.prop
    '';
  };

  # Waydroid requires a container system, which needs lxd or general network bridging enabled.
  # NixOS handles most of this under the hood with virtualisation.waydroid.enable, 
  # but you must ensure your firewall doesn't block the container's internet access.
  networking.firewall.trustedInterfaces = [ "waydroid0" ];

  # AUTOMATION 1: Declaratively download and handle Android 11 Images if missing
  systemd.services.init-waydroid-images = {
    description = "Declarative download and installation of Android 11 images for Waydroid";
    before = [ "waydroid-container.service" ];
    wantedBy = [ "multi-user.target" ];
    path = with pkgs; [ wget unzip ]; # Gives the script native access to these tools
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      mkdir -p /var/lib/waydroid/images
      
      # Check if the images are already installed
      if [ ! -f /var/lib/waydroid/images/system.img ] || [ ! -f /var/lib/waydroid/images/vendor.img ]; then
        echo "Waydroid Android 11 images missing. Starting automated installation..."
        
        cd /tmp
        
        # 1. Download System Image (GAPPS edition) if zip doesn't exist locally
        if [ ! -f system11.zip ]; then
          echo "Downloading Android 11 system image..."
          wget -O system11.zip "https://sourceforge.net/projects/waydroid/files/images/system/lineage/waydroid_x86_64/lineage-18.1-20250621-GAPPS-waydroid_x86_64-system.zip/download"
        fi
        
        # 2. Download Vendor Image if zip doesn't exist locally
        if [ ! -f vendor11.zip ]; then
          echo "Downloading Android 11 vendor image..."
          wget -O vendor11.zip "https://sourceforge.net/projects/waydroid/files/images/vendor/waydroid_x86_64/lineage-18.1-20250621-MAINLINE-waydroid_x86_64-vendor.zip/download"
        fi
        
        # 3. Extract them directly to the system directory
        echo "Extracting images to /var/lib/waydroid/images/..."
        unzip -o system11.zip -d /var/lib/waydroid/images/
        unzip -o vendor11.zip -d /var/lib/waydroid/images/
        
        # 4. Clean up the temp zip files to save space
        rm system11.zip vendor11.zip
        echo "Waydroid Android 11 environment provisioned successfully."
      else
        echo "Waydroid Android 11 images are already present. Skipping download."
      fi
    '';
  };

  # AUTOMATION 1.5: Declaratively install libhoudini translation layer via upstream repository
  systemd.services.init-waydroid-houdini = {
    description = "Declarative installation of libhoudini translation layer for Waydroid";
    after = [ "init-waydroid-images.service" ];
    before = [ "waydroid-container.service" ];
    wantedBy = [ "multi-user.target" ];
    
    # Provides all core utilities needed to build the translation translation layers safely
    path = with pkgs; [ python3 python3Packages.pip python3Packages.virtualenv lzip unzip wget git coreutils waydroid bash ];
    
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      # Check if arm translation folders are already present inside the container
      if [ ! -d /var/lib/waydroid/overlay/system/lib/arm ] && [ ! -d /var/lib/waydroid/overlay/system/lib64/arm64 ]; then
        echo "libhoudini ARM translation layer missing. Launching runtime environment..."
        
        cd /tmp
        rm -rf waydroid_script
        git clone https://github.com/casualsnek/waydroid_script.git
        cd waydroid_script
        
        # Isolate script execution inside a runtime virtual environment
        python3 -m venv venv
        ./venv/bin/pip install -r requirements.txt
        
        # Fire the installer
        ./venv/bin/python3 main.py install libhoudini
        
        # Clean up temp files
        cd /tmp
        rm -rf waydroid_script
        echo "libhoudini installed successfully."
      else
        echo "libhoudini translation layers are already active. Skipping script runtime."
      fi
    '';
  };

  # AUTOMATION 2: Automatically apply input spoofing parameters on boot
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
      # Forces touch emulation profile so game clients pass the splash screen loading cycle
      ${pkgs.waydroid}/bin/waydroid prop set persist.waydroid.fake_touch com.roblox.client
    '';
  };

  programs.nix-ld.enable = true;

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
    dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
    localNetworkGameTransfers.openFirewall = true; # Open ports for local network game transfers
  };

  programs.gamemode.enable = true;

  # If you want to use gamescope as well
  programs.gamescope.enable = true;

  systemd.services.waydroid-container.wantedBy = [ "multi-user.target" ];

  # Permanent mount for the 'Soft' drive
  fileSystems."/mnt/Soft" = {
    device = "/dev/disk/by-uuid/EA282ACC282A9799";
    fsType = "ntfs-3g";
    options = [ 
      "rw"
      "uid=1000"
      "gid=100"
      "nofail"
      "x-systemd.device-timeout=5s"
    ];
  };

  # Permanent mount for the 'Data' drive (Optional, but recommended)
  fileSystems."/mnt/Data" = {
    device = "/dev/disk/by-uuid/1C1839B518398EB0";
    fsType = "ntfs-3g";
    options = [ 
      "rw"
      "uid=1000"
      "gid=100"
      "nofail"
      "x-systemd.device-timeout=5s"
    ];
  };

  # --- APACHE KAFKA (KRaft Mode) ---
  
  # services.apache-kafka = {
  #   enable = true;
  #   clusterId = "muFUCn_OSq-6It9LTWlY1g"; 
  #   formatLogDirs = true; 

  #   settings = {
  #     "node.id" = 1;
  #     "process.roles" = [ "broker" "controller" ];
  #     "controller.listener.names" = [ "CONTROLLER" ];
  #     "controller.quorum.voters" = [ "1@127.0.0.1:9093" ];
  #     "listeners" = [ "PLAINTEXT://127.0.0.1:9092" "CONTROLLER://127.0.0.1:9093" ];
  #     "listener.security.protocol.map" = [ "CONTROLLER:PLAINTEXT" "PLAINTEXT:PLAINTEXT" ];
  #     "log.dirs" = [ "/var/lib/kafka/logs" ];
  #     "offsets.topic.replication.factor" = 1;
  #   };
  # };
  # --------------------------------------

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?

}
