final: prev: rec {
  krew-plugin-bin = import ../. { pkgs = final; };
  kubectl = prev.kubectl.overrideAttrs (_: {
    passthru.withKrewPlugins =
      selectPlugins:
      let
        selectedPlugins = selectPlugins krew-plugin-bin.plugins;
        pluginsDir = final.symlinkJoin {
          name = "kubectl-plugins";
          paths = selectedPlugins;
        };
        kubectlWrapper =
          final.runCommand "kubectl-with-plugins-wrapper"
            {
              nativeBuildInputs = [ final.makeWrapper ];
              meta.priority = final.kubectl.meta.priority or 0 + 10;
            }
            ''
              makeWrapper ${final.kubectl}/bin/kubectl $out/bin/kubectl --prefix PATH : ${final.lib.makeBinPath selectedPlugins}
            '';
            # --set KREW_ROOT "${pluginsDir}"
      in
      final.buildEnv {
        name = "${final.kubectl.name}-with-plugins";
        paths = [ kubectlWrapper ];
      };
  });
}
