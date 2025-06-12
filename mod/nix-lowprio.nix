{...}: {
    nix.daemonIOSchedPriority = 7;
    nix.daemonIOSchedClass = "idle";
    nix.daemonCPUSchedPolicy = "idle";
}
