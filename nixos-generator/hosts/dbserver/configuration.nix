# hosts/dbserver/configuration.nix
{ config, pkgs, ... }:

{
  networking.hostName = "dbserver";

  networking.useDHCP = false;
  networking.interfaces.eth0.ipv4.addresses = [{
    address      = "192.168.1.11";
    prefixLength = 24;
  }];
  networking.defaultGateway = "192.168.1.1";
  networking.nameservers    = [ "1.1.1.1" "8.8.8.8" ];

  # PostgreSQL only reachable from internal network, not exposed to firewall
  networking.firewall.allowedTCPPorts = [ 22 ];

  services.postgresql = {
    enable  = true;
    package = pkgs.postgresql_16;

    # Allow local Unix socket connections without password (for local processes)
    authentication = ''
      local all all              trust
      host  all all 127.0.0.1/32 scram-sha-256
    '';

    initialScript = pkgs.writeText "pg-init.sql" ''
      CREATE USER appuser WITH PASSWORD 'changeme';
      CREATE DATABASE appdb OWNER appuser;
    '';
  };
}
