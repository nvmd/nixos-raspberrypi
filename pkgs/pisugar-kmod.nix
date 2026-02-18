{
  stdenv,
  lib,
  fetchFromGitHub,
  kernel,
  kmod,
  pisugarVersion,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "pisugar${pisugarVersion}-kmod";
  version = "2.0.0-preview2";

  src = fetchFromGitHub {
    owner = "PiSugar";
    repo = "pisugar-power-manager-rs";
    rev = "v${finalAttrs.version}";
    sha256 = "sha256-dKyCBD4+/0NiN28/0aYhUtGyYQcT9ze0fI/Vlw9LxPI=";
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
  ]
  ++ lib.optionals (stdenv.hostPlatform != stdenv.buildPlatform) [
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
