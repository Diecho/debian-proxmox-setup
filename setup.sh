#!/bin/bash
set -e

echo "Starting the Ultimate Debian Terminal Setup..."

# 1. Get the true user and home directory
TRUE_USER=$(whoami)
TRUE_HOME=$(eval echo ~$TRUE_USER)
export HOME=$TRUE_HOME
export ZSH="$TRUE_HOME/.oh-my-zsh"

# 2. Update system and install the essentials (Added cmatrix)
echo "Installing base packages..."
sudo apt-get update
sudo apt-get install -y zsh git curl btop bat fzf ripgrep unzip make gcc locales-all cmatrix

if [ -f /usr/bin/batcat ]; then
    sudo ln -sf /usr/bin/batcat /usr/local/bin/bat
fi

# 3. Install Fastfetch
echo "Installing Fastfetch directly from GitHub..."
sudo rm -f fastfetch-linux-amd64.deb
curl -fLO https://github.com/fastfetch-cli/fastfetch/releases/latest/download/fastfetch-linux-amd64.deb
sudo dpkg -i fastfetch-linux-amd64.deb
rm fastfetch-linux-amd64.deb

# 4. Install Tailscale
echo "Installing Tailscale..."
curl -fsSL https://tailscale.com/install.sh | sh

# 5. Install Oh My Zsh
echo "Installing Oh My Zsh..."
if [ ! -d "$ZSH" ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
    echo "Oh My Zsh is already installed, skipping cleanly..."
fi

# 6. Download Visual Plugins
echo "Downloading Zsh Plugins..."
ZSH_CUSTOM_DIR="$ZSH/custom/plugins"
mkdir -p "$ZSH_CUSTOM_DIR"

if [ ! -d "$ZSH_CUSTOM_DIR/zsh-syntax-highlighting" ]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM_DIR/zsh-syntax-highlighting"
fi
if [ ! -d "$ZSH_CUSTOM_DIR/zsh-autosuggestions" ]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM_DIR/zsh-autosuggestions"
fi

# 7. Write the .zshrc file
echo "Writing Zsh configuration..."
cat << 'EOF' > "$TRUE_HOME/.zshrc"
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export ZSH="$HOME/.oh-my-zsh"

# Reverted to default theme
ZSH_THEME="robbyrussell"

# Plugins
plugins=(git sudo extract web-search zsh-autosuggestions zsh-syntax-highlighting)
source $ZSH/oh-my-zsh.sh

# Initialize fzf
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# --- CUSTOM ALIASES ---
alias reload="clear && source ~/.zshrc"
alias update="sudo apt update && sudo apt upgrade -y"
alias vim="nvim"

# Run Fastfetch when opening the terminal
fastfetch
EOF

# 8. Install Neovim
echo "Installing modern Neovim..."
sudo rm -rf /opt/nvim /usr/local/bin/nvim nvim-linux-x86_64.tar.gz
curl -fLO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz
sudo mv /opt/nvim-linux-x86_64 /opt/nvim
sudo ln -sf /opt/nvim/bin/nvim /usr/local/bin/nvim
rm nvim-linux-x86_64.tar.gz

# 9. Configure Neovim (Now with Oxocarbon)
echo "Setting up Neovim configuration..."
NVIM_CONFIG_DIR="$TRUE_HOME/.config/nvim"
mkdir -p "$NVIM_CONFIG_DIR"

cat << 'EOF' > "$NVIM_CONFIG_DIR/init.lua"
vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.opt.number = true
vim.opt.termguicolors = true
vim.opt.timeout = true
vim.opt.timeoutlen = 300

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({"git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath})
end
vim.opt.rtp:prepend(lazypath)

-- Load Plugins
require("lazy").setup({
  { "nyoom-engineering/oxocarbon.nvim" },
  { "nvim-telescope/telescope.nvim", branch = "0.1.x", dependencies = { "nvim-lua/plenary.nvim" } },
  { "folke/which-key.nvim", event = "VeryLazy" },
  { "numToStr/Comment.nvim", config = true },
  { "akinsho/bufferline.nvim", dependencies = "nvim-tree/nvim-web-devicons" },
  { "nvim-neo-tree/neo-tree.nvim", branch = "v3.x", dependencies = { "nvim-lua/plenary.nvim", "nvim-tree/nvim-web-devicons", "MunifTanjim/nui.nvim" } }
})

-- Apply Oxocarbon Theme
vim.cmd("colorscheme oxocarbon")
require("bufferline").setup{}

local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = "Find Files" })
vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = "Live Grep" })
vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = "Find Open Buffers" })
vim.keymap.set('n', '<leader>e', '<cmd>Neotree toggle<CR>', { desc = "Toggle Explorer" })
vim.keymap.set('n', '<S-l>', '<cmd>BufferLineCycleNext<CR>', { desc = "Next Tab" })
vim.keymap.set('n', '<S-h>', '<cmd>BufferLineCyclePrev<CR>', { desc = "Previous Tab" })
EOF

# 10. Set Default Shell
sudo chsh -s $(which zsh) $TRUE_USER

echo "SUCCESS! Setup complete."
