{ pkgs, ... }:
{
  # keep-sorted start block=yes newline_separated=yes prefix_order=projectRootFile,
  projectRootFile = "flake.nix";

  programs.keep-sorted.enable = true;

  programs.mdformat.enable = true;

  programs.mdsh.enable = true;

  programs.nixfmt = {
    enable = true;
    package = pkgs.nixfmt-rfc-style;
  };

  programs.rufo.enable = true;

  programs.statix.enable = true;
  # keep-sorted end
}
