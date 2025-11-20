#!/bin/bash
set -e

# ============================================
# AST Miner CLI Installation Complète (Version propre)
# Ubuntu LTS, Ryzen 9 9950X, 32 Go DDR5
# Installation dans ~/miner/astatine
# ============================================

# --- Variables ---
INSTALL_BASE="$HOME/miner"
INSTALL_DIR="$INSTALL_BASE/astatine"
MINER_REPO="https://github.com/Jecta-ai/ast-miner-cli.git"
ENV_FILE="$INSTALL_DIR/.astminer_env"
SERVICE_FILE="$HOME/.config/systemd/user/astminer.service"
USER_NAME="$USER"

# --- Créer le dossier d'installation ---
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

# --- Installer les paquets nécessaires ---
sudo apt-get update -y && sudo apt-get upgrade -y
for pkg in git build-essential curl software-properties-common pkg-config libssl-dev; do
    if ! dpkg -s $pkg >/dev/null 2>&1; then
        echo "[INFO] Installation de $pkg..."
        sudo apt-get install -y $pkg
    fi
done

# --- Installer Node.js LTS si absent ---
if ! command -v node >/dev/null 2>&1; then
    echo "[INFO] Installation de Node.js LTS..."
    curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
    sudo apt-get install -y nodejs
else
    echo "[INFO] Node.js trouvé : $(node -v)"
fi

# --- Cloner ou mettre à jour le repo ---
if [ ! -d "$INSTALL_DIR/.git" ]; then
    echo "[INFO] Clonage du repo AST Miner..."
    git clone "$MINER_REPO" "$INSTALL_DIR"
else
    echo "[INFO] Mise à jour du repo..."
    git fetch --all
    git reset --hard origin/main
fi

# --- Autoriser Git safe directory (pour le user) ---
git config --global --add safe.directory "$INSTALL_DIR"

# --- Installer les dépendances npm ---
npm install

# --- Configuration de la seed phrase ---
if [ ! -f "$ENV_FILE" ]; then
    read -sp "Entrez votre seed phrase AST : " AST_SEED
    echo
    echo "AST_SEED='$AST_SEED'" > "$ENV_FILE"
    chmod 600 "$ENV_FILE"
    echo "[INFO] Seed phrase enregistrée dans $ENV_FILE"
else
    echo "[INFO] Seed phrase déjà configurée."
fi

# --- Détection du script npm à lancer ---
AVAILABLE_SCRIPTS=$(npm run 2>/dev/null)
if echo "$AVAILABLE_SCRIPTS" | grep -q "mine"; then
    NPM_SCRIPT="mine"
elif echo "$AVAILABLE_SCRIPTS" | grep -q "start"; then
    NPM_SCRIPT="start"
else
    echo "[ERROR] Aucun script npm valide ('mine' ou 'start') trouvé. Vérifiez package.json"
    exit 1
fi
echo "[INFO] Script npm choisi : $NPM_SCRIPT"

# --- Création du service systemd utilisateur ---
mkdir -p "$HOME/.config/systemd/user"
tee "$SERVICE_FILE" >/dev/null <<EOF
[Unit]
Description=AST Miner CLI Avancé (User Service)
After=network.target

[Service]
Type=simple
EnvironmentFile=$ENV_FILE
WorkingDirectory=$INSTALL_DIR
ExecStart=/bin/bash -c "git fetch --all && git reset --hard origin/main && npm install && npm run $NPM_SCRIPT"
Restart=always
RestartSec=5
LimitNOFILE=65535
Environment=OMP_NUM_THREADS=32
StartLimitBurst=5
StartLimitIntervalSec=60

[Install]
WantedBy=default.target
EOF

# --- Activation et démarrage du service utilisateur ---
systemctl --user daemon-reload
systemctl --user enable astminer.service
systemctl --user start astminer.service

echo "[INFO] Installation terminée avec succès !"
echo "Pour suivre les logs en temps réel : journalctl --user -u astminer.service -f"
echo "Pour vérifier le statut : systemctl --user status astminer.service"
