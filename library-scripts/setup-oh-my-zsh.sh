#!/bin/bash
# setup-oh-my-zsh.sh

echo "Setting up Oh-My-Zsh and plugins..."

# Install Oh-My-Zsh if not already installed
if [ ! -d "/root/.oh-my-zsh" ]; then
    echo "Installing Oh-My-Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
    echo "Oh-My-Zsh is already installed."
fi

# Clone additional plugins
echo "Installing additional plugins..."
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# Update the plugins list in .zshrc
echo "Configuring .zshrc..."
sed -i 's/plugins=(git)/plugins=(git terraform zsh-autosuggestions zsh-syntax-highlighting)/' ~/.zshrc

# Install Atuin and configure it for Zsh
echo "Installing Atuin..."
curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh 
echo 'eval "$(atuin init zsh)"' >> ~/.zshrc

# Apply a preferred theme (optional)
sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="agnoster"/' ~/.zshrc

# Set Zsh as the default shell
chsh -s "$(which zsh)" vscode

echo "Oh-My-Zsh setup complete!"
