#!/bin/bash
set -e

# ===============================
# Installation AST Miner CLI optimisé
# ===============================

INSTALL_DIR="/miner/astatine"
MINER_CLI_URL="https://www.astatine.work/cli"  # site officiel
SCREEN_NAME="astatine"
THREADS=24

# --- Créer le dossier ---
sudo mkdir -p "$INSTALL_DIR"
sudo chown $USER:$USER "$INSTALL_DIR"
cd "$INSTALL_DIR"

# --- Installer dépendances si manquantes ---
sudo apt update && sudo apt install -y curl git build-essential screen

# --- Installer Node.js LTS si absent ---
if ! command -v node >/dev/null; then
    curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
    sudo apt install -y nodejs
fi

# --- Télécharger et installer le miner officiel ---
curl -fsSL "$MINER_CLI_URL" -o install.sh
bash install.sh

# --- Seed phrase (interactive une seule fois) ---
ENV_FILE="$INSTALL_DIR/.astminer_env"
if [ ! -f "$ENV_FILE" ]; then
    read -sp "Entrez votre seed phrase AST : " AST_SEED
    echo
    echo "export AST_SEED='$AST_SEED'" > "$ENV_FILE"
    chmod 600 "$ENV_FILE"
fi
source "$ENV_FILE"

# --- Lancer le miner dans screen avec auto-restart ---
screen -S "$SCREEN_NAME" -dm bash -c "
while true; do
    export AST_SEED='$AST_SEED'
    export OMP_NUM_THREADS=$THREADS
    npm run mine
    echo 'Miner crashed ou stoppé. Redémarrage dans 10 secondes...'
    sleep 10
done
"

echo "Installation terminée !"
echo "Le miner tourne dans un screen nommé '$SCREEN_NAME'."
echo "Pour accéder au screen : screen -r $SCREEN_NAME"
