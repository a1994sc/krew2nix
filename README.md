# krew2nix

[![.github/workflows/update-flake-lock.yml](https://github.com/a1994sc/krew2nix/actions/workflows/update-flake-lock.yml/badge.svg?branch=main)](https://github.com/a1994sc/krew2nix/actions/workflows/update-flake-lock.yml)

TL/DR:

The examples use flakes as the primary way to get the krew support into nix.

### NixOS

```nix
  nixpkgs.overlays = [ inputs.krew2nix.overlay ];
  environment.systemPackages = [ kubectl.withKrewPlugins (plugins: [ plugins.node-shell ]) ];
```

### Home-manager

```nix
  nixpkgs.overlays = [ inputs.krew2nix.overlay ];
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
      pkgs = import nixpkgs {
        overlays = [ self.overlay ];
        inherit system;
      };
    in {
      devShell = pkgs.mkShell {
        nativeBuildInputs = [ pkgs.bashInteractive ];
        buildInputs = with pkgs;[
          k9s
          (wrapHelm kubernetes-helm {
            plugins = with pkgs; [ 
              kubernetes-helmPlugins.helm-secrets
              kubernetes-helmPlugins.helm-unittest
            ];
          })
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
