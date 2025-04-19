{
  description = "Makes kubectl plug-ins from the Krew repository accessible to Nix";
  inputs = {
    # keep-sorted start block=yes case=no
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    systems.url = "github:nix-systems/default";
    treefmt-nix = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:numtide/treefmt-nix";
    };
    # keep-sorted end
  };
  outputs =
    {
      self,
      flake-utils,
      nixpkgs,
      treefmt-nix,
      systems,
    }:
    {
      overlay = import overlays/.;
    }
    // flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          overlays = [ self.overlay ];
          inherit system;
        };
        treefmtEval = treefmt-nix.lib.evalModule pkgs ./treefmt.nix;
        environ = {
          default.buildInputs = [
            pkgs.ruby
            pkgs.curl
          ];
          default.nativeBuildInputs = [ pkgs.cacert ];
          testing = {
            buildInputs =
              with pkgs;
              [
                k9s
                kubernetes-helm
                (kubectl.withKrewPlugins (
                  plugins: with plugins; [
                    # keep-sorted start
                    change-ns
                    images
                    krew
                    node-shell
                    # keep-sorted end
                  ]
                ))
              ]
              ++ environ.default.buildInputs;
          };
        };
      in
      with pkgs;
      {
        formatter = treefmtEval.config.build.wrapper;
        legacyPackages = self.packages.${system};
        packages = {
          default = self.packages.${system}.kubectl;
          inherit (pkgs) kubectl;
        };
        devShells = {
          ci = pkgs.mkShell { inherit (environ.default) buildInputs nativeBuildInputs; };
          default = pkgs.mkShell { inherit (environ.default) buildInputs nativeBuildInputs; };
          testing = pkgs.mkShell { inherit (environ.testing) buildInputs; };
        };
      }
    );
}
