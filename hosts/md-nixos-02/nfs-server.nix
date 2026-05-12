{ ... }:
{
  # ── NFS Server ───────────────────────────────────────────────────────────
  # Exports /mnt/arr-data to md-nixos-01 (VM) and other LAN clients.
  services.nfs.server = {
    enable = true;
    exports = ''
      /mnt/arr-data 10.10.10.0/24(rw,sync,no_subtree_check,root_squash,anonuid=0,anongid=65534)
    '';
  };
}

