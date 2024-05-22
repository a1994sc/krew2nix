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

      # # per krew spec the only two supported archives are `.zip` and `.tar.gz`.
      # # https://krew.sigs.k8s.io/docs/developer-guide/plugin-manifest/
      # unpackPhase =
      #   ''
      #     mkdir extract plugin
      #     if [[ $src == *.zip ]] then
      #       unzip -o $src -d extract
      #     else
      #       tar -xzf $src -C extract
      #     fi
      #   ''
      #   + (files archSrc);

      nativeBuildInputs = [ unzip ] ++ (lib.optionals (!stdenv.isDarwin) [ autoPatchelfHook ]);

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

      # # The upstream terraform wrapper assumes the provider filename here.
      # installPhase = ''
      #   dir=$out/${krew-prefix}/${plugin}
      #   mkdir -p "$dir"
      #   mv plugin/* "$dir/"
      # '';
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
