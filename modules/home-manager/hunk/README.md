# Hunk Git difftool

This Home Manager module installs [Hunk](https://www.hunk.dev/) from the
existing locked `nixpkgs-unstable` input and makes it the default Git difftool.
It is enabled on `MLGERHL6W4P2RXH` only.

The shared `modules/home-manager` import exposes the option; enable it in a
host's Home Manager configuration:

```nix
profiles.common.hunk.enable = true;
```

For configurations that do not import the shared modules, import
`modules/home-manager/hunk` and pass `inputs` through Home Manager's
`extraSpecialArgs`. The input must contain `nixpkgs-unstable`.

After you activate Home Manager yourself:

```sh
git difftool                 # compare working tree with index
git difftool --cached        # compare staged changes with HEAD
git difftool HEAD~1 HEAD     # compare commits
hunk diff                   # review the full changeset in one stream
```

Git calls Hunk once per file with quoted `$LOCAL`, `$REMOTE`, and `$MERGED`
arguments, as specified in the
[upstream integration guide](https://www.hunk.dev/docs/workflows/git-pager-and-difftool/).
The command uses the Nix store executable rather than relying on `PATH`.
The existing Delta pager and Vimdiff merge tool are unchanged.

To disable, remove the host's enable line or set it to `false`, then activate
Home Manager yourself. Other hosts remain unchanged.

Build without activating:

```sh
nix build .#homeConfigurations.MLGERHL6W4P2RXH.activationPackage --no-link
```

This realizes the Home Manager generation in the Nix store but does not run
its activation script or apply nix-darwin.
