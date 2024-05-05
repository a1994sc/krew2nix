{
  description = "Makes kubectl plug-ins from the Krew repository accessible to Nix";
  inputs = {
    # keep-sorted start block=yes case=no
    flake-utils.url = "github:numtide/flake-utils";
    krew-index = {
      url = "github:kubernetes-sigs/krew-index";
      flake = false;
    };
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
      krew-index,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        krewPlugins = pkgs.callPackage ./krew-plugins.nix { inherit krew-index; };
        kubectl = pkgs.callPackage ./kubectl.nix { inherit krew-index; };
        treefmtEval = treefmt-nix.lib.evalModule pkgs ./treefmt.nix;
      in
      with pkgs;
      {
        packages = krewPlugins // {
          inherit kubectl;
        };
        formatter = treefmtEval.config.build.wrapper;
        devShell = pkgs.mkShell {
          nativeBuildInputs = [ pkgs.bashInteractive ];
          buildInputs = [
            pkgs.k9s
            pkgs.kubernetes-helm
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
          ];
        };
      }
    );
}
