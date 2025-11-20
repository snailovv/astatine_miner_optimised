#!/bin/bash
set -e

# Créer le dossier d'installation principal
INSTALL_DIR="/miner/astatine"
mkdir -p $INSTALL_DIR
cd $INSTALL_DIR

# Installer les prérequis
sudo apt update
sudo apt install -y git curl wget build-essential numactl gpg jq screen ca-certificates openssl apt-transport-https gnupg

# Installer Node.js LTS via Nodesource
curl -fsSL https://deb.nodesource.com/setup_24.x | sudo -E bash -
sudo apt install -y nodejs
echo "Node version: $(node -v)"
echo "NPM version: $(npm -v)"

# Cloner le repo officiel dans un sous-dossier
MINER_DIR="$INSTALL_DIR/ast-miner-cli"
if [ -d "$MINER_DIR" ]; then
  echo "Le dossier $MINER_DIR existe déjà. Mise à jour du repo..."
  cd $MINER_DIR
  git pull
else
  git clone https://github.com/Jecta-ai/ast-miner-cli.git $MINER_DIR
  cd $MINER_DIR
fi

# Installer les dépendances npm
npm install

# Lancer le miner dans screen
screen -dmS astminer npm start
echo "Miner lancé dans screen 'astminer'."
echo "Pour rejoindre le screen : screen -r astminer"
echo "Pour suivre les logs : sudo journalctl -u astminer -f"
