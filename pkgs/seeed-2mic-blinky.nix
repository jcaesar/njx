{
  gegensprech,
  callPackage,
}: let
in
  callPackage (gegensprech.src + /blinky) {}
