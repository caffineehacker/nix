{...}: {
  tw.containers.lemmy.enable = true;

  networking.nat.enable = true;
  networking.nat.internalInterfaces = [ "ve-+" ];
  networking.nat.externalInterface = "enp30s0";
}