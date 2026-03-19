let
  nixpkgs-src = fetchTarball "https://github.com/NixOS/nixpkgs/archive/nixos-25.11.tar.gz";
  pkgs = import nixpkgs-src {
    config = {
      allowUnfree = true;
    };
  };
in
# Create an FHS-compatible environment for running Synopsys VCS tools.
# FHS (Filesystem Hierarchy Standard) environments help proprietary software
# that expects standard Linux paths to work correctly under NixOS.
(pkgs.buildFHSEnv {
  name = "vcs-install-env";

  # List of packages to include in the environment.
  # These cover dependencies needed by VCS and typical EDA tools.
  targetPkgs =
    pkgs:
    (with pkgs; [
      # Core system libraries
      glibc
      libxcrypt-legacy # Older version some proprietary tools still need
      ncurses5 # Version 5 specifically for compatibility
      zlib
      expat # XML parsing library

      # GUI and graphics libraries (for tools with graphical interfaces)
      fontconfig
      freetype
      libGL
      libGLU

      # X11 window system libraries
      xorg.libX11
      xorg.libXext
      xorg.libXft
      xorg.libXrender
      xorg.libXp
      xorg.libXtst
      xorg.libXi
      xorg.libXScrnSaver
      xorg.libXcomposite
      xorg.libXcursor
      xorg.libXdamage
      xorg.libXrandr

      # Shells and common utilities
      tcsh # Some older EDA scripts still use tcsh
      bashInteractive # Interactive bash with readline support
      bc # Calculator tool, used in some scripts
      gnumake # Build system
      gcc # C compiler
      binutils # Binary utilities (ld, ar, etc.)
      perl # Lots of EDA tooling uses Perl
      python3 # Modern tooling often uses Python
      nettools # Provides netstat, ifconfig, etc.
      coreutils # Basic Unix utilities (ls, cp, mv, etc.)
      which # Locates executables in PATH
      procps # Process utilities (free, top, ps) - some scripts need these
    ]);

  # Environment setup that runs when the shell starts.
  # This sets up paths and variables specific to Synopsys tools.
  profile = ''
    # Handy alias to reload shell config without restarting
    alias ref="source ~/.zshrc"

    # Basic environment variables
    export HOME_DIR="/opt/synopsys"  # Where Synopsys tools are installed

    # Point to the license server - adjust hostname as needed
    export LM_LICENSE_FILE=27000@localhost.localdomain

    # Synopsys Common Licensing (flexlm) setup
    export SCL_HOME="$HOME_DIR/scl/2021.03"
    export PATH="$SCL_HOME/linux64/bin:$PATH"

    # Shortcut to start the license manager.
    # Note: The license file path might need adjustment based on your setup.
    alias lm="$SCL_HOME/linux64/bin/lmgrd -c $SCL_HOME/Synopsys.dat"

    # VCS (Verilog Compiler Simulator) setup
    export VCS_HOME="$HOME_DIR/vcs/W-2024.09-SP1"
    export PATH="$VCS_HOME/bin:$PATH"

    echo "--- Synopsys VCS & SCL Install Environment Loaded ---"
    echo "VCS_HOME: $VCS_HOME"
  '';

}).env
