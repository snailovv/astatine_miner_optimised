#!/bin/bash
set -e

echo "=== AST Miner Installation Optimisée - Début ==="

# Installer les dépendances système
sudo apt update
sudo apt install -y git curl wget build-essential numactl gpg jq screen ca-certificates openssl linux-tools-common linux-tools-$(uname -r)

# Installer NVM (pour l'utilisateur root)
export NVM_DIR="/root/.nvm"
if [ ! -d "$NVM_DIR" ]; then
    echo "Installation de NVM..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.9/install.sh | bash
fi
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Installer Node.js LTS via NVM
echo "Installation / mise à jour de Node.js LTS..."
nvm install --lts
nvm use --lts
nvm alias default lts/*

# Mettre à jour npm
npm install -g npm

# Créer l'utilisateur astminer si besoin
id -u astminer &>/dev/null || sudo useradd -m -s /bin/bash astminer

# Créer le dossier du miner et récupérer le repo
sudo mkdir -p /opt/ast-miner-cli
sudo chown astminer:astminer /opt/ast-miner-cli
cd /opt/ast-miner-cli
if [ -d ".git" ]; then
    git pull
else
    sudo -u astminer git clone https://github.com/snailovv/astatine_miner_optimised.git .
fi

# Installer les dépendances npm pour le miner
sudo -u astminer bash -c "source $NVM_DIR/nvm.sh && npm install"

# Lancer le miner dans un screen
echo "Démarrage du miner dans screen 'astatine'..."
sudo -u astminer screen -dmS astatine bash -c "source $NVM_DIR/nvm.sh && npm start"

echo "=== INSTALLATION TERMINEE ==="
echo "Pour suivre les logs du miner : sudo journalctl -u astminer -f"
echo "Pour rejoindre le screen du miner : screen -r astatine"
