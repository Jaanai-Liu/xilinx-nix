{
  pkgs ? import <nixpkgs> { },
  fetchFromGitHub,
  getEnv',
}:
let
  nixpkgsSrcs = fetchFromGitHub {
    owner = "NixOS";
    repo = "nixpkgs";
    rev = "c374d94f1536013ca8e92341b540eba4c22f9c62";
    hash = "sha256-Z/ELQhrSd7bMzTO8r7NZgi9g5emh+aRKoCdaAv5fiO0=";
  };

  lockedPkgs = import nixpkgsSrcs { system = "x86_64-linux"; };
  gcc9 = pkgs.lib.hiPrio lockedPkgs.gcc9;

  xilinxHome = getEnv' "XILINX_STATIC_HOME";
  vcStaticHome = getEnv' "VC_STATIC_HOME";
  lmLicenseFile = getEnv' "LM_LICENSE_FILE";
in
pkgs.buildFHSEnv {
  name = "xilinx-fhs-env";

  profile = ''
    export LC_NUMERIC="en_US.UTF-8"
    echo "[Debug] Pre-source path: $(which gcc || echo 'not found')"
    echo "[Debug] GCC Version: $(gcc --version | head -n 1)"

    if [ -d "${xilinxHome}/Vivado" ]; then
      for s in ${xilinxHome}/Vivado/*/settings64.sh; do
        if [ -f "$s" ]; then
          echo "[FHS] Sourcing Vivado settings from $s"
          source "$s"
        fi
      done
    fi
    if [ -d "${xilinxHome}/Vitis_HLS" ]; then
      for s in ${xilinxHome}/Vitis_HLS/*/settings64.sh; do
        if [ -f "$s" ]; then
          echo "[FHS] Sourcing Vitis_HLS settings from $s"
          source "$s"
        fi
      done
    fi

    if [ -d "${xilinxHome}/Vitis" ]; then
      for s in ${xilinxHome}/Vitis/*/settings64.sh; do
        if [ -f "$s" ]; then
          echo "[FHS] Sourcing Vitis settings from $s"
          source "$s" 
        fi
      done
    fi
    echo "[FHS] Xilinx FHS Environment Loaded."
    export LD_LIBRARY_PATH="$ORIGINAL_LD_PATH"
    export PATH="$ORIGINAL_PATH:$PATH"

    export VC_STATIC_HOME=${vcStaticHome}
    export TCL_TZ=UTC
    export VC_STATIC_HOME=$VC_STATIC_HOME
    export VCS_HOME=$VC_STATIC_HOME/vcs/W-2024.09-SP1
    export VCS_TARGET_ARCH=amd64
    export VCS_ARCH_OVERRIDE=linux
    export VERDI_HOME=$VC_STATIC_HOME/verdi/W-2024.09-SP1
    export NOVAS_HOME=$VC_STATIC_HOME/verdi/W-2024.09-SP1
    export SNPS_VERDI_CBUG_LCA=1
    export LM_LICENSE_FILE=${lmLicenseFile}

    export PATH=$PATH:$VCS_HOME/gui/dve/bin:$PATH
    export PATH=$PATH:$VCS_HOME/bin:$PATH
    export PATH=$PATH:$VERDI_HOME/bin:$PATH
    export PATH=$PATH:$SCL_HOME/linux64/bin:$PATH

    export QT_X11_NO_MITSHM=1
    export LD_LIBRARY_PATH=/usr/lib64/
    export LD_LIBRARY_PATH=$VERDI_HOME/share/PLI/lib/LINUX64:$LD_LIBRARY_PATH
    export LD_LIBRARY_PATH=$VERDI_HOME/share/NPI/lib/LINUX64:$LD_LIBRARY_PATH
    echo "[Debug] Unified EDA Environment Loaded."

    echo "[Debug] Post-source path: $(which gcc || echo 'not found')"
    echo "[Debug] GCC Version: $(gcc --version | head -n 1)"

    export _oldVcsEnvPath="$PATH"
    preHook() {
      PATH="$PATH:$_oldVcsEnvPath"
    }
    export -f preHook

    echo "[FHS] VCS FHS Environment Loaded."
  '';

  targetPkgs = (
    ps:
    with ps;
    let
      ncurses' = ncurses5.overrideAttrs (old: {
        configureFlags = old.configureFlags ++ [ "--with-termlib" ];
        postFixup = "";
      });
    in
    [
      bash
      coreutils
      zlib
      lsb-release
      stdenv.cc.cc

      # https://github.com/NixOS/nixpkgs/issues/218534
      # postFixup would create symlinks for the non-unicode version but since it breaks
      # in buildFHSEnv, we just install both variants
      ncurses'
      (ncurses'.override { unicodeSupport = false; })
      xorg.libXext
      xorg.libX11
      xorg.libXrender
      xorg.libXtst
      xorg.libXi
      xorg.libXft
      xorg.libxcb
      xorg.libxcb
      # common requirements
      freetype
      fontconfig
      glib
      gtk2
      gtk3
      libxcrypt-legacy # required for Vivado
      python3

      (libidn.overrideAttrs (_old: {
        # we need libidn.so.11 but nixpkgs has libidn.so.12
        src = fetchurl {
          url = "mirror://gnu/libidn/libidn-1.34.tar.gz";
          sha256 = "sha256-Nxnil18vsoYF3zR5w4CvLPSrTpGeFQZSfkx2cK//bjw=";
        };
      }))
      gcc9
      which

      # to compile some xilinx examples
      opencl-clhpp
      ocl-icd
      opencl-headers

      # from installLibs.sh
      graphviz
      unzip
      nettools

      # vcs simulation requirements
      bc
      elfutils
      time
      util-linux
      libnsl
      binutils
    ]
  );
}
