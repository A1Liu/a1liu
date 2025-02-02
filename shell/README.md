### Directory Structure
- `bash`/`zsh` - Shell scripts only for `bash`/`zsh`
- `common` - Shell scripts run on every shell
- `nix` - Files for `nix-shell` to source. Can be used with `alenv`, e.g.
   ```sh
   # This will run `nix-shell` $CFG_DIR/shell/nix/my-env.nix --command 'zsh'
   # (assuming it exists)
   alenv my-env
   ```

### Environment Variables
- `CFG_DIR` - Configuration directory (this repository)
- `IS_INTERACTIVE_SHELL` - Whether or not the shell is interactive
- `CFG_SHELL_ENV` - Guard variable for checking if path is correctly set
- `CFG_ENV` - Guard variable for checking if environment variables are set
