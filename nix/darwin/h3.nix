{ ... }:

# The work laptop: the shared configuration in flake.nix, plus the fix for
# Netskope, which intercepts TLS and re-signs it with a CA that Nix doesn't
# trust out of the box.
{
  nix.settings.ssl-cert-file =
    "/Library/Application Support/Netskope/Certs/netskope-cert-bundle.pem";
}
