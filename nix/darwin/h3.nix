{ ... }:

# The work machine: a MacOS workstation sitting behind Netskope, which
# terminates TLS and re-signs it with its own CA. Everything else about the
# machine is the shared configuration in flake.nix.
#
# This is the system half of the trust store; `home-manager/h3.nix` is the user
# half. Both are needed, because they're read by different processes.
#
# Deliberately not in the shared configuration: the bundle below only exists on
# machines with Netskope installed, and pointing Nix at a file that isn't there
# makes every download fail on the personal machines instead.
{
  # Writes /etc/nix/nix.conf, which is what the nix-daemon reads, so substituter
  # downloads trust the proxy too. Without it they die with "SSL peer
  # certificate or SSH remote key was not OK (60)", because Nix checks the
  # proxy's certificate against the nss-cacert bundle it ships with, which has
  # no Netskope root in it.
  #
  # This is also the only thing that covers `just switch-darwin`: that runs Nix
  # under sudo, which drops $NIX_SSL_CERT_FILE from the environment -- and
  # nix.conf outranks that variable anyway.
  #
  # nix.conf is NOT shell, so the space stays a plain space. The backslash in
  # `/Library/Application\ Support/...` is only correct in ~/.zshenv, where the
  # shell eats it. Here it would survive into the value verbatim and Nix would
  # fail with "Problem with the SSL CA cert (path? access rights?) (77)" on a
  # path that doesn't exist.
  nix.settings.ssl-cert-file =
    "/Library/Application Support/Netskope/Certs/netskope-cert-bundle.pem";
}
