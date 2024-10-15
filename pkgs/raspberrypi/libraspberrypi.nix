{ lib, stdenv
, fetchFromGitHub
, cmake
, pkg-config
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "libraspberrypi";
  version = "unstable-2023-10-20";

  src = fetchFromGitHub {
    owner = "raspberrypi";
    repo = "userland";
    rev = "96a7334ae9d5fc9db7ac92e59852377df63f1848";
    hash = "sha256-H5wCsK7o4mBmTYpUchmumT4FyWN/cxdsmsYoRhkhOx8=";
  };

  nativeBuildInputs = [ cmake pkg-config ];
  cmakeFlags = [
    # -DARM64=ON disables all targets that only build on 32-bit ARM; this allows
    # the package to build on aarch64 and other architectures
    "-DARM64=${if stdenv.hostPlatform.isAarch32 then "OFF" else "ON"}"
    "-DVMCS_INSTALL_PREFIX=${placeholder "out"}"
  ];

  meta = with lib; {
    description = "ARM side libraries for interfacing to Raspberry Pi GPU";
    homepage = "https://github.com/raspberrypi/userland";
    license = licenses.bsd3;
    platforms = [ "armv6l-linux" "armv7l-linux" "aarch64-linux" "x86_64-linux" ];
    maintainers = with maintainers; [ dezgeg tkerber ];
  };
})