#!/bin/bash
set -e

# ============================================
# Script d'installation complète AST Miner CLI
# Ubuntu LTS, Ryzen 9 9950X, 32 Go DDR5
# Installation dans /miner/astatine
# ============================================

# --- Variables ---
INSTALL_BASE="/miner"
INSTALL_DIR="$INSTALL_BASE/astatine"
MINER_REPO="https://github.com/Jecta-ai/ast-miner-cli.git"
ENV_FILE="$INSTALL_DIR/.astminer_env"
SERVICE_FILE="/etc/systemd/system/astminer.service"
USER_NAME="s_nailo_vv"  # ton utilisateur normal

# --- Créer le dossier d'installation ---
sudo mkdir -p "$INSTALL_DIR"
sudo chown $USER_NAME:$USER_NAME "$INSTALL_DIR"
cd "$INSTALL_DIR"

# --- Fonction pour installer un paquet si nécessaire ---
function ensure_package {
    if ! dpkg -s "$1" >/dev/null 2>&1; then
        echo "[INFO] Installation de $1..."
        sudo apt-get install -y "$1"
    fi
}

# --- Mise à jour système et dépendances ---
sudo apt-get update -y && sudo apt-get upgrade -y
ensure_package git
ensure_package build-essential
ensure_package curl
ensure_package software-properties-common
ensure_package pkg-config
ensure_package libssl-dev

# --- Installation ou mise à jour Node.js LTS ---
NODE_VERSION=$(node -v 2>/dev/null || echo "")
if [[ "$NODE_VERSION" == "" ]]; then
    echo "[INFO] Node.js non installé. Installation LTS..."
    curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
    sudo apt-get install -y nodejs
else
    echo "[INFO] Node.js installé : $NODE_VERSION"
fi

# --- Clonage ou mise à jour du repo miner ---
if [ ! -d "$INSTALL_DIR/.git" ]; then
    echo "[INFO] Clonage du repo du miner..."
    git clone "$MINER_REPO" "$INSTALL_DIR"
else
    echo "[INFO] Mise à jour du repo du miner..."
    git fetch --all
    git reset --hard origin/main
fi

# --- Installation dépendances npm ---
npm install

# --- Configuration de la seed phrase (systemd friendly) ---
if [ ! -f "$ENV_FILE" ]; then
    read -sp "Entrez votre seed phrase AST : " AST_SEED
    echo
    echo "AST_SEED='$AST_SEED'" > "$ENV_FILE"
    chmod 600 "$ENV_FILE"
    echo "[INFO] Seed phrase enregistrée dans $ENV_FILE"
else
    echo "[INFO] Seed phrase déjà configurée."
fi

# --- Création du service systemd corrigé ---
sudo tee "$SERVICE_FILE" >/dev/null <<EOF
[Unit]
Description=AST Miner CLI Avancé
After=network.target

[Service]
Type=simple
User=$USER_NAME
EnvironmentFile=$ENV_FILE
WorkingDirectory=$INSTALL_DIR
ExecStart=/bin/bash -c "git fetch --all && git reset --hard origin/main && npm install && npm run mine"
Restart=always
RestartSec=5
LimitNOFILE=65535
Environment=OMP_NUM_THREADS=32
StartLimitBurst=5
StartLimitIntervalSec=60

[Install]
WantedBy=multi-user.target
EOF

# --- Activation et démarrage du service ---
sudo systemctl daemon-reload
sudo systemctl enable astminer.service
sudo systemctl start astminer.service

echo "[INFO] Installation terminée avec succès !"
echo "Logs en temps réel : sudo journalctl -u astminer.service -f"
