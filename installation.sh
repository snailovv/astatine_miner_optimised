#!/bin/bash
set -e

INSTALL_DIR="/miner/astatine"
MINER_REPO="https://github.com/Jecta-ai/ast-miner-cli.git"
ENV_FILE="$INSTALL_DIR/.astminer_env"
SERVICE_FILE="$HOME/.config/systemd/user/astminer.service"
USER_NAME="$USER"

# --- Créer le dossier ---
sudo mkdir -p "$INSTALL_DIR"
sudo chown $USER_NAME:$USER_NAME "$INSTALL_DIR"
cd "$INSTALL_DIR"

# --- Installer paquets nécessaires ---
sudo apt-get update -y && sudo apt-get upgrade -y
for pkg in git build-essential curl software-properties-common pkg-config libssl-dev; do
    if ! dpkg -s $pkg >/dev/null 2>&1; then
        sudo apt-get install -y $pkg
    fi
done

# --- Installer Node.js LTS si absent ---
if ! command -v node >/dev/null 2>&1; then
    curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
    sudo apt-get install -y nodejs
fi

# --- Cloner ou mettre à jour le repo ---
if [ ! -d "$INSTALL_DIR/.git" ]; then
    git clone "$MINER_REPO" "$INSTALL_DIR"
else
    git fetch --all
    git reset --hard origin/main
fi

# --- Git safe directory ---
git config --global --add safe.directory "$INSTALL_DIR"

# --- Installer dépendances npm ---
npm install

# --- Seed phrase (interactive une seule fois) ---
if [ ! -f "$ENV_FILE" ]; then
    read -sp "Entrez votre seed phrase AST : " AST_SEED
    echo
    echo "AST_SEED='$AST_SEED'" > "$ENV_FILE"
    chmod 600 "$ENV_FILE"
    echo "[INFO] Seed phrase enregistrée dans $ENV_FILE"
fi

# --- Détecter script npm ---
AVAILABLE_SCRIPTS=$(npm run 2>/dev/null)
if echo "$AVAILABLE_SCRIPTS" | grep -q "mine"; then
    NPM_SCRIPT="mine"
elif echo "$AVAILABLE_SCRIPTS" | grep -q "start"; then
    NPM_SCRIPT="start"
else
    echo "[ERROR] Aucun script npm valide trouvé"
    exit 1
fi

# --- Service systemd utilisateur ---
mkdir -p "$HOME/.config/systemd/user"
tee "$SERVICE_FILE" >/dev/null <<EOF
[Unit]
Description=AST Miner CLI Avancé (User Service)
After=network.target

[Service]
Type=simple
EnvironmentFile=$ENV_FILE
WorkingDirectory=$INSTALL_DIR
ExecStart=/bin/bash -c "npm install && npm run $NPM_SCRIPT"
Restart=always
RestartSec=5
LimitNOFILE=65535
Environment=OMP_NUM_THREADS=32

[Install]
WantedBy=default.target
EOF

# --- Activer et démarrer ---
systemctl --user daemon-reload
systemctl --user enable astminer.service
systemctl --user start astminer.service

echo "[INFO] Installation terminée !"
echo "Logs : journalctl --user -u astminer.service -f"
