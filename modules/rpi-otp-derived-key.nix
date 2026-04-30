{ config
, lib
, pkgs
, utils
, ...
}:
let
  cfg = config.services.rpiOtpDerivedKey;
  users = config.users.users;
  otpDerivedKeyLib = import ../lib/rpi-otp-derived-key.nix { };
  formats = [
    "hex"
    "binary"
    "ed25519"
    "age"
  ];
  isAbsolutePath = path: lib.hasPrefix "/" path;
  isRunPath = path: path == "/run" || lib.hasPrefix "/run/" path;
  isPathAtOrBelowDir = dir: path: path == dir || lib.hasPrefix "${dir}/" path;
  shouldManageTmpfilesDir = dir: !(builtins.elem dir [ "/" "/run" "/tmp" "/var" "/var/lib" ]);
  absolutePathType = (lib.types.addCheck lib.types.str isAbsolutePath) // {
    description = "absolute path";
    name = "absolute path";
  };
  fileModeType = lib.types.strMatching "0[0-7]{3}";
  managedSaltLength = 32;
  otpHelperPackage = pkgs.rpi-otp-private-key or (
    pkgs.callPackage ../pkgs/raspberrypi/rpi-otp-private-key.nix { }
  );
  modulePackage = pkgs.rpi-otp-derived-key or (
    pkgs.callPackage ../pkgs/raspberrypi/rpi-otp-derived-key.nix {
      rpi-otp-private-key = otpHelperPackage;
    }
  );
  defaultOtpHelperPackage = lib.optional
    (lib.meta.availableOn pkgs.stdenv.hostPlatform otpHelperPackage)
    otpHelperPackage;
  defaultOtpHelperRuntimePackages =
    [
      pkgs.gawk
      pkgs.gnugrep
      pkgs.gnused
      pkgs.which
    ]
    ++ lib.optional
      (pkgs ? libraspberrypi && lib.meta.availableOn pkgs.stdenv.hostPlatform pkgs.libraspberrypi)
      pkgs.libraspberrypi;
  defaultInitrdPackages = [
    pkgs.age
    pkgs.coreutils
    pkgs.openssl
    pkgs.xxd
  ] ++ defaultOtpHelperRuntimePackages ++ defaultOtpHelperPackage;

  secretType = lib.types.submodule (
    { config, ... }:
    {
      options = {
        format = lib.mkOption {
          type = lib.types.enum formats;
          example = "age";
          description = ''
            Output format to generate for this secret.
          '';
        };

        path = lib.mkOption {
          type = absolutePathType;
          default = "/run/rpi-otp-derived-key/${config._module.args.name}";
          description = ''
            Path where the derived secret is written.
            Secrets with `neededForBoot = true` should keep this under `/run`.
          '';
        };

        neededForBoot = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = ''
            Generate this secret in `boot.initrd.systemd` instead of stage 2.
            This is useful for consumers that need the derived secret during the
            systemd initrd phase. The module automatically provisions a
            persistent per-secret salt for initrd use during
            `switch-to-configuration boot` or `switch-to-configuration switch`
            before initrd secrets are appended by the bootloader.
          '';
        };

        owner = lib.mkOption {
          type = with lib.types; nullOr str;
          default = null;
          example = "my-service";
          description = ''
            Owner of the derived secret. `null` means `root`.
          '';
        };

        group = lib.mkOption {
          type = with lib.types; nullOr str;
          default =
            if config.owner != null && builtins.hasAttr config.owner users then
              users.${config.owner}.group
            else
              null;
          defaultText = lib.literalMD "The owning user's primary group when available, otherwise `root`.";
          description = ''
            Group of the derived secret. `null` means `root`.
          '';
        };

        mode = lib.mkOption {
          type = fileModeType;
          default = "0400";
          example = "0440";
          description = ''
            File mode to apply to the derived secret.
          '';
        };

        before = lib.mkOption {
          type = with lib.types; listOf str;
          default = [ ];
          example = [ "sshd.service" ];
          description = ''
            Units that should start after this derived-secret service.
          '';
        };

      };
    }
  );

  stage2Secrets = lib.filterAttrs (_: secret: !secret.neededForBoot) cfg.secrets;
  initrdSecrets = lib.filterAttrs (_: secret: secret.neededForBoot) cfg.secrets;
  hasInitrdSecrets = initrdSecrets != { };
  saltStateDir = "/var/lib/rpi-otp-derived-key/salt";
  initrdSaltDir = "/run/rpi-otp-derived-key/salt";
  initrdServiceStorePaths = lib.unique (
    [
      modulePackage
    ]
    ++ defaultInitrdPackages
  );
  mkRandomSaltCreationSnippet =
    saltPath: ''
      salt_dir=${lib.escapeShellArg (builtins.dirOf saltPath)}
      salt_path=${lib.escapeShellArg saltPath}

      ${pkgs.coreutils}/bin/mkdir -p "$salt_dir"

      if [[ -e "$salt_path" ]]; then
        :
      else
        tmp_path="$(${pkgs.coreutils}/bin/mktemp "$salt_dir/.rpi-otp-derived-key-salt.tmp.XXXXXX")"
        trap '${pkgs.coreutils}/bin/rm -f "$tmp_path"' EXIT

        ${pkgs.openssl}/bin/openssl rand -out "$tmp_path" "${toString managedSaltLength}"

        ${pkgs.coreutils}/bin/chown root:root "$tmp_path"
        ${pkgs.coreutils}/bin/chmod 0400 "$tmp_path"
        ${pkgs.coreutils}/bin/mv -f "$tmp_path" "$salt_path"

        trap - EXIT
      fi
    '';
  mkRandomSaltCreationScript =
    saltPaths: ''
      set -euo pipefail
      ${lib.concatMapStringsSep "\n" mkRandomSaltCreationSnippet saltPaths}
    '';
  mkSecretCreationScript =
    { secret
    , saltFileAssignment
    , prelude ? ""
    }: ''
      set -euo pipefail

      ${prelude}

      output_dir=${lib.escapeShellArg secret.outputDir}
      output_path=${lib.escapeShellArg secret.path}
      owner=${lib.escapeShellArg secret.ownerName}
      group=${lib.escapeShellArg secret.groupName}
      mode=${lib.escapeShellArg secret.mode}
      salt_file=${saltFileAssignment}

      ${pkgs.coreutils}/bin/mkdir -p "$output_dir"
      tmp_path="$(${pkgs.coreutils}/bin/mktemp "$output_dir/.${secret.unitSuffix}.tmp.XXXXXX")"
      trap '${pkgs.coreutils}/bin/rm -f "$tmp_path"' EXIT

      cmd=(
        ${lib.getExe modulePackage}
        --format ${lib.escapeShellArg secret.format}
        --salt-file "$salt_file"
      )

      "''${cmd[@]}" > "$tmp_path"

      ${pkgs.coreutils}/bin/chown "$owner:$group" "$tmp_path"
      ${pkgs.coreutils}/bin/chmod "$mode" "$tmp_path"
      ${pkgs.coreutils}/bin/mv -f "$tmp_path" "$output_path"

      trap - EXIT
    '';

  mkSecretInstances =
    secrets:
    lib.mapAttrs
      (
        name: secretCfg:
        let
          unitSuffix = utils.escapeSystemdPath name;
          saltPathComponent = otpDerivedKeyLib.saltPathComponentForName name;
          outputDir = builtins.dirOf secretCfg.path;
        in
        secretCfg
        // {
          inherit name outputDir saltPathComponent unitSuffix;
          unitName = "rpi-otp-derived-key-${unitSuffix}";
          saltUnitName = "rpi-otp-derived-key-salt-${unitSuffix}";
          ownerName = if secretCfg.owner != null then secretCfg.owner else "root";
          groupName = if secretCfg.group != null then secretCfg.group else "root";
          persistentSaltPath = "${saltStateDir}/${saltPathComponent}";
          initrdSaltPath = "${initrdSaltDir}/${saltPathComponent}";
        }
      )
      secrets;

  stage2SecretInstances = mkSecretInstances stage2Secrets;
  initrdSecretInstances = mkSecretInstances initrdSecrets;
  secretInstances = stage2SecretInstances // initrdSecretInstances;
  initrdBootSecrets = lib.mapAttrs'
    (_: secret: lib.nameValuePair secret.initrdSaltPath secret.persistentSaltPath)
    initrdSecretInstances;
  checkOtpProgrammedSnippet = ''
        if ! ${lib.getExe otpHelperPackage} -c; then
          cat >&2 <<'EOF'
    services.rpiOtpDerivedKey: Raspberry Pi OTP private key is not programmed.

    Program the OTP private key before installing initrd OTP-derived secrets. One supported flow is:

      openssl ecparam -name prime256v1 -genkey -noout -out private_key.pem
      openssl ec -in private_key.pem -text -noout | awk '/priv:/{flag=1; next} /pub:/{flag=0} flag' | tr -d ' \n:' | head -n1 > d.hex
      rpi-otp-private-key -w "$(cat d.hex)"

    Run `rpi-otp-private-key -h` for details and warnings. Aborting bootloader install.
    EOF
          exit 1
        fi
  '';
  initrdDeviceReadinessSnippet = ''
    if [[ -e /sys/firmware/devicetree/base/system/linux,revision ]]; then
      for _ in 1 2 3 4 5 6 7 8 9 10; do
        [[ -e /dev/vcio ]] && break
        ${pkgs.coreutils}/bin/sleep 0.1
      done
    fi
  '';
  preSwitchInitrdSaltCheck = lib.optionalAttrs hasInitrdSecrets {
    rpi-otp-derived-key-initrd-salts = ''
      set -euo pipefail

      case "''${2:-}" in
        switch|boot)
          ;;
        *)
          exit 0
          ;;
      esac

      ${checkOtpProgrammedSnippet}
      ${mkRandomSaltCreationScript (
        map (secret: secret.persistentSaltPath) (lib.attrValues initrdSecretInstances)
      )}
    '';
  };

  managedOutputDirs = lib.unique (
    lib.filter
      shouldManageTmpfilesDir
      (lib.mapAttrsToList (_: secret: secret.outputDir) secretInstances)
  );

  tmpfilesRules = lib.unique (
    [
      "d /var/lib/rpi-otp-derived-key 0711 root root - -"
      "d ${saltStateDir} 0700 root root - -"
    ]
    ++ map (dir: "d ${dir} 0711 root root - -") managedOutputDirs
  );

  secretAssertions = lib.flatten (
    lib.mapAttrsToList
      (
        name: secret:
          [
            {
              assertion = !isPathAtOrBelowDir saltStateDir secret.path;
              message = "services.rpiOtpDerivedKey.secrets.${lib.strings.escapeNixIdentifier name}.path must not point inside the module-managed salt state directory.";
            }
            {
              assertion = !isPathAtOrBelowDir initrdSaltDir secret.path;
              message = "services.rpiOtpDerivedKey.secrets.${lib.strings.escapeNixIdentifier name}.path must not point inside the module-managed initrd salt directory.";
            }
            {
              assertion = !secret.neededForBoot || isRunPath secret.path;
              message = "services.rpiOtpDerivedKey.secrets.${lib.strings.escapeNixIdentifier name}.path must point inside /run when neededForBoot is enabled.";
            }
            {
              assertion = !secret.neededForBoot || secret.owner == null || secret.owner == "root";
              message = "services.rpiOtpDerivedKey.secrets.${lib.strings.escapeNixIdentifier name}.owner must be root when neededForBoot is enabled.";
            }
            {
              assertion = !secret.neededForBoot || secret.group == null || secret.group == "root";
              message = "services.rpiOtpDerivedKey.secrets.${lib.strings.escapeNixIdentifier name}.group must be root when neededForBoot is enabled.";
            }
          ]
      )
      secretInstances
  );

  stage2SaltServices = lib.mapAttrs'
    (
      _: secret:
        lib.nameValuePair secret.saltUnitName {
          description = "Generate persistent salt for rpi-otp-derived-key secret ${secret.name}";
          before = [ "${secret.unitName}.service" ];
          after = [ "local-fs.target" ];
          unitConfig = {
            DefaultDependencies = "no";
            ConditionPathExists = "!${secret.persistentSaltPath}";
            RequiresMountsFor = [ (builtins.dirOf secret.persistentSaltPath) ];
          };
          serviceConfig = {
            Type = "oneshot";
            UMask = "0077";
            NoNewPrivileges = true;
            PrivateTmp = true;
            ProtectSystem = "strict";
            ReadWritePaths = [ (builtins.dirOf secret.persistentSaltPath) ];
          };
          script = mkRandomSaltCreationScript [ secret.persistentSaltPath ];
        }
    )
    stage2SecretInstances;

  mkSecretServices =
    { initrd ? false
    , secretSet
    ,
    }:
    lib.mapAttrs'
      (
        _: secret:
        lib.nameValuePair secret.unitName {
          description = "Generate device-unique key material from Raspberry Pi OTP for ${secret.name}";
          wantedBy = if initrd then [ "initrd.target" ] else [ "sysinit.target" ];
          before = lib.unique (
            lib.optionals initrd [ "initrd.target" ]
            ++ secret.before
          );
          requires =
            lib.optionals initrd [ "initrd-nixos-copy-secrets.service" ]
            ++ lib.optionals (!initrd) [ "${secret.saltUnitName}.service" ];
          after =
            lib.optionals (!initrd) [ "local-fs.target" ]
            ++ lib.optionals initrd [ "initrd-nixos-copy-secrets.service" ]
            ++ lib.optionals (!initrd) [ "${secret.saltUnitName}.service" ];
          unitConfig = {
            DefaultDependencies = "no";
            RequiresMountsFor = lib.unique (
              [ secret.outputDir ]
              ++ lib.optionals (!initrd) [ (builtins.dirOf secret.persistentSaltPath) ]
            );
          };
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            UMask = "0077";
            NoNewPrivileges = true;
            PrivateTmp = true;
            ProtectSystem = "strict";
            ReadWritePaths = if initrd then [ "/run" ] else [ secret.outputDir ];
            LoadCredential = [
              "salt:${if initrd then secret.initrdSaltPath else secret.persistentSaltPath}"
            ];
          };
          script = mkSecretCreationScript {
            inherit secret;
            saltFileAssignment = ''"$CREDENTIALS_DIRECTORY/salt"'';
            prelude = lib.optionalString initrd initrdDeviceReadinessSnippet;
          };
        }
      )
      secretSet;

  stage2SecretServices = mkSecretServices {
    secretSet = stage2SecretInstances;
  };

  initrdSecretServices = mkSecretServices {
    initrd = true;
    secretSet = initrdSecretInstances;
  };

  ensureScripts = lib.mapAttrs
    (
      _: secret:
        pkgs.writeShellScript "rpi-otp-derived-key-ensure-${secret.saltPathComponent}" (
          mkSecretCreationScript {
            inherit secret;
            saltFileAssignment = lib.escapeShellArg secret.persistentSaltPath;
            prelude = mkRandomSaltCreationSnippet secret.persistentSaltPath;
          }
        )
    )
    secretInstances;
in
{
  options.services.rpiOtpDerivedKey = {
    enable = lib.mkEnableOption "Raspberry Pi OTP-derived key generation services";

    secrets = lib.mkOption {
      type = with lib.types; attrsOf secretType;
      default = { };
      description = ''
        Derived secrets keyed by name.
      '';
    };

  };

  config = lib.mkIf cfg.enable {
    systemd.tmpfiles.rules = tmpfilesRules;

    system.build.rpiOtpDerivedKeyEnsureScripts = ensureScripts;

    assertions =
      [
        {
          assertion = cfg.secrets != { };
          message = "services.rpiOtpDerivedKey.enable requires at least one secret in services.rpiOtpDerivedKey.secrets.";
        }
        {
          assertion = !hasInitrdSecrets || config.boot.initrd.systemd.enable;
          message = "services.rpiOtpDerivedKey.secrets.<name>.neededForBoot requires boot.initrd.systemd.enable = true.";
        }
        {
          assertion = !hasInitrdSecrets || config.boot.loader.supportsInitrdSecrets;
          message = "services.rpiOtpDerivedKey.secrets.<name>.neededForBoot requires a bootloader that supports native initrd secrets.";
        }
      ]
      ++ secretAssertions;

    system.preSwitchChecks = preSwitchInitrdSaltCheck;

    systemd.services = stage2SaltServices // stage2SecretServices;

    boot.initrd.secrets = lib.mkIf hasInitrdSecrets initrdBootSecrets;

    boot.initrd.systemd = lib.mkIf hasInitrdSecrets {
      initrdBin = defaultInitrdPackages;
      storePaths = map (source: { inherit source; }) initrdServiceStorePaths;
      services = initrdSecretServices;
    };
  };
}
