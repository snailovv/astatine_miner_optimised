#!/bin/bash
set -e

# ============================================
# Script d'installation et configuration
# pour ast-miner-cli sur Ubuntu Server LTS
# Optimisé Ryzen 9 9950X, 32 Go DDR5
# ============================================

# --- Variables ---
MINER_REPO="https://github.com/Jecta-ai/ast-miner-cli.git"
INSTALL_DIR="$HOME/ast-miner-cli"
ENV_FILE="$HOME/.astminer_env"
SERVICE_FILE="/etc/systemd/system/astminer.service"

# --- Fonction pour vérifier si un paquet est installé ---
function ensure_package {
    if ! dpkg -s "$1" >/dev/null 2>&1; then
        echo "[INFO] Installation de $1..."
        sudo apt-get install -y "$1"
    fi
}

# --- Mise à jour du système ---
echo "[INFO] Mise à jour des paquets..."
sudo apt-get update -y && sudo apt-get upgrade -y

# --- Installation des dépendances de base ---
echo "[INFO] Installation des dépendances de base..."
ensure_package git
ensure_package build-essential
ensure_package curl
ensure_package software-properties-common
ensure_package pkg-config
ensure_package libssl-dev

# --- Installation de Node.js (dernier LTS) ---
if ! command -v node >/dev/null 2>&1; then
    echo "[INFO] Installation de Node.js LTS..."
    curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
    sudo apt-get install -y nodejs
fi

# --- Vérification de npm ---
if ! command -v npm >/dev/null 2>&1; then
    echo "[ERROR] npm non installé, vérifiez Node.js"
    exit 1
fi

# --- Clonage ou mise à jour du repo du miner ---
if [ ! -d "$INSTALL_DIR" ]; then
    echo "[INFO] Clonage du repo du miner..."
    git clone "$MINER_REPO" "$INSTALL_DIR"
else
    echo "[INFO] Mise à jour du repo du miner..."
    cd "$INSTALL_DIR"
    git pull
fi

# --- Installation des dépendances npm ---
echo "[INFO] Installation des dépendances npm..."
cd "$INSTALL_DIR"
npm install

# --- Configuration de la seed phrase ---
if [ ! -f "$ENV_FILE" ]; then
    read -sp "Entrez votre seed phrase AST : " AST_SEED
    echo
    echo "export AST_SEED='$AST_SEED'" > "$ENV_FILE"
    chmod 600 "$ENV_FILE"
    echo "[INFO] Seed phrase enregistrée dans $ENV_FILE"
else
    echo "[INFO] Seed phrase déjà configurée."
fi

# --- Création du service systemd ---
echo "[INFO] Création du service systemd..."
sudo tee "$SERVICE_FILE" >/dev/null <<EOF
[Unit]
Description=AST Miner CLI
After=network.target

[Service]
Type=simple
User=$USER
EnvironmentFile=$ENV_FILE
WorkingDirectory=$INSTALL_DIR
ExecStart=/usr/bin/npm run start
Restart=always
RestartSec=5
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

# --- Reload systemd et démarrage du service ---
echo "[INFO] Activation et démarrage du service..."
sudo systemctl daemon-reload
sudo systemctl enable astminer.service
sudo systemctl start astminer.service

# --- Optimisation CPU ---
echo "[INFO] Optimisation du miner pour Ryzen 9 9950X..."
# Le miner Node.js utilise souvent toutes les threads, on peut set des variables si le miner le supporte
export OMP_NUM_THREADS=32  # Ajuster selon le nombre de threads logiques
echo "export OMP_NUM_THREADS=32" >> "$ENV_FILE"

echo "[INFO] Installation terminée avec succès !"
echo "Vérifiez les logs avec : sudo journalctl -u astminer.service -f"
