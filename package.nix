{
  stdenv,
  lib,
  fetchurl,
  makeWrapper,
  qt6,
  autoPatchelfHook,
  wrapQtAppsHook ? qt6.wrapQtAppsHook,
  libcap_ng,
  bash,
  libnl,
  iptables,
  xterm,
  libnsl,
  libatomic_ops,
  libxkbcommon,
  psmisc,
  makeDesktopItem,
  copyDesktopItems,
  installOutDir ? "$out/opt/piavpn",
  iproute2,
  gawk,
  mount,
  systemd,
  openresolv,
  util-linux,
  coreutils,
  xkeyboardconfig,
  ...
}:
stdenv.mkDerivation rec {
  pname = "piavpn";
  version = "3.8-08539";

  src = fetchurl {
    url = "https://installers.privateinternetaccess.com/download/pia-linux-${version}.run";
    sha256 = "sha256-o88uK1DSlpO6WPCuIy5SxXhfAkSlbm7QBbaEsYdnOZ8=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
    wrapQtAppsHook
    copyDesktopItems
  ];

  buildInputs = [
    qt6.qtbase
    qt6.qtwayland
    qt6.qt3d
    qt6.qtquicktimeline
    qt6.qtvirtualkeyboard
    qt6.qtlottie
    qt6.qtscxml
    libcap_ng

    bash

    libxkbcommon
    libnl.out
    libnsl.out
    iptables
    psmisc
    libatomic_ops
    xterm
    iproute2
  ];

  desktopItems = [
    (makeDesktopItem {
      name = pname;
      desktopName = "Private Internet Access (PIA)";
      comment = "Private Internet Access VPN client";
      exec = "${passthru.piaOptDir}/bin/pia-client %u";
      icon = pname;
      terminal = false;
      categories = [ "Network" ];
      keywords = [
        "pia"
        "vpn"
      ];
      startupWMClass = "pia-client";
      mimeTypes = [ "x-scheme-handler/piavpn" ];
    })
  ];

  dontBuild = true;

  unpackPhase = ''
    runHook preUnpack

    sh $src --target . --noexec --keep

    runHook postUnpack
  '';

  passthru = {
    groupName = pname;
    libDir = "${installOutDir}/lib";
    piaOptDir = "/opt/piavpn";
  };

  installPhase = ''
    runHook preInstall

    mkdir -p ${installOutDir}
    cp -a ./piafiles/* ${installOutDir}

    for binary in pia-client pia-daemon pia-hnsd pia-openvpn pia-ss-local pia-support-tool pia-unbound pia-wireguard-go piactl support-tool-launcher; do
      makeWrapper ${installOutDir}/bin/$binary ${installOutDir}/bin/$binary-wrapped \
        --prefix PATH : "${
          lib.makeBinPath [
            iptables
            psmisc
            iproute2
            gawk
            mount
            systemd
            openresolv
            util-linux
            coreutils
          ]
        }" \
        --prefix LD_LIBRARY_PATH : "${
          lib.makeLibraryPath [
            installOutDir
            libxkbcommon
            libnl.out
            libnsl.out
          ]
        }" \
      --set QT_QPA_PLATFORM xcb \
      --set QT_XKB_CONFIG_ROOT "${xkeyboardconfig}/share/X11/xkb"
    done

    mkdir -p $out/share/icons/hicolor/128x128/apps
    cp ./installfiles/app-icon.png $out/share/icons/hicolor/128x128/apps/piavpn.png

    substituteInPlace ${installOutDir}/bin/openvpn-updown.sh \
      --replace-fail "/usr/bin/busctl" "${systemd}/bin/busctl"

    mkdir -p $out/bin

    for binary in piactl pia-client; do
      ln -s ${installOutDir}/bin/$binary-wrapped $out/bin/$binary
    done

    runHook postInstall
  '';

  meta = {
    description = "Private Internet Access (PIA) VPN client";
    homepage = "https://www.privateinternetaccess.com/";
    license = lib.licenses.unfree;
    maintainers = with lib.maintainers; [ epireyn ];
    platforms = [ "x86_64-linux" ];
  };
}
