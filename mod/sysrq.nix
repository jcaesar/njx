{lib, ...}: {
  # Anti-oom-measures pt 2 (press SysRq+Alt+f)
  boot.kernel.sysctl."kernel.sysrq" = let
    inherit (lib) bitOr fold;
    all = 1;
    log = 2; # enable control of console logging level
    sak = 4; # enable control of keyboard (SAK, unraw)
    dmp = 8; # enable debugging dumps of processes etc.
    syn = 16; # enable sync command
    mro = 32; # enable remount read-only
    sig = 64; # enable signalling of processes (term, kill, oom-kill)
    off = 128; # allow reboot/poweroff
    rtt = 256; # allow nicing of all RT tasks
  in
    fold bitOr 0 [log sak syn mro sig off];
}
