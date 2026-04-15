#!/bin/bash

set -e

echo "🚀 Starting dotfiles setup..."

# --------------------------------------
# 1. Install Homebrew (if missing)
# --------------------------------------
if ! command -v brew >/dev/null 2>&1; then
  echo "🍺 Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >>~/.zprofile
  eval "$(/opt/homebrew/bin/brew shellenv)"
else
  echo "✅ Homebrew already installed"
fi

# --------------------------------------
# 2. Install required packages
# --------------------------------------
echo "📦 Installing core tools..."
brew install git stow

# --------------------------------------
# 2b. Install Java (if missing)
# --------------------------------------
if ! command -v java >/dev/null 2>&1; then
  echo "☕ Installing Java..."
  brew install openjdk

  # Ensure JAVA_HOME is set in .zprofile (only once)
  if ! grep -q "JAVA_HOME" ~/.zprofile 2>/dev/null; then
    echo '' >>~/.zprofile
    echo '# Java' >>~/.zprofile
    echo 'export JAVA_HOME=$(/usr/libexec/java_home)' >>~/.zprofile
    echo 'export PATH="$JAVA_HOME/bin:$PATH"' >>~/.zprofile
  fi

  # Load for current session
  export JAVA_HOME=$(/usr/libexec/java_home)
  export PATH="$JAVA_HOME/bin:$PATH"
else
  echo "✅ Java already installed"
fi

# --------------------------------------
# 3. Ensure Git is configured
# --------------------------------------
if ! git config --global user.name >/dev/null; then
  echo "⚠️ Git user.name not set"
  read -p "Enter your Git name: " git_name
  git config --global user.name "$git_name"
fi

if ! git config --global user.email >/dev/null; then
  echo "⚠️ Git user.email not set"
  read -p "Enter your Git email: " git_email
  git config --global user.email "$git_email"
fi

# --------------------------------------
# 4. Clone dotfiles (if not already)
# --------------------------------------
if [ ! -d "$HOME/dotfiles" ]; then
  echo "📥 Cloning dotfiles..."

  if ssh -T git@github.com >/dev/null 2>&1; then
    git clone git@github.com:ralphmagnette/dotfiles.git ~/dotfiles
  else
    echo "⚠️ SSH not configured, using HTTPS..."
    git clone https://github.com/ralphmagnette/dotfiles.git ~/dotfiles
  fi
else
  echo "✅ Dotfiles already exist"
fi

cd ~/dotfiles

# --------------------------------------
# 5. Install Brew packages
# --------------------------------------
if [ -f Brewfile ]; then
  echo "📦 Installing Brewfile packages..."
  brew bundle --file=~/dotfiles/Brewfile
else
  echo "⚠️ No Brewfile found"
fi

# --------------------------------------
# 6. Backup existing configs (safe Stow)
# --------------------------------------
backup_dir="$HOME/.dotfiles-backup-$(date +%s)"
mkdir -p "$backup_dir"

echo "🛟 Backing up existing configs to $backup_dir"

for file in .zshrc .zprofile; do
  if [ -f "$HOME/$file" ] && [ ! -L "$HOME/$file" ]; then
    mv "$HOME/$file" "$backup_dir/"
  fi
done

for dir in nvim tmux ghostty starship; do
  if [ -d "$HOME/.config/$dir" ] && [ ! -L "$HOME/.config/$dir" ]; then
    mv "$HOME/.config/$dir" "$backup_dir/"
  fi
done

# --------------------------------------
# 7. Apply Stow
# --------------------------------------
echo "🔗 Applying dotfiles with Stow..."
stow -t ~ nvim tmux ghostty starship zsh

# --------------------------------------
# 8. Final message
# --------------------------------------
echo ""
echo "🎉 Setup complete!"
echo "👉 Restart your terminal or run:"
echo "   source ~/.zshrc"
