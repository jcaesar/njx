{pkgs, ...}: {
  environment.systemPackages = with pkgs; [aircrack-ng iw];
  programs.wireshark = {
    enable = true;
    dumpcap.enable = true;
    usbmon.enable = true;
  };
  # Lost your phone but it responds to ping?
  # - Figure out target MAC address: sudo arping fon.lan
  # - Figure out your WiFi channel: wpa_cli scan_results | grep WIFI
  # - Send some traffic (from a different device in screen): ping fon.lan
  # - Set interface to monitor mode: sudo airmon-ng start wlan0 2472
  # - Hop to correct frequency: sudo iw wlan0mon set freq 2472
  # - Open wireshark: sudo -g wireshark wireshark
  # - Start campturing on wlan0mon
  # - Add a source MAC display filter: wlan.sa == 76:59:73:F2:DE:36
  # - Open any packet → Radiotap Header → Antenna signal → [context menu] → Apply as column
  # - Watch most recent packet signal strength
  # - Roughly: far 80dBm, next room 60dBm, same room 40dBm, right on top 20dBm
}
