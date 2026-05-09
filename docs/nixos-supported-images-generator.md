# Supported images by the nixos-generator

> To check what images are supported by the generator execute

```sh
nix eval --json ./nixos-generator#nixosConfigurations.dbserver.config.system.build.images --apply builtins.attrNames
```
