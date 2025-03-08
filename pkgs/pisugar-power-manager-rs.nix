{ lib, fetchFromGitHub, rustPlatform }:

rustPlatform.buildRustPackage rec {
  pname = "pisugar-power-manager-rs";
  version = "2.0.0-preview2";

  src = fetchFromGitHub {
    owner = "PiSugar";
    repo = "pisugar-power-manager-rs";
    rev = "v${version}";
    sha256 = "sha256-dKyCBD4+/0NiN28/0aYhUtGyYQcT9ze0fI/Vlw9LxPI=";
  };

  useFetchCargoVendor = true;
  cargoHash = "sha256-EHwlv6XlsltpaSBTKebhrgJYq3GTtB0t5tyNhkiptb8=";

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