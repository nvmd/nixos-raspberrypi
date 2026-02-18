# This file is a modified version of config.txt generator
# Licensed under the terms of MIT License
# https://raw.githubusercontent.com/nix-community/raspberry-pi-nix/refs/heads/master/rpi/config.nix
# with modifications
# https://raw.githubusercontent.com/nvmd/raspberry-pi-nix/refs/heads/master/rpi/config.nix

{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.hardware.raspberry-pi;

  render-raspberrypi-config =
    let

      render-kvs =
        kvs:
        let
          render-kv = k: v: if isNull v.value then k else "${k}=${toString v.value}";
        in
        lib.attrsets.mapAttrsToList render-kv (lib.filterAttrs (k: v: v.enable) kvs);

      render-dt-param = x: "dtparam=" + x;
      render-dt-params = params: lib.strings.concatMapStringsSep "\n" render-dt-param (render-kvs params);

      render-dt-overlay =
        { overlay, params }:
        lib.concatStringsSep "\n" (
          lib.filter (x: x != "") [
            ("dtoverlay=" + overlay)
            (render-dt-params params)
            "dtoverlay="
          ]
        );

      render-options = opts: lib.strings.concatStringsSep "\n" (render-kvs opts);

      render-base-dt-params = render-dt-params;

      render-dt-overlays =
        overlays:
        lib.strings.concatMapStringsSep "\n" render-dt-overlay (
          lib.attrsets.mapAttrsToList (overlay: params: {
            inherit overlay;
            inherit (params) params;
          }) (lib.filterAttrs (k: v: v.enable) overlays)
        );

      render-config-section =
        conditionalFilter:
        {
          options,
          base-dt-params,
          dt-overlays,
        }:
        let
          all-config = lib.concatStringsSep "\n" (
            lib.filter (x: x != "") [
              (render-options options)
              (render-base-dt-params base-dt-params)
              (render-dt-overlays dt-overlays)
            ]
          );
        in
        ''
          [${conditionalFilter}]
          ${all-config}
        '';
    in
    conf:
    lib.strings.concatStringsSep "\n" (
      (lib.attrsets.mapAttrsToList render-config-section conf) ++ [ cfg.extra-config ]
    );
in
{
  options.hardware.raspberry-pi = {
    config =
      let
        rpi-config-param = {
          options = {
            enable = lib.mkEnableOption "attr";
            value = lib.mkOption {
              type =
                with lib.types;
                oneOf [
                  int
                  str
                  bool
                ];
            };
          };
        };
        dt-param = {
          options = {
            enable = lib.mkEnableOption "attr";
            value = lib.mkOption {
              type =
                with lib.types;
                nullOr (oneOf [
                  int
                  str
                  bool
                ]);
              default = null;
            };
          };
        };
        dt-overlay = {
          options = {
            enable = lib.mkEnableOption "overlay";
            params = lib.mkOption {
              type = with lib.types; attrsOf (submodule dt-param);
              default = { };
            };
          };
        };
        raspberry-pi-config-options = {
          options = {
            options = lib.mkOption {
              type = with lib.types; attrsOf (submodule rpi-config-param);
              default = { };
              description = ''
                Common hardware configuration options, translates to
                `<option>=<value>` in the `config.txt`.
                <https://www.raspberrypi.com/documentation/computers/config_txt.html#common-hardware-configuration-options>
              '';
              example = {
                arm_boost = {
                  # arm_boost=1
                  enable = true;
                  value = true;
                };
              };
            };
            base-dt-params = lib.mkOption {
              type = with lib.types; attrsOf (submodule dt-param);
              default = { };
              description = ''
                Parameters to pass to the base DTB, translates to
                `dtparam=<param>=<value>` in the `config.txt`.
                <https://www.raspberrypi.com/documentation/computers/configuration.html#part3.2>
              '';
              example = {
                i2c = {
                  # dtparam=i2c=on
                  enable = true;
                  value = "on";
                };
                ant2 = {
                  # dtparam=ant2
                  enable = true;
                };
              };
            };
            dt-overlays = lib.mkOption {
              type = with lib.types; attrsOf (submodule dt-overlay);
              default = { };
              description = ''
                DTB overlays to enable and configure with parameters, translates to
                ```
                 dtoverlay=<overlay>
                 dtparam=<param>=<value>
                 dtoverlay=
                ```, which is an equivalent to a more popular format of
                `dtoverlay=<overlay>,<param>=<value>`.
                <https://www.raspberrypi.com/documentation/computers/configuration.html#part3.1>
              '';
              example = {
                vc4-kms-v3d = {
                  # dtoverlay=vc4-kms-v3d,cma-256
                  enable = true;
                  params = {
                    cma-256 = {
                      enable = true;
                      # value = "";
                    };
                  };
                };
                disable-bt = {
                  # dtoverlay=disable-bt
                  enable = true;
                };
              };
            };
          };
        };
      in
      lib.mkOption {
        type = with lib.types; attrsOf (submodule raspberry-pi-config-options);
        description = ''
          Configures `config.txt` file for Raspberry Pi devices.
          The file is located on a firmware partition, usually mounted at
          `/boot/firmware`.
          <https://www.raspberrypi.com/documentation/computers/config_txt.html>
        '';
      };

    extra-config = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = ''
        Extra options that will be appended to `/boot/firmware/config.txt` file.
        For possible values, see: https://www.raspberrypi.com/documentation/computers/config_txt.html
      '';
    };

    config-generated = lib.mkOption {
      type = lib.types.str;
      description = ''
        The config file text generated by hardware.raspberry-pi.config
      '';
      readOnly = true;
    };
  };

  config = {
    hardware.raspberry-pi.config-generated = render-raspberrypi-config cfg.config;
  };
}
