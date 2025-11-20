#!/bin/bash
set -e

INSTALL_DIR="/miner/astatine"
MINER_DIR="$INSTALL_DIR/ast-miner-cli"

# Créer le dossier principal
mkdir -p $INSTALL_DIR
cd $INSTALL_DIR

# Installer les prérequis
sudo apt update
sudo apt install -y git curl wget build-essential numactl gpg jq screen ca-certificates openssl apt-transport-https gnupg

# Installer Node.js LTS
curl -fsSL https://deb.nodesource.com/setup_24.x | sudo -E bash -
sudo apt install -y nodejs
echo "Node version: $(node -v)"
echo "NPM version: $(npm -v)"

# Cloner ou mettre à jour le dépôt officiel
if [ -d "$MINER_DIR" ]; then
    echo "Mise à jour du repo existant..."
    cd $MINER_DIR
    git pull
else
    echo "Clonage du dépôt officiel dans $MINER_DIR..."
    git clone https://github.com/Jecta-ai/ast-miner-cli.git $MINER_DIR
    cd $MINER_DIR
fi

# Installer les dépendances npm
npm install

# Lancer le miner dans un screen interactif pour saisir la passphrase
echo "Lancement du miner dans screen interactif nommé 'astminer'..."
screen -S astminer -dm bash -c "cd $MINER_DIR && npm start"

echo "=== INSTALLATION TERMINEE ==="
echo "Pour rejoindre le screen et saisir la passphrase :"
echo "  screen -r astminer"
echo "Pour détacher sans arrêter le miner : Ctrl+A puis D"
echo "Pour suivre les logs : sudo journalctl -u astminer -f"
