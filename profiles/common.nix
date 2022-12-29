# A default configuration that applies to all servers.
# Common configuration accross *all* the machines
{ config, pkgs, lib, ... }:
{
  imports = [
    ./common/upgrade-diff.nix
    ./common/well-known-hosts.nix
    ./common/zfs.nix
    ./common/serial.nix
  ];

  # Use systemd during boot as well on systems that do not require networking in early-boot
  boot.initrd.systemd.enable = lib.mkDefault (!config.boot.initrd.network.enable);

  # Work around for https://github.com/NixOS/nixpkgs/issues/124215
  documentation.info.enable = false;

  # Allow PMTU / DHCP
  networking.firewall.allowPing = true;

  # Use networkd instead of the pile of shell scripts
  networking.useNetworkd = lib.mkDefault true;
  networking.useDHCP = lib.mkDefault false;

  # Fallback quickly if substituters are not available.
  nix.settings.connect-timeout = 5;

  # Enable flakes
  nix.settings.experimental-features = "nix-command flakes";

  # The default at 10 is rarely enough.
  nix.settings.log-lines = lib.mkDefault 25;

  # Avoid disk full issues
  nix.settings.max-free = lib.mkDefault (1000 * 1000 * 1000);
  nix.settings.min-free = lib.mkDefault (128 * 1000 * 1000);

  # Avoid copying unnecessary stuff over SSH
  nix.settings.builders-use-substitutes = true;

  # Use the better version of nscd
  services.nscd.enableNsncd = true;

  # Allow sudo from the @wheel users
  security.sudo.enable = true;

  # Enable SSH everywhere
  services.openssh = {
    forwardX11 = false;
    kbdInteractiveAuthentication = false;
    passwordAuthentication = false;
    useDns = false;
    # Only allow system-level authorized_keys to avoid injections.
    # We currently don't enable this when git-based software that relies on this is enabled.
    # It would be nicer to make it more granular using `Match`.
    # However those match blocks cannot be put after other `extraConfig` lines
    # with the current sshd config module, which is however something the sshd
    # config parser mandates.
    authorizedKeysFiles = lib.mkIf (!config.services.gitea.enable && !config.services.gitlab.enable && !config.services.gitolite.enable && !config.services.gerrit.enable)
      (lib.mkForce [ "/etc/ssh/authorized_keys.d/%u" ]);

    # unbind gnupg sockets if they exists
    extraConfig = "StreamLocalBindUnlink yes";
  };

  systemd = {
    # Often hangs
    # https://github.com/systemd/systemd/blob/e1b45a756f71deac8c1aa9a008bd0dab47f64777/NEWS#L13
    services = {
      NetworkManager-wait-online.enable = false;
    };
    network.wait-online.enable = false;
  };
}