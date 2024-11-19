docker-build:
  docker run --privileged --rm -it -v ./:/workdir ghcr.io/joeyeamigh/nixos-superbird/builder:latest

build:
  nix build '.#nixosConfigurations.superbird.config.system.build.installer' -j"$(nproc)" --show-trace

installer:
  #!/usr/bin/env bash
  set -euo pipefail

  nix build '.#nixosConfigurations.superbird.config.system.build.installer' -j$(nproc) --show-trace
  echo "kernel is $(stat -Lc%s -- result/linux/kernel | numfmt --to=iec)"
  echo "initrd is $(stat -Lc%s -- result/linux/initrd.img | numfmt --to=iec)"
  echo "rootfs (sparse) is $(stat -Lc%s -- result/linux/rootfs.img | numfmt --to=iec)"

  sudo rm -rf ./out
  mkdir ./out
  cp -r ./result/* ./out/
  chown -R $(whoami):$(whoami) ./out
  cd ./out

  sudo ./scripts/shrink-img.sh
  echo "rootfs (compact) is $(stat -Lc%s -- ./linux/rootfs.img | numfmt --to=iec)"

ssh:
  ssh -i ./out/ssh/ssh_host_ed25519_key root@172.16.42.2

run-installer:
  just installer
  cd out && ./install.sh

zip-installer:
  #!/usr/bin/env bash
  set -euo pipefail

  cd ./out/
  zip -r nixos-superbird-installer.zip .

push:
  nix run github:serokell/deploy-rs