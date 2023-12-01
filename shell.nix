{
  pkgs ? import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/bc3ec5eaa759.tar.gz") {} 
}: 

let 
  pkgs_rl = import (fetchTarball "https://github.com/ryansname/nix/archive/3b7e5fe.tar.gz") { inherit pkgs; };
in
pkgs.mkShell {
  nativeBuildInputs = [
    pkgs.pkg-config
    pkgs.curlFull
    pkgs.glfw
    (pkgs_rl.zig { version = "0.12.0-dev.1571+03adafd80"; })
    (pkgs_rl.zls { version = "e89b712"; srcHash = "sha256-VDEkuYGTrqHqfmCrsDjmURFKqDBaowKYkjpdliwK9+A="; zigVersion = "0.12.0-dev.1591+3fc6a2f11"; })
  ];
  
  buildInputs = [
  ];
}
