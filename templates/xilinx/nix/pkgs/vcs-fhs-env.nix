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
  lockedPkgs = import nixpkgsSrcs {
    system = "x86_64-linux";
    # allow unfree by jaanai
    config = {
      allowUnfree = true;
      permittedInsecurePackages = [
        "qtwebkit-5.212.0-alpha4"
      ];
    };
    ###############################
  };

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

    # add verdi lib by jaanai
    export LD_LIBRARY_PATH=$VERDI_HOME/platform/LINUXAMD64/lib:$LD_LIBRARY_PATH    
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

      # --- 2024 Verdi XCB -by jaanai ---
      xorg.xcbutilwm # 提供 libxcb-icccm.so.4 (解决你当前的报错)
      xorg.xcbutilimage # 提供 libxcb-image.so.0
      xorg.xcbutilkeysyms # 提供 libxcb-keysyms.so.1
      xorg.xcbutilrenderutil # 提供 libxcb-render-util.so.0
      xorg.xcbutil # 基础 XCB util 库
      xorg.libXdamage # 解决 libXdamage.so.1
      xorg.libXfixes # 解决 libXfixes.so.3 (当前报错)
      xorg.libXcursor # 解决光标显示问题
      xorg.libXcomposite # 解决窗口合成问题
      alsa-lib # 解决 libasound.so.2 (当前报错)
      xorg.libXfixes
      xorg.libXcursor
      xorg.libXdamage
      xorg.libXcomposite
      xorg.libXinerama
      xorg.libXi
      xorg.libXrandr
      xorg.libXScrnSaver
      xorg.libXft
      libxslt # 解决 libxslt.so.1 (当前报错)
      libxml2 # 确保这个也在
      libselinux # 解决 libselinux.so.1 (当前报错)
      libsepol # libselinux 的依赖
      pcre2 # libselinux 的依赖
      libthai # 很多现代 UI 框架（如 Pango）的依赖
      libdatrie # libthai 的依赖
      libxkbcommon # 解决你现在的 libxkbcommon-x11 报错
      dbus # 解决进程间通信报错
      at-spi2-core # 解决辅助功能框架报错
      libdrm # 解决直接渲染管理报错
      mesa # 提供完整的 OpenGL 支持
      nss # 提供 libsmime3.so, libnss3.so 等
      nspr # nss 的依赖库
      atk # 辅助功能框架
      at-spi2-atk # 辅助功能桥接
      at-spi2-core # 辅助功能核心
      libdrm # 显卡直接渲染管理
      mesa # OpenGL 支持
      libxkbcommon # 键盘映射 (解决上一个报错)
      gtk3 # 很多 2024 工具的对话框需要它
      pango # 字体渲染
      cairo # 2D 图形渲染
      gdk-pixbuf # 图片加载
      cups # 打印支持（有些 UI 组件会查这个）
      qt5.qtbase # 核心：Gui, Core, Widgets, Network, Sql
      qt5.qtx11extras # 解决 libQt5X11Extras.so.5
      qt5.qtcharts # 解决 libQt5Charts.so.5
      qt5.qtwebengine # 解决 libQt5WebEngine*.so
      qt5.qtwebkit # 解决 libQt5WebKit*.so (老版 Web 引擎)
      qt5.qtwebchannel # 解决 libQt5WebChannel.so.5
      qt5.qtscript # 解决 libQt5Script.so.5
      qt5.qtdeclarative
      qt5.qtwebview
      tbb # 解决 libtbb.so.12 (并行计算库)
      libpng12 # 解决 libpng12.so.0 (老版图片库，Verdi 强依赖)

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
