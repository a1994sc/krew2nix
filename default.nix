{ pkgs, ... }:
let
  inherit (pkgs)
    lib
    stdenv
    unzip
    autoPatchelfHook
    ;

  krew-prefix = "krew-plugin";

  fetchArchURL =
    system: archSrc:
    let
      src = archSrc.${system} or (throw "system ${system} not supported");
    in
    pkgs.fetchurl { inherit (src) url sha256; };

  mkKrewPlugin =
    {
      plugin,
      version,
      archSrc,
      homepage,
      description,
    }:
    let
      inherit (pkgs.stdenv.hostPlatform) system;
      files =
        archSrc':
        lib.concatStringsSep "\n" (
          map (file: ''
            cp -a ./${file.from} $out/lib/${file.to}
          '') archSrc'.${system}.files
        );
      pluginBinaryName = "kubectl-${builtins.replaceStrings [ "-" ] [ "_" ] plugin}";
    in
    stdenv.mkDerivation {
      pname = "${krew-prefix}-${plugin}";
      inherit version;
      src = fetchArchURL system archSrc;
      sourceRoot = ".";
      dontBuild = true;

      nativeBuildInputs = [unzip ] ++ lib.optionals stdenv.isLinux [ autoPatchelfHook ];

      installPhase = ''
        runHook preInstall
        mkdir -p $out/{bin,lib}
        ${files archSrc}
        ln -s $out/lib/${archSrc.${system}.bin} $out/bin/${pluginBinaryName}
        runHook postInstall
      '';

      meta = {
        inherit description homepage;
      };
    };

  plugins = lib.mapAttrs (
    name: type:
    if type == "directory" then
      let
        data = lib.importJSON (./plugins + "/${name}/default.json");
      in
      mkKrewPlugin data
    else
      null
  ) (builtins.readDir ./plugins);
in
{
  inherit mkKrewPlugin plugins;
}
