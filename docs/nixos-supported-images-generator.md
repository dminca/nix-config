# Supported Images in nixos-generator

Diataxis type: Reference

Use this command to list available image outputs exposed by the `nixos-generator` flake configuration.

## Command

```sh
nix eval --json ./nixos-generator#nixosConfigurations.dbserver.config.system.build.images --apply builtins.attrNames
```

## Output

- JSON array of image attribute names that can be built from that configuration.
