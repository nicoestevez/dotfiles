#!/usr/bin/env bash
#
# Dotfiles bootstrap: installs shell dependencies and creates the symlinks.
# Idempotent: safe to run multiple times.

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGES=(zsh git tmux nvim vscode kitty herdr)

info() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m==> WARN:\033[0m %s\n' "$*"; }
fail() { printf '\033[1;31m==> ERROR:\033[0m %s\n' "$*" >&2; exit 1; }

# --- 1. Base programs (installed with the system package manager) ---
missing=()
for cmd in git stow zsh tmux nvim curl; do
  command -v "$cmd" >/dev/null || missing+=("$cmd")
done
if [ ${#missing[@]} -gt 0 ]; then
  printf 'Missing programs: %s\n' "${missing[*]}"
  printf 'Install them first, e.g.:\n'
  printf '  Arch:   sudo pacman -S %s\n' "${missing[*]}"
  printf '  Debian: sudo apt install %s\n' "${missing[*]}"
  printf '  macOS:  brew install %s\n' "${missing[*]}"
  fail "base dependencies incomplete"
fi

# nvim-treesitter (main branch) compiles its parsers locally and needs a C
# compiler plus the tree-sitter CLI. Not fatal, but without them nvim shows
# no syntax highlighting for most filetypes.
for cmd in cc tree-sitter; do
  command -v "$cmd" >/dev/null || warn "'$cmd' not found: nvim-treesitter cannot compile parsers (Arch: sudo pacman -S base-devel tree-sitter-cli; without sudo: npm install -g tree-sitter-cli)"
done
# conform.nvim formats Lua with stylua on save; without it, it falls back to
# lua_ls and re-indents the config to 4 spaces. Mason installs it from nvim.
command -v stylua >/dev/null || [ -x "$HOME/.local/share/nvim/mason/bin/stylua" ] ||
  warn "'stylua' not found: run :MasonInstall stylua inside nvim (or sudo pacman -S stylua)"
# External tools nvim shells out to: ripgrep for Telescope live_grep, lazygit
# for the snacks.nvim <leader>gg / <leader>gl / <leader>gf keymaps.
for cmd in rg lazygit; do
  command -v "$cmd" >/dev/null || warn "'$cmd' not found: nvim keymaps that use it will fail (Arch: sudo pacman -S ripgrep lazygit; without sudo: mise use -g ripgrep lazygit; macOS: brew install ripgrep lazygit)"
done

# --- 2. Oh My Zsh ---
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  info "Installing Oh My Zsh..."
  # RUNZSH=no: don't drop into zsh afterwards; KEEP_ZSHRC=yes: don't touch our .zshrc
  RUNZSH=no KEEP_ZSHRC=yes sh -c \
    "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# --- 3. Zsh theme and plugins + TPM ---
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

clone_if_missing() { # repo dest
  [ -d "$2" ] || { info "Cloning $1..."; git clone --depth=1 "https://github.com/$1" "$2"; }
}

clone_if_missing romkatv/powerlevel10k "$ZSH_CUSTOM/themes/powerlevel10k"
clone_if_missing zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
clone_if_missing zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
clone_if_missing tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"

# --- 4. herdr (terminal multiplexer; the config in herdr/ assumes it exists) ---
if ! command -v herdr >/dev/null; then
  info "Installing herdr..."
  curl -fsSL https://herdr.dev/install.sh | sh ||
    warn "herdr install failed; install it manually: curl -fsSL https://herdr.dev/install.sh | sh"
fi

# --- 5. Symlinks ---
info "Creating symlinks with stow: ${PACKAGES[*]}"
cd "$DOTFILES_DIR"
stow --restow "${PACKAGES[@]}" ||
  fail "stow conflict: back up/remove the real files that already exist in \$HOME and retry"

# --- 6. VS Code extensions (settings.json is symlinked by stow) ---
if command -v code >/dev/null && [ -f "$DOTFILES_DIR/vscode/extensions.txt" ]; then
  info "Installing VS Code extensions..."
  xargs -n1 code --install-extension < "$DOTFILES_DIR/vscode/extensions.txt" || \
    warn "some VS Code extensions failed to install"
fi

# --- 7. Git identity (kept out of the repo) ---
if [ ! -f "$HOME/.gitconfig.local" ]; then
  info "Setting up git identity (stored in ~/.gitconfig.local, not in the repo)"
  read -rp "  Name:  " git_name
  read -rp "  Email: " git_email
  printf '[user]\n\tname = %s\n\temail = %s\n' "$git_name" "$git_email" > "$HOME/.gitconfig.local"
fi

info "Done. Final steps:"
echo "  - If zsh is not your default shell: chsh -s \$(which zsh)"
echo "  - Inside tmux, press prefix + I to install plugins (TPM)"
echo "  - Open nvim: lazy.nvim and mason install everything on first launch"
echo "  - Launch herdr inside kitty; its config is ~/.config/herdr/config.toml"
