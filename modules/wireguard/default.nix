{
  config,
  lib,
  ...
}:
let
  cfg = config.profiles.vpn.wireguard;
  connectionName = cfg.interfaceName;
  templateName = "${connectionName}-nmconnection";
in
{
  options.profiles.vpn.wireguard = {
    enable = lib.mkEnableOption "WireGuard VPN client tunnel (e.g. to a pfSense peer), managed by NetworkManager";

    interfaceName = lib.mkOption {
      type = lib.types.str;
      default = "wg0";
      description = "Name of the WireGuard network interface / NetworkManager connection id.";
    };

    connectionUuid = lib.mkOption {
      type = lib.types.str;
      description = ''
        Stable UUID for the generated NetworkManager connection profile.
        Generate once with `uuidgen` and keep it fixed so NetworkManager
        doesn't treat every rebuild as a brand-new connection.
      '';
    };

    address = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "Tunnel IPv4 address(es) assigned to this client by the VPN peer, e.g. [ \"10.10.20.2/24\" ].";
    };

    peerPublicKey = lib.mkOption {
      type = lib.types.str;
      description = "Public key of the remote peer (e.g. pfSense WireGuard endpoint). Not secret.";
    };

    endpoint = lib.mkOption {
      type = lib.types.str;
      description = "Remote peer endpoint as \"host:port\", e.g. \"vpn.example.com:51820\".";
    };

    allowedIPs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "0.0.0.0/0"
        "::/0"
      ];
      description = "Traffic ranges routed through the tunnel. Defaults to full-tunnel.";
    };

    persistentKeepalive = lib.mkOption {
      type = lib.types.int;
      default = 25;
      description = "Keepalive interval in seconds. Useful when the client sits behind NAT.";
    };

    listenPort = lib.mkOption {
      type = lib.types.nullOr lib.types.port;
      default = null;
      description = "Local UDP port to listen on. Leave null to let WireGuard pick an ephemeral port.";
    };

    autoconnect = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Whether NetworkManager should bring the tunnel up automatically on boot/login.
        Leave false to start/stop it manually from the Cinnamon network applet.
      '';
    };

    sopsFile = lib.mkOption {
      type = lib.types.path;
      description = "Path to the sops-encrypted secrets file holding this host's WireGuard keys.";
    };

    privateKeySecret = lib.mkOption {
      type = lib.types.str;
      default = "wireguard-private-key";
      description = "Name of the sops secret (and key inside sopsFile) holding this client's WireGuard private key.";
    };

    presharedKeySecret = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = "wireguard-preshared-key";
      description = "Name of the sops secret (and key inside sopsFile) holding the WireGuard preshared key. Set to null to disable PSK.";
    };
  };

  config = lib.mkIf cfg.enable {
    networking.networkmanager.enable = true;

    sops.secrets.${cfg.privateKeySecret} = {
      sopsFile = cfg.sopsFile;
      key = "private_key";
      mode = "0400";
    };

    sops.secrets.${cfg.presharedKeySecret} = lib.mkIf (cfg.presharedKeySecret != null) {
      sopsFile = cfg.sopsFile;
      key = "preshared_key";
      mode = "0400";
    };

    # Rendered directly to NetworkManager's connection directory so the
    # tunnel shows up as a normal connection in the Cinnamon network applet /
    # nm-connection-editor. sops.templates substitutes the secret
    # placeholders at activation time without ever writing them to the Nix
    # store.
    sops.templates.${templateName} = {
      path = "/etc/NetworkManager/system-connections/${connectionName}.nmconnection";
      owner = "root";
      mode = "0600";
      content = ''
        [connection]
        id=${connectionName}
        uuid=${cfg.connectionUuid}
        type=wireguard
        interface-name=${cfg.interfaceName}
        autoconnect=${if cfg.autoconnect then "true" else "false"}

        [wireguard]
        private-key=${config.sops.placeholder.${cfg.privateKeySecret}}
        ${lib.optionalString (cfg.listenPort != null) "listen-port=${toString cfg.listenPort}"}

        [wireguard-peer.${cfg.peerPublicKey}]
        endpoint=${cfg.endpoint}
        allowed-ips=${lib.concatStringsSep ";" cfg.allowedIPs};
        persistent-keepalive=${toString cfg.persistentKeepalive}
        ${lib.optionalString (
          cfg.presharedKeySecret != null
        ) "preshared-key=${config.sops.placeholder.${cfg.presharedKeySecret}}"}
        ${lib.optionalString (cfg.presharedKeySecret != null) "preshared-key-flags=0"}

        [ipv4]
        address1=${builtins.elemAt cfg.address 0}
        method=manual

        [ipv6]
        method=disabled
      '';
    };

    # Make sure the connection file exists before NetworkManager starts
    # reading its system-connections directory.
    systemd.services.NetworkManager = {
      after = [ "sops-install-secrets.service" ];
      wants = [ "sops-install-secrets.service" ];
    };
  };
}
