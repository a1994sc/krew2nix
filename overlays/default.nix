final: prev: rec {
  krew-plugin-bin = import ../. { pkgs = final; };
  kubectl = prev.kubectl.overrideAttrs (_: {
    passthru.withKrewPlugins =
      selectPlugins:
      let
        selectedPlugins = selectPlugins krew-plugin-bin.plugins;
        kubectlWrapper =
          final.runCommand "kubectl-with-plugins-wrapper"
            {
              nativeBuildInputs = [
                final.makeWrapper
                final.installShellFiles
              ];
              meta.priority = final.kubectl.meta.priority or 0 + 10;
            }
            ''
              makeWrapper ${final.kubectl}/bin/kubectl $out/bin/kubectl --prefix PATH : ${final.lib.makeBinPath selectedPlugins}

              installShellCompletion --cmd kubectl \
                --bash <($out/bin/kubectl completion bash) \
                --fish <($out/bin/kubectl completion fish) \
                --zsh <($out/bin/kubectl completion zsh)
            '';
      in
      final.buildEnv {
        name = "${final.kubectl.name}-with-plugins";
        paths = [ kubectlWrapper ];
      };
  });
}
