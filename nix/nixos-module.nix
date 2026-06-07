{
  config,
  lib,
  ...
}:
let
  cfg = config.services.gzml-shell;
in
{
  options.services.gzml-shell = {
    enable = lib.mkEnableOption "GZML Shell systemd user service";

    package = lib.mkOption {
      type = lib.types.package;
      description = "The gzml-shell package to use.";
    };

    target = lib.mkOption {
      type = lib.types.str;
      default = "graphical-session.target";
      example = "hyprland-session.target";
      description = "The systemd user target for the gzml-shell service.";
    };
  };

  config = lib.mkIf cfg.enable {
    warnings = [
      ''
        Running gzml-shell as a systemd user service is optional.
        For Hyprland users, launching it from Hyprland exec-once is usually simpler.
      ''
    ];

    systemd.user.services.gzml-shell = {
      description = "GZML Shell - Wayland desktop shell";
      documentation = [ "https://github.com/zero-j89/gzml_shell" ];
      after = [ cfg.target ];
      partOf = [ cfg.target ];
      wantedBy = [ cfg.target ];
      restartTriggers = [ cfg.package ];

      environment = {
        PATH = lib.mkForce null;
      };

      serviceConfig = {
        ExecStart = lib.getExe cfg.package;
        Restart = "on-failure";
      };
    };

    environment.systemPackages = [ cfg.package ];
  };
}
