#!/bin/bash
# === AST Miner Installation Optimisée - Ryzen 9 9950X ===

set -e

# Variables
INSTALL_DIR="/miner/astatine"
REPO_URL="https://github.com/Jecta-ai/ast-miner-cli.git"
SCREEN_NAME="astminer"

echo "=== AST Miner Installation Optimisée - Début ==="

# 1️⃣ Créer le dossier d'installation
mkdir -p $INSTALL_DIR
cd $INSTALL_DIR

# 2️⃣ Installer les prérequis système
sudo apt update
sudo apt install -y git curl wget build-essential numactl gpg jq screen ca-certificates openssl

# 3️⃣ Installer Node.js LTS (24.x) via Nodesource
curl -fsSL https://deb.nodesource.com/setup_24.x | sudo -E bash -
sudo apt install -y nodejs
echo "Node version: $(node -v)"
echo "NPM version: $(npm -v)"

# 4️⃣ Installer NVM (facultatif, pour gérer plusieurs versions Node)
if [ ! -d "$HOME/.nvm" ]; then
  wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.9/install.sh | bash
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  echo "NVM version: $(nvm --version)"
fi

# 5️⃣ Cloner le dépôt officiel du miner
if [ ! -d "$INSTALL_DIR/.git" ]; then
  git clone $REPO_URL $INSTALL_DIR
else
  echo "Mise à jour du repo existant..."
  git pull
fi

# 6️⃣ Installer les dépendances npm
npm install

# 7️⃣ Lancer le miner dans un screen avec optimisation Ryzen
echo "Lancement du miner dans screen..."
screen -dmS $SCREEN_NAME bash -c "numactl --interleave=all npm start"

echo "=== INSTALLATION TERMINEE ==="
echo "Pour suivre les logs du miner : sudo journalctl -u astminer -f (si service systemd configuré)"
echo "Pour rejoindre le screen du miner : screen -r $SCREEN_NAME"
