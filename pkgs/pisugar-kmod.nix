{ stdenv, lib, fetchFromGitHub, kernel, kmod, pisugarVersion }:

stdenv.mkDerivation (finalAttrs: {
  pname = "pisugar${pisugarVersion}-kmod";
  version = "unstable-2024-11-19";

  src = fetchFromGitHub {
    owner = "PiSugar";
    repo = "pisugar-power-manager-rs";
    rev = "dd33fe8171a607b0f5605e360bb8ecc85aab47f6";
    sha256 = "sha256-GwRLu779O4POiqxqzAQO9PhDC8ll5cFRidHIg13sC1s=";
  };

  sourceRoot = "${finalAttrs.src.name}/pisugar-module/pisugar-${pisugarVersion}";

  hardeningDisable = [ "pic" ];
  nativeBuildInputs = kernel.moduleBuildDependencies;

  configurePhase = ''
    export KERNEL_MODULE_SRC=$(pwd)
  '';

  makeFlags = [
    "V=1"
    "ARCH=${stdenv.hostPlatform.linuxArch}"
  ] ++ lib.optionals (stdenv.hostPlatform != stdenv.buildPlatform) [
    "CROSS_COMPILE=${stdenv.cc.targetPrefix}"
  ];
  KSRC = "${kernel.dev}/lib/modules/${kernel.modDirVersion}/build";

  buildPhase = ''
    make $makeFlags -C ${finalAttrs.KSRC} M="$KERNEL_MODULE_SRC" modules
  '';

  installPhase = ''
    runHook preInstall
    install -vD "$KERNEL_MODULE_SRC/pisugar_${pisugarVersion}_battery.ko" -t $out/lib/modules/${kernel.modDirVersion}/kernel/drivers/power/supply
    runHook postInstall
  '';

  enableParallelBuilding = true;

  meta = with lib; {
    description = "Kernel module for PiSugar${pisugarVersion} battery module";
    homepage = "https://github.com/PiSugar/pisugar-power-manager-rs.git";
    license = licenses.gpl3Only;
    maintainers = with maintainers; [ kazenyuk ];
    platforms = platforms.linux;
  };
})