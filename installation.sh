#!/bin/bash
set -e

INSTALL_DIR="/miner/astatine"
REPO_URL="https://github.com/Jecta-ai/ast-miner-cli.git"
SCREEN_NAME="astminer"

echo "=== AST Miner Installation Optimisée - Début ==="

# 0️⃣ Supprimer le dossier existant pour une installation propre
if [ -d "$INSTALL_DIR" ]; then
    echo "Suppression de l'ancien dossier d'installation..."
    sudo rm -rf $INSTALL_DIR
fi

# 1️⃣ Créer le dossier d'installation
mkdir -p $INSTALL_DIR
cd $INSTALL_DIR

# 2️⃣ Installer prérequis
sudo apt update
sudo apt install -y git curl wget build-essential numactl gpg jq screen ca-certificates openssl

# 3️⃣ Installer Node.js LTS
curl -fsSL https://deb.nodesource.com/setup_24.x | sudo -E bash -
sudo apt install -y nodejs
echo "Node version: $(node -v)"
echo "NPM version: $(npm -v)"

# 4️⃣ Installer NVM si non présent
if [ ! -d "$HOME/.nvm" ]; then
    wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.9/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    echo "NVM version: $(nvm --version)"
fi

# 5️⃣ Cloner le dépôt officiel
echo "Clonage du dépôt officiel..."
git clone $REPO_URL $INSTALL_DIR

# 6️⃣ Installer dépendances npm
npm install

# 7️⃣ Lancer le miner dans screen avec optimisation Ryzen 9
screen -dmS $SCREEN_NAME bash -c "numactl --interleave=all npm start"

echo "=== INSTALLATION TERMINEE ==="
echo "Pour rejoindre le screen du miner : screen -r $SCREEN_NAME"
echo "Pour suivre les logs du miner : sudo journalctl -u astminer -f"
