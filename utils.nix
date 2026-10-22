{
  callPiaWithDeps =
    pkgs:
    import ./package.nix {
      inherit (pkgs)
        stdenv
        lib
        qt6
        makeWrapper
        xterm
        openssl
        libnl
        libnsl
        libatomic_ops
        fetchurl
        autoPatchelfHook
        libcap_ng
        bash
        libxkbcommon
        psmisc
        makeDesktopItem
        copyDesktopItems
        iptables
        iproute2
        gawk
        mount
        systemd
        openresolv
        util-linux
        coreutils
        ;
    };
}
