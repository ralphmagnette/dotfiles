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
if ! /usr/libexec/java_home >/dev/null 2>&1; then
  echo "☕ Java runtime not detected. Installing OpenJDK..."

  if brew install openjdk; then
    echo "   ✅ OpenJDK installed successfully"
  else
    echo "   ❌ Failed to install OpenJDK"
    exit 1
  fi

  echo "🔗 Making Java visible to macOS..."

  sudo mkdir -p /Library/Java/JavaVirtualMachines

  if sudo ln -sfn /opt/homebrew/opt/openjdk/libexec/openjdk.jdk \
    /Library/Java/JavaVirtualMachines/openjdk.jdk; then
    echo "   ✅ Java symlink created successfully"
  else
    echo "   ❌ Failed to create Java symlink"
    echo "   💡 Try manually:"
    echo "      sudo ln -sfn /opt/homebrew/opt/openjdk/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk.jdk"
    exit 1
  fi

  echo "🧭 Configuring JAVA_HOME..."

  if ! grep -q "JAVA_HOME" ~/.zprofile 2>/dev/null; then
    {
      echo ""
      echo "# Java"
      echo 'export JAVA_HOME=$(/usr/libexec/java_home)'
      echo 'export PATH="$JAVA_HOME/bin:$PATH"'
    } >>~/.zprofile
    echo "   ✅ Added JAVA_HOME to ~/.zprofile"
  else
    echo "   ℹ️ JAVA_HOME already configured in ~/.zprofile"
  fi

  export JAVA_HOME=$(/usr/libexec/java_home)
  export PATH="$JAVA_HOME/bin:$PATH"

  echo "   ✅ Java loaded for current session"
else
  echo "✅ Java already installed and visible to macOS"
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
# 5b. Install zsh framework + theme + plugins
#
# zsh/.zshrc sources oh-my-zsh and loads powerlevel10k, zsh-autosuggestions and
# zsh-syntax-highlighting. None of them are brew packages, so without this step the
# stowed .zshrc fails on first login.
# --------------------------------------
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo "🐚 Installing oh-my-zsh..."
  # KEEP_ZSHRC stops the installer replacing a .zshrc that stow is about to own.
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
  echo "✅ oh-my-zsh already installed"
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

clone_if_missing() {
  local repo="$1" dest="$2" name="$3"
  if [ -d "$dest" ]; then
    echo "✅ $name already installed"
  else
    echo "🎨 Installing $name..."
    git clone --depth=1 "$repo" "$dest"
  fi
}

clone_if_missing https://github.com/romkatv/powerlevel10k.git \
  "$ZSH_CUSTOM/themes/powerlevel10k" "powerlevel10k"
clone_if_missing https://github.com/zsh-users/zsh-autosuggestions.git \
  "$ZSH_CUSTOM/plugins/zsh-autosuggestions" "zsh-autosuggestions"
clone_if_missing https://github.com/zsh-users/zsh-syntax-highlighting.git \
  "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" "zsh-syntax-highlighting"

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

for dir in nvim tmux ghostty; do
  if [ -d "$HOME/.config/$dir" ] && [ ! -L "$HOME/.config/$dir" ]; then
    mv "$HOME/.config/$dir" "$backup_dir/"
  fi
done

# --------------------------------------
# 7. Apply Stow
# --------------------------------------
echo "🔗 Creating symlinks with Stow..."

packages=(nvim tmux ghostty zsh)

for pkg in "${packages[@]}"; do
  # A name that no longer has a directory used to abort the whole run before the
  # remaining packages were linked. Warn and carry on instead.
  if [ ! -d "$pkg" ]; then
    echo "   ⚠️ Skipping $pkg — no such directory in dotfiles"
    continue
  fi

  echo "   → Linking $pkg..."

  if stow -t ~ "$pkg"; then
    echo "   ✅ Successfully linked $pkg"
  else
    echo "   ❌ Failed to link $pkg"
    echo "   💡 Run: stow -n -v -t ~ $pkg"
    exit 1
  fi
done

echo "🎉 All symlinks created successfully!"

# --------------------------------------
# 8. Final message
# --------------------------------------
echo ""
echo "🎉 Setup complete!"
echo "👉 Restart your terminal or run:"
echo "   source ~/.zshrc"
