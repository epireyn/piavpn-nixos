{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) mkOption mkIf types;
  inherit (import ./utils.nix) callPiaWithDeps;
  cfg = config.services.piavpn;
  pkg = cfg.package;
in
{
  options.services.piavpn = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable the Private Internet Access VPN service.";
    };
    package = mkOption {
      type = types.package;
      default = callPiaWithDeps pkgs;
      description = "Set PIA package to be used";
    };
  };

  config = mkIf cfg.enable ({
    assertions = [
      {
        assertion = config.networking.networkmanager.enable;
        message = "services.piavpn requires networking.networkmanager to be enabled";
      }
    ];

    environment.systemPackages = [ pkg ];

    systemd.services.piavpn = {
      description = "Private Internet Access VPN Daemon";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "/opt/piavpn/bin/pia-daemon-wrapped";
        Restart = "on-failure";
        User = "root";
        Group = pkg.groupName;
        BindReadOnlyPaths = [ "${pkgs.bash}/bin/bash:/bin/bash"] ++ (map (x: "${pkg + pkg.piaOptDir}/${x}:${pkg.piaOptDir}/${x}") ["bin" "lib" "share"]);
        BindPaths = ["/etc/piavpn:${pkg.piaOptDir}/etc" "/var/lib/piavpn:${pkg.piaOptDir}/var"];
      };
    };

    systemd.tmpfiles.rules = [
      "d /etc/piavpn 0755 root ${pkg.groupName} -"
    ];

    networking = {

      wireguard.enable = true;
      networkmanager = {
        enable = true;
        unmanaged = [ "interface-name:wgpia*" ];
      };
    };

    users.groups = {
      piavpn = { };
      piahnsd = { };
    };

    environment.etc."apport/blacklist.d/piavpn".text = ''
      /opt/piavpn/bin/pia-client
      /opt/piavpn/bin/pia-daemon
    '';

    security.wrappers = {
      "pia-unbound" = {
        source = "${pkg}/opt/piavpn/bin/pia-unbound";
        capabilities = "cap_net_bind_service+ep";
        owner = "root";
        group = "root";
      };
    };
  });
}
