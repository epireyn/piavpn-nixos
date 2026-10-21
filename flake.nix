{
  description = "Private Internet Access (PIA) VPN - Nix flake";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

  outputs =
    { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfreePredicate = pkg: pkgs.lib.getName pkg == "piavpn";
      };

      inherit (import ./utils.nix) callPiaWithDeps;
    in
    {
      packages.${system} = rec {
        default = piavpn;
        piavpn = callPiaWithDeps pkgs;
      };

      nixosModules.piavpn = import ./module.nix;
    };
}
