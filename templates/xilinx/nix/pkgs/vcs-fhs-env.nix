# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2024 Jiuyang Liu <liu@jiuyang.me>

# This is a bit dirty. Since VCS are close source toolchains, we have no way to fix it for environment changes.
# So here we have to lock the whole nixpkgs to a working version.
#
# For convenience, we still use the nixpkgs defined in flake to "callPackage" this derivation.
# But the buildFHSEnv, targetPkgs is still from the locked nixpkgs.
{ getEnv', fetchFromGitHub }:
let
  nixpkgsSrcs = fetchFromGitHub {
    owner = "NixOS";
    repo = "nixpkgs";
    rev = "c374d94f1536013ca8e92341b540eba4c22f9c62";
    hash = "sha256-Z/ELQhrSd7bMzTO8r7NZgi9g5emh+aRKoCdaAv5fiO0=";
  };

  # The vcs we have only support x86-64_linux
  lockedPkgs = import nixpkgsSrcs { system = "x86_64-linux"; };

  vcStaticHome = getEnv' "VC_STATIC_HOME";
  lmLicenseFile = getEnv' "LM_LICENSE_FILE";
in
lockedPkgs.buildFHSEnv {
  name = "vcs-fhs-env";
  profile = ''
    [ ! -e "${vcStaticHome}"  ] && echo "env VC_STATIC_HOME='${vcStaticHome}' points to unknown location" && exit 1
    [ ! -d "${vcStaticHome}"  ] && echo "VC_STATIC_HOME='${vcStaticHome}' not accessible" && exit 1
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

    export _oldVcsEnvPath="$PATH"
    preHook() {
      PATH="$PATH:$_oldVcsEnvPath"
    }
    export -f preHook
  '';
  targetPkgs = (
    ps: with ps; [
      libGL
      util-linux
      libxcrypt-legacy
      coreutils-full
      ncurses5
      gmp5
      bzip2
      glib
      bc
      time
      elfutils
      ncurses5
      e2fsprogs
      cyrus_sasl
      expat
      sqlite
      nssmdns
      (libkrb5.overrideAttrs rec {
        version = "1.18.2";
        src = fetchurl {
          url = "https://kerberos.org/dist/krb5/${lib.versions.majorMinor version}/krb5-${version}.tar.gz";
          hash = "sha256-xuTJ7BqYFBw/XWbd8aE1VJBQyfq06aRiDumyIIWHOuA=";
        };
        sourceRoot = "krb5-${version}/src";
      })
      (gnugrep.overrideAttrs rec {
        version = "3.1";
        doCheck = false;
        src = fetchurl {
          url = "mirror://gnu/grep/grep-${version}.tar.xz";
          hash = "sha256-22JcerO7PudXs5JqXPqNnhw5ka0kcHqD3eil7yv3oH4=";
        };
      })

      keyutils
      graphite2
      libpulseaudio
      libxml2
      gcc
      gnumake
      xorg.libX11
      xorg.libXft
      xorg.libXScrnSaver
      xorg.libXext
      xorg.libxcb
      xorg.libXau
      xorg.libXrender
      xorg.libXcomposite
      xorg.libXi
      zlib

      # --- 2024 Verdi XCB -by Jaanai ---
      xorg.xcbutilwm # 提供 libxcb-icccm.so.4 (解决你当前的报错)
      xorg.xcbutilimage # 提供 libxcb-image.so.0
      xorg.xcbutilkeysyms # 提供 libxcb-keysyms.so.1
      xorg.xcbutilrenderutil # 提供 libxcb-render-util.so.0
      xorg.xcbutil # 基础 XCB util 库

      # Synopsys debug tools dependencies
      gdb
      strace

      # verdi other dependencies
      dejavu_fonts
      freetype
      fontconfig
      xorg.libXcursor
      xorg.libXinerama
      xorg.libXtst
      xorg.libXt
      xorg.libXmu
      xorg.libXpm
      xorg.libXaw
      xorg.libSM
      xorg.libICE
      xorg.libXrandr
      numactl
      libpng
      libjpeg
      expat
    ]
  );
}
