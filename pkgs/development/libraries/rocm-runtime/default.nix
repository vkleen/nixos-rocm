{ stdenv
, lib
, fetchFromGitHub
, addOpenGLRunpath
, clang-unwrapped
, cmake
, xxd
, elfutils
, llvm
, rocm-device-libs
, rocm-thunk }:

stdenv.mkDerivation rec {
  pname = "rocm-runtime";
  version = "3.8.0";

  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "ROCR-Runtime";
    rev = "rocm-${version}";
    sha256 = "1lm4cbx1d727zll85vjc1kykc72mk82nfhyyhjljv82gd4mnz00c";
  };

  sourceRoot = "source/src";

  nativeBuildInputs = [ cmake xxd ];

  buildInputs = [ clang-unwrapped elfutils llvm ];

  cmakeFlags = [
   "-DBITCODE_DIR=${rocm-device-libs}/lib"
   "-DCMAKE_PREFIX_PATH=${rocm-thunk}"
  ] ++ lib.optional stdenv.isPower9 "-DIMAGE_SUPPORT=off";

  NIX_CFLAGS_COMPILE = [
    "-DNO_WARN_X86_INTRINSICS"
    "-Wno-error=attributes"
  ];

  patches = [
    ./rocr-power9.patch
  ];

  postPatch = ''
    patchShebangs image/blit_src/create_hsaco_ascii_file.sh
  '';

  fixupPhase = ''
    rm -rf $out/hsa
  '';

  meta = with stdenv.lib; {
    description = "Platform runtime for ROCm";
    homepage = "https://github.com/RadeonOpenCompute/ROCR-Runtime";
    license = with licenses; [ ncsa ];
    maintainers = with maintainers; [ danieldk ];
  };
}
