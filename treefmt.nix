{ pkgs, ... }:
{
  # keep-sorted start block=yes newline_separated=yes prefix_order=projectRootFile,
  projectRootFile = "flake.nix";

  programs.deadnix.enable = true;

  programs.keep-sorted.enable = true;

  programs.mdformat.enable = true;

  programs.mdsh.enable = true;

  programs.nixfmt = {
    enable = true;
    package = pkgs.nixfmt-rfc-style;
  };

  programs.rufo.enable = true;

  programs.statix.enable = true;

  # Disabled on "flake.nix" because of some false positivies.
  settings.formatter.deadnix.excludes = [ "**/flake.nix" ];
  # keep-sorted end
}
