{
  lib,
  fetchFromGitHub,
  rustPlatform,
}:

rustPlatform.buildRustPackage rec {
  pname = "pisugar-power-manager-rs";
  version = "2.3.3";

  src = fetchFromGitHub {
    owner = "PiSugar";
    repo = "pisugar-power-manager-rs";
    rev = "v${version}";
    sha256 = "sha256-UmiaSQhIIIZawJH+O3Sc4bS5Jr4zayJMSdJeoUhBS5w=";
  };

  cargoHash = "sha256-8wp1RxeoAmPk8sMUy2UY+t0RhO/bpK2e322bmoA5ac4=";

  postPatch = ''
    sed -e 's#.*replace-with.*##' -i .cargo/config.toml
  '';

  postInstall = ''
    examples_src=scripts
    declare -a examples=(
      BootWatchdogPiSugar3.sh
      PiSugarSButtonActive.sh
      SoftwareWatchdogPiSugar3.sh
      power-on-off.sh
      readme.md
      record-level.sh
    )

    for i in "''${examples[@]}"; do
      install -vD "$examples_src/$i" -t $out/share/examples
    done
  '';

  meta = with lib; {
    description = "Power management software for PiSugar boards";
    homepage = "https://github.com/PiSugar/pisugar-power-manager-rs";
    license = licenses.gpl3Only;
    maintainers = with maintainers; [ kazenyuk ];
  };
}
