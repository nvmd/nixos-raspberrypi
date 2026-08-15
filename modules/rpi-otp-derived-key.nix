{
  config,
  lib,
  options,
  pkgs,
  utils,
  ...
}:
let
  cfg = config.services.rpiOtpDerivedKey;
  users = config.users.users;
  supportedRaspberryPiVariants = [
    "02"
    "4"
    "5"
  ];
  hasRaspberryPiVariantOption = options ? boot.loader.raspberry-pi.variant;
  hasRaspberryPiVariant =
    hasRaspberryPiVariantOption && options.boot.loader.raspberry-pi.variant.isDefined;
  hasRaspberryPiConfigOption = lib.hasAttrByPath [
    "hardware"
    "raspberry-pi"
    "config"
  ] options;
  hasSupportedRaspberryPiVariant =
    hasRaspberryPiVariant
    && lib.elem config.boot.loader.raspberry-pi.variant supportedRaspberryPiVariants;
  otpDerivedKeyLib = import ../lib/rpi-otp-derived-key.nix { };
  formats = [
    "hex"
    "binary"
    "ed25519"
    "age"
  ];
  schemes = [
    "firmware-hmac-v1"
    "legacy-hkdf-v1"
  ];
  isRunPath = path: path == "/run" || lib.hasPrefix "/run/" path;
  isPathAtOrBelowDir = dir: path: path == dir || lib.hasPrefix "${dir}/" path;
  pathsOverlap = left: right: isPathAtOrBelowDir left right || isPathAtOrBelowDir right left;
  canonicalAbsolutePathType =
    (lib.types.addCheck lib.types.str otpDerivedKeyLib.isCanonicalAbsolutePath)
    // {
      description = "canonical absolute path without dot components or repeated separators";
      name = "canonical absolute path";
    };
  fileModeType = lib.types.strMatching "0[0-7]{3}";
  managedSaltLength = 32;
  otpHelperPackage =
    pkgs.rpi-otp-private-key or (pkgs.callPackage ../pkgs/raspberrypi/rpi-otp-private-key.nix { });
  rpiUtilsPackage =
    pkgs.raspberrypi-utils or (pkgs.callPackage ../pkgs/raspberrypi/raspberrypi-utils.nix { });
  modulePackage =
    pkgs.rpi-otp-derived-key or (pkgs.callPackage ../pkgs/raspberrypi/rpi-otp-derived-key.nix {
      raspberrypi-utils = rpiUtilsPackage;
      rpi-otp-private-key = otpHelperPackage;
    });
  moduleRpiFwCryptoPackage = modulePackage.rpiFwCryptoPackage or rpiUtilsPackage;
  defaultOtpHelperPackage = lib.optional (lib.meta.availableOn pkgs.stdenv.hostPlatform otpHelperPackage) otpHelperPackage;
  defaultOtpHelperInitrdBinPackages = [
    pkgs.gawk
    pkgs.gnugrep
    pkgs.gnused
    pkgs.which
  ];
  # The helper embeds absolute runtime paths. Copy libraspberrypi into the
  # initrd store without merging its overlapping binaries into initrdBin.
  legacyOtpHelperInitrdStorePackages = lib.optional (
    pkgs ? libraspberrypi && lib.meta.availableOn pkgs.stdenv.hostPlatform pkgs.libraspberrypi
  ) pkgs.libraspberrypi;
  defaultInitrdBinPackages = [
    pkgs.age
    pkgs.coreutils
    pkgs.openssl
    moduleRpiFwCryptoPackage
    pkgs.xxd
  ]
  ++ defaultOtpHelperInitrdBinPackages
  ++ defaultOtpHelperPackage;

  secretType = lib.types.submodule (
    { config, ... }:
    {
      options = {
        scheme = lib.mkOption {
          type = lib.types.enum schemes;
          example = "firmware-hmac-v1";
          description = ''
            Versioned derivation scheme for this secret. Use `firmware-hmac-v1`
            for new deployments. `legacy-hkdf-v1` exists only to migrate keys
            created by older versions of this module.
          '';
        };

        format = lib.mkOption {
          type = lib.types.enum formats;
          example = "age";
          description = ''
            Output format to generate for this secret.
          '';
        };

        path = lib.mkOption {
          type = canonicalAbsolutePathType;
          default = "/run/rpi-otp-derived-key/${otpDerivedKeyLib.pathComponentForName config._module.args.name}";
          description = ''
            Canonical absolute path where the derived secret is written.
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
    ++ defaultInitrdBinPackages
    ++ legacyOtpHelperInitrdStorePackages
  );
  mkRandomSaltCreationSnippet = saltPath: ''
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
  mkRandomSaltCreationScript = saltPaths: ''
    set -euo pipefail
    ${lib.concatMapStringsSep "\n" mkRandomSaltCreationSnippet saltPaths}
  '';
  mkSecretCreationScript =
    {
      secret,
      saltFileAssignment,
      prelude ? "",
    }:
    ''
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
        --scheme ${lib.escapeShellArg secret.scheme}
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
    lib.mapAttrs (
      name: secretCfg:
      let
        unitSuffix = utils.escapeSystemdPath name;
        saltPathComponent = otpDerivedKeyLib.saltPathComponentForName name;
        outputDir = builtins.dirOf secretCfg.path;
      in
      secretCfg
      // {
        inherit
          name
          outputDir
          saltPathComponent
          unitSuffix
          ;
        unitName = "rpi-otp-derived-key-${unitSuffix}";
        saltUnitName = "rpi-otp-derived-key-salt-${unitSuffix}";
        ownerName = if secretCfg.owner != null then secretCfg.owner else "root";
        groupName = if secretCfg.group != null then secretCfg.group else "root";
        persistentSaltPath = "${saltStateDir}/${saltPathComponent}";
        initrdSaltPath = "${initrdSaltDir}/${saltPathComponent}";
      }
    ) secrets;

  stage2SecretInstances = mkSecretInstances stage2Secrets;
  initrdSecretInstances = mkSecretInstances initrdSecrets;
  secretInstances = stage2SecretInstances // initrdSecretInstances;
  secretInstanceValues = lib.attrValues secretInstances;
  outputPaths = map (secret: secret.path) secretInstanceValues;
  persistentSaltPaths = map (secret: secret.persistentSaltPath) secretInstanceValues;
  outputPathHasCollision =
    path: lib.length (lib.filter (otherPath: pathsOverlap path otherPath) outputPaths) > 1;
  hasOutputPathCollision = lib.any outputPathHasCollision outputPaths;
  hasPersistentSaltPathCollision =
    lib.length (lib.unique persistentSaltPaths) != lib.length persistentSaltPaths;
  usesOnlyFirmwareHmac = lib.all (secret: secret.scheme == "firmware-hmac-v1") secretInstanceValues;
  initrdBootSecrets = lib.mapAttrs' (
    _: secret: lib.nameValuePair secret.initrdSaltPath secret.persistentSaltPath
  ) initrdSecretInstances;
  readinessSchemes = lib.unique (map (secret: secret.scheme) (lib.attrValues initrdSecretInstances));
  mkOtpReadinessSnippet = scheme: ''
    if ! ${lib.getExe modulePackage} \
      --scheme ${lib.escapeShellArg scheme} \
      --salt ${lib.escapeShellArg "rpi-otp-derived-key-readiness:${scheme}"} \
      --length 1 \
      >/dev/null
    then
      cat >&2 <<'EOF'
    services.rpiOtpDerivedKey: OTP derivation backend is not ready for scheme ${scheme}.

    Ensure the OTP device private key is programmed before installing initrd
    OTP-derived secrets. firmware-hmac-v1 additionally requires firmware with
    the rpi-fw-crypto HMAC API and uses OTP key slot 1 by default.

    Aborting bootloader install.
    EOF
      exit 1
    fi
  '';
  checkOtpProgrammedSnippet = lib.concatMapStringsSep "\n" mkOtpReadinessSnippet readinessSchemes;
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
    map (secret: secret.outputDir) (lib.attrValues stage2SecretInstances)
  );
  outputDirTmpfilesSettings = lib.listToAttrs (
    map (
      dir:
      lib.nameValuePair dir {
        d = {
          # The ':' prefix applies these values only when creating the directory.
          # Existing application-owned directories keep their permissions and owner.
          mode = ":0711";
          user = ":root";
          group = ":root";
        };
      }
    ) managedOutputDirs
  );
  tmpfilesRules = [
    "d /var/lib/rpi-otp-derived-key 0711 root root - -"
    "d ${saltStateDir} 0700 root root - -"
  ];

  secretAssertions = lib.flatten (
    lib.mapAttrsToList (name: secret: [
      {
        assertion = !pathsOverlap saltStateDir secret.path;
        message = "services.rpiOtpDerivedKey.secrets.${lib.strings.escapeNixIdentifier name}.path must not overlap the module-managed salt state directory.";
      }
      {
        assertion = !pathsOverlap initrdSaltDir secret.path;
        message = "services.rpiOtpDerivedKey.secrets.${lib.strings.escapeNixIdentifier name}.path must not overlap the module-managed initrd salt directory.";
      }
      {
        assertion = secret.path != "/";
        message = "services.rpiOtpDerivedKey.secrets.${lib.strings.escapeNixIdentifier name}.path must name a file, not the filesystem root.";
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
    ]) secretInstances
  );

  stage2SaltServices = lib.mapAttrs' (
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
  ) stage2SecretInstances;

  mkSecretServices =
    {
      initrd ? false,
      secretSet,
    }:
    lib.mapAttrs' (
      _: secret:
      lib.nameValuePair secret.unitName {
        description = "Generate device-unique key material from Raspberry Pi OTP for ${secret.name}";
        wantedBy = if initrd then [ "initrd.target" ] else [ "sysinit.target" ];
        before = lib.unique (lib.optionals initrd [ "initrd.target" ] ++ secret.before);
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
            [ secret.outputDir ] ++ lib.optionals (!initrd) [ (builtins.dirOf secret.persistentSaltPath) ]
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
    ) secretSet;

  stage2SecretServices = mkSecretServices {
    secretSet = stage2SecretInstances;
  };

  initrdSecretServices = mkSecretServices {
    initrd = true;
    secretSet = initrdSecretInstances;
  };

  ensureScripts = lib.mapAttrs (
    _: secret:
    pkgs.writeShellScript "rpi-otp-derived-key-ensure-${secret.saltPathComponent}"
      (mkSecretCreationScript {
        inherit secret;
        saltFileAssignment = lib.escapeShellArg secret.persistentSaltPath;
        prelude = mkRandomSaltCreationSnippet secret.persistentSaltPath;
      })
  ) secretInstances;
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

  config = lib.mkMerge (
    [
      (lib.mkIf cfg.enable {
        systemd.tmpfiles.rules = tmpfilesRules;
        systemd.tmpfiles.settings.rpi-otp-derived-key-output-dirs = outputDirTmpfilesSettings;

        system.build.rpiOtpDerivedKeyEnsureScripts = ensureScripts;

        assertions = [
          {
            assertion = hasSupportedRaspberryPiVariant;
            message = ''
              services.rpiOtpDerivedKey only supports Raspberry Pi Zero 2, 4, and 5.
              Import a supported Raspberry Pi board module or set
              boot.loader.raspberry-pi.variant to one of:
              ${lib.concatStringsSep ", " supportedRaspberryPiVariants}
            '';
          }
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
          {
            assertion = !hasOutputPathCollision;
            message = "services.rpiOtpDerivedKey secret output paths must be unique and must not contain another secret output path.";
          }
          {
            assertion = !hasPersistentSaltPathCollision;
            message = "services.rpiOtpDerivedKey secret names collide after conversion to persistent salt paths; rename one of the secrets.";
          }
        ]
        ++ secretAssertions;

        system.preSwitchChecks = preSwitchInitrdSaltCheck;

        systemd.services = stage2SaltServices // stage2SecretServices;

        boot.initrd.secrets = lib.mkIf hasInitrdSecrets initrdBootSecrets;

        boot.initrd.systemd = lib.mkIf hasInitrdSecrets {
          initrdBin = defaultInitrdBinPackages;
          storePaths = map (source: { inherit source; }) initrdServiceStorePaths;
          services = initrdSecretServices;
        };
      })
    ]
    ++ lib.optional hasRaspberryPiConfigOption (
      lib.mkIf (cfg.enable && usesOnlyFirmwareHmac) {
        hardware.raspberry-pi.config.all.options.lock_device_private_key = {
          enable = lib.mkDefault true;
          value = lib.mkDefault 1;
        };
      }
    )
  );
}
