# dotfiles

My configuration files, managed with [GNU Stow](https://www.gnu.org/software/stow/).

Each folder is a stow "package" whose internal structure mirrors `$HOME`. Running `stow <package>` from `~/.dotfiles` creates the symlinks in the right place.

## Contents

| Package | Files | Description |
|---------|-------|-------------|
| `zsh/` | `.zshrc`, `.p10k.zsh` | Zsh with Oh My Zsh + Powerlevel10k theme |
| `git/` | `.gitconfig` | Git configuration (identity lives in `~/.gitconfig.local`) |
| `tmux/` | `.tmux.conf` | Tmux with vi mode, mouse support and session persistence (TPM) |
| `nvim/` | `.config/nvim/` | Neovim with lazy.nvim, LSP (mason), Telescope, Treesitter |
| `vscode/` | `.config/Code/User/settings.json` | VS Code user settings (extensions listed in `vscode/extensions.txt`) |

## Requirements

**Base:**

- `git`, `stow`, `zsh`
- [Oh My Zsh](https://ohmyz.sh/)
- [Powerlevel10k](https://github.com/romkatv/powerlevel10k) (Oh My Zsh theme)
- [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) and [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting) (custom Oh My Zsh plugins)
- A [Nerd Font](https://www.nerdfonts.com/) for the prompt icons

**Tmux:**

- `tmux` + [TPM](https://github.com/tmux-plugins/tpm)
- `wl-clipboard` for clipboard copy (Wayland only; on macOS/X11 adjust `copy-pipe-and-cancel` in `.tmux.conf`)

**Neovim:**

- Neovim ≥ 0.10
- `ripgrep` (for `Telescope live_grep`)
- Plugins and LSP servers install themselves on first launch (lazy.nvim + mason)

**VS Code:**

- `code` on the `PATH` (the `install.sh` step is skipped if absent)
- Extensions are reinstalled from `vscode/extensions.txt`, refresh it with `code --list-extensions > vscode/extensions.txt`

**Optional** (the `.zshrc` detects these and skips them if absent): nvm, bun, mise, Google Cloud SDK, CUDA.

## Installation

```bash
git clone git@github.com:nicoestevez/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh
```

The script is idempotent: it checks the base programs, installs Oh My Zsh / Powerlevel10k / zsh plugins / TPM if missing, runs `stow`, and prompts for your git identity if `~/.gitconfig.local` doesn't exist.

> If a real file (not a symlink) already exists in `$HOME`, stow will fail with a conflict warning. Back up/remove the original file and re-run the script.

After installing:

1. **Tmux plugins** — inside tmux, press `prefix + I`
2. **Neovim** — open `nvim`; lazy.nvim and mason download everything on first launch
3. **VS Code** — the script installs the extensions from `vscode/extensions.txt` (needs `code` on the `PATH`)

<details>
<summary>Manual installation (without the script)</summary>

```bash
cd ~/.dotfiles
stow zsh git tmux nvim vscode
```

And create `~/.gitconfig.local`:

```ini
[user]
	email = you@email.com
	name = yourname
```

</details>

## Machine-specific configuration

Anything specific to a single machine (private aliases, secrets, unusual paths) **does not belong in this repo**:

- `~/.zshrc.local` — sourced at the end of `.zshrc` if it exists
- `~/.gitconfig.local` — included from `.gitconfig` (user identity)

## Adding a new package

```bash
mkdir -p ~/.dotfiles/<package>/<path relative to $HOME>
mv ~/<file> ~/.dotfiles/<package>/<path relative to $HOME>/
cd ~/.dotfiles && stow <package>
```
