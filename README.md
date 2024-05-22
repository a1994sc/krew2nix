# krew2nix

[![.github/workflows/update-flake-lock.yml](https://github.com/a1994sc/krew2nix/actions/workflows/update-flake-lock.yml/badge.svg?branch=main)](https://github.com/a1994sc/krew2nix/actions/workflows/update-flake-lock.yml)

TL/DR:

### NixOS

```nix
  environment.systemPackages = [ kubectl.withKrewPlugins (plugins: [ plugins.node-shell ]) ];
```

### NixOS

```nix
  home.packages = [ kubectl.withKrewPlugins (plugins: [ plugins.node-shell ]) ];
```

## Examples

### devShell

```nix
{
  inputs = {
    # keep-sorted start block=yes case=no
    krew2nix = {
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.systems.follows = "systems";
      url = "github:a1994sc/krew2nix";
    };
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable-small";
    systems.url = "github:nix-systems/default";
    # keep-sorted end
  };
  outputs = { nixpkgs, flake-utils, krew2nix, ... }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
      inherit (krew2nix.packages.${system}) kubectl;
    in {
      devShell = pkgs.mkShell {
        nativeBuildInputs = [ pkgs.bashInteractive ];
        buildInputs = [
          pkgs.k9s
          pkgs.kubernetes-helm
          (kubectl.withKrewPlugins (plugins: with plugins; [
            df-pv
            krew
            node-shell
          ]))
        ];
      };
    });
}
```

Enter with `nix develop`.
