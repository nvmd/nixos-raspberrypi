{ lib, fetchFromGitHub, rustPlatform }:

rustPlatform.buildRustPackage rec {
  pname = "pisugar-power-manager-rs";
  version = "unstable-2024-11-19";

  src = fetchFromGitHub {
    owner = "PiSugar";
    repo = "pisugar-power-manager-rs";
    rev = "dd33fe8171a607b0f5605e360bb8ecc85aab47f6";
    sha256 = "sha256-GwRLu779O4POiqxqzAQO9PhDC8ll5cFRidHIg13sC1s=";
  };

  cargoHash = "sha256-IDH56pTddM4ja2UCcEUe0s8VhriQaKn5T++yDdl76jE=";

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