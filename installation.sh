#!/bin/bash
set -e

echo "=== AST Miner Installation Optimisée - Début ==="

# Installer les dépendances système
sudo apt update
sudo apt install -y git curl wget build-essential numactl gpg jq screen ca-certificates openssl linux-tools-common linux-tools-$(uname -r)

# Installer Node.js globalement (NodeSource)
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt install -y nodejs

# Vérifier node et npm
echo "Node version: $(node -v)"
echo "NPM version: $(npm -v)"

# Créer l'utilisateur astminer si besoin
id -u astminer &>/dev/null || sudo useradd -m -s /bin/bash astminer

# Créer le dossier du miner et récupérer le repo
sudo mkdir -p /opt/ast-miner-cli
sudo chown astminer:astminer /opt/ast-miner-cli
cd /opt/ast-miner-cli
if [ -d ".git" ]; then
    sudo -u astminer git pull
else
    sudo -u astminer git clone https://github.com/snailovv/astatine_miner_optimised.git .
fi

# Installer les dépendances npm pour l'utilisateur astminer
sudo -u astminer npm install

# Lancer le miner dans un screen
sudo -u astminer screen -dmS astatine bash -c "npm start"

echo "=== INSTALLATION TERMINEE ==="
echo "Pour suivre les logs du miner : sudo journalctl -u astminer -f"
echo "Pour rejoindre le screen du miner : screen -r astatine"
