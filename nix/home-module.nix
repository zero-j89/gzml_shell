{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.gzml-shell;
  jsonFormat = pkgs.formats.json { };
  tomlFormat = pkgs.formats.toml { };

  generateJson =
    name: value:
    if lib.isString value then
      pkgs.writeText "gzml-${name}.json" value
    else if builtins.isPath value || lib.isStorePath value then
      value
    else
      jsonFormat.generate "gzml-${name}.json" value;
in
{
  options.programs.gzml-shell = {
    enable = lib.mkEnableOption "GZML Shell configuration";

    systemd.enable = lib.mkEnableOption "GZML Shell systemd integration";

    package = lib.mkOption {
      type = lib.types.nullOr lib.types.package;
      default = null;
      description = "The gzml-shell package to use.";
    };

    settings = lib.mkOption {
      type =
        with lib.types;
        oneOf [
          jsonFormat.type
          str
          path
        ];
      default = { };
      example = lib.literalExpression ''
        {
          bar = {
            position = "bottom";
            backgroundOpacity = 0.95;
          };
          general = {
            animationSpeed = 1.5;
            radiusRatio = 1.2;
          };
          colorSchemes = {
            darkMode = true;
            useWallpaperColors = true;
          };
        }
      '';
      description = ''
        GZML Shell settings as an attribute set, string, or filepath.
        Written to ~/.config/gzml-shell/settings.json.
      '';
    };

    colors = lib.mkOption {
      type =
        with lib.types;
        oneOf [
          jsonFormat.type
          str
          path
        ];
      default = { };
      example = lib.literalExpression ''
        {
          mPrimary = "#aaaaaa";
          mSecondary = "#a7a7a7";
          mSurface = "#111111";
          mSurfaceVariant = "#191919";
        }
      '';
      description = ''
        GZML Shell color configuration as an attribute set, string, or filepath.
        Written to ~/.config/gzml-shell/colors.json.
      '';
    };

    user-templates = lib.mkOption {
      default = { };
      type =
        with lib.types;
        oneOf [
          tomlFormat.type
          str
          path
        ];
      example = lib.literalExpression ''
        {
          templates = {
            neovim = {
              input_path = "~/.config/gzml-shell/templates/template.lua";
              output_path = "~/.config/nvim/generated.lua";
              post_hook = "pkill -SIGUSR1 nvim";
            };
          };
        }
      '';
      description = ''
        Template definitions for GZML Shell.
        Written to ~/.config/gzml-shell/user-templates.toml.
      '';
    };

    plugins = lib.mkOption {
      type =
        with lib.types;
        oneOf [
          jsonFormat.type
          str
          path
        ];
      default = { };
      example = lib.literalExpression ''
        {
          sources = [
            {
              enabled = true;
              name = "Noctalia Plugins";
              url = "https://github.com/noctalia-dev/noctalia-plugins";
            }
          ];
          states = { };
          version = 2;
        }
      '';
      description = ''
        GZML Shell plugin configuration as an attribute set, string, or filepath.
        Written to ~/.config/gzml-shell/plugins.json.
      '';
    };

    pluginSettings = lib.mkOption {
      type =
        with lib.types;
        attrsOf (oneOf [
          jsonFormat.type
          str
          path
        ]);
      default = { };
      example = lib.literalExpression ''
        {
          catwalk = {
            minimumThreshold = 25;
            hideBackground = true;
          };
        }
      '';
      description = ''
        Each plugin's settings as an attribute set, string, or filepath.
        Written to ~/.config/gzml-shell/plugins/plugin-name/settings.json.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    warnings = lib.mkIf cfg.systemd.enable [
      ''
        Running gzml-shell as a Home Manager systemd user service is optional.
        For Hyprland users, launching it from Hyprland exec-once is usually simpler.
      ''
    ];

    systemd.user.services.gzml-shell = lib.mkIf cfg.systemd.enable {
      Unit = {
        Description = "GZML Shell - Wayland desktop shell";
        Documentation = "https://github.com/zero-j89/gzml_shell";
        PartOf = [ config.wayland.systemd.target ];
        After = [ config.wayland.systemd.target ];
        X-Restart-Triggers =
          lib.optional (cfg.settings != { }) "${config.xdg.configFile."gzml-shell/settings.json".source}"
          ++ lib.optional (cfg.colors != { }) "${config.xdg.configFile."gzml-shell/colors.json".source}"
          ++ lib.optional (cfg.plugins != { }) "${config.xdg.configFile."gzml-shell/plugins.json".source}"
          ++ lib.optional (
            cfg.user-templates != { }
          ) "${config.xdg.configFile."gzml-shell/user-templates.toml".source}"
          ++ lib.mapAttrsToList (
            name: _: "${config.xdg.configFile."gzml-shell/plugins/${name}/settings.json".source}"
          ) cfg.pluginSettings;
      };

      Service = {
        ExecStart = lib.getExe cfg.package;
        Restart = "on-failure";
      };

      Install.WantedBy = [ config.wayland.systemd.target ];
    };

    home.packages = lib.optional (cfg.package != null) cfg.package;

    xdg.configFile = {
      "gzml-shell/settings.json" = lib.mkIf (cfg.settings != { }) {
        source = generateJson "settings" cfg.settings;
      };
      "gzml-shell/colors.json" = lib.mkIf (cfg.colors != { }) {
        source = generateJson "colors" cfg.colors;
      };
      "gzml-shell/plugins.json" = lib.mkIf (cfg.plugins != { }) {
        source = generateJson "plugins" cfg.plugins;
      };
      "gzml-shell/user-templates.toml" = lib.mkIf (cfg.user-templates != { }) {
        source =
          if lib.isString cfg.user-templates then
            pkgs.writeText "gzml-user-templates.toml" cfg.user-templates
          else if builtins.isPath cfg.user-templates || lib.isStorePath cfg.user-templates then
            cfg.user-templates
          else
            tomlFormat.generate "gzml-user-templates.toml" cfg.user-templates;
      };
    }
    // lib.mapAttrs' (
      name: value:
      lib.nameValuePair "gzml-shell/plugins/${name}/settings.json" {
        source = generateJson "${name}-settings" value;
      }
    ) cfg.pluginSettings;

    assertions = [
      {
        assertion = !cfg.systemd.enable || cfg.package != null;
        message = "gzml-shell: The package option must not be null when systemd service is enabled.";
      }
    ];
  };
}
