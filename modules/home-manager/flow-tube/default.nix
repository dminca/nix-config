{ pkgs, ... }:
{
  home.packages = [ (pkgs.callPackage ../../../pkgs/flow-tube { }) ];
}
