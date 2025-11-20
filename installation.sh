#!/bin/bash

# ===============================
# Installation Astatine Miner Optimisé
# ===============================

set -e

# --- Vérification de Node.js ---
if ! command -v node >/dev/null 2>&1; then
    echo "Node.js non trouvé. Installation..."
    curl -fsSL https://deb.nodesource.com/setup_24.x | sudo -E bash -
    sudo apt-get install -y nodejs build-essential git screen
else
    echo "Node.js déjà installé."
fi

# --- Demande du nombre de threads ---
echo "Choisir le nombre de threads (24, 28 ou 32) : "
read -r THREADS
if [[ ! "$THREADS" =~ ^(24|28|32)$ ]]; then
    echo "Nombre invalide, utilisation par défaut : 24 threads"
    THREADS=24
fi

# --- Demande de la seed (une seule fois) ---
if [ ! -f seed.txt ]; then
    echo "Entrez votre 12-word seed : "
    read -r SEED
    echo "$SEED" > seed.txt
    chmod 600 seed.txt
fi

# --- Clonage ou mise à jour du miner ---
if [ ! -d ast-cli-miner ]; then
    git clone https://github.com/astminer/ast-cli-miner.git
fi
cd ast-cli-miner
git pull || true

# --- Installation des dépendances npm ---
npm install

# --- Création du script de démarrage optimisé ---
cat > start_miner.sh <<EOL
#!/bin/bash
cd ~/miner/astatine/ast-cli-miner
export AST_SEED=\$(cat ~/miner/astatine/seed.txt)
screen -dmS astatine bash -c "ts-node -P tsconfig.miner.json miner.ts --threads $THREADS"
EOL

chmod +x start_miner.sh

# --- Création du service systemd pour restart automatique ---
cat > ~/.config/systemd/user/astminer.service <<EOL
[Unit]
Description=Astatine Miner Optimisé
After=network.target

[Service]
Type=simple
ExecStart=$HOME/miner/astatine/start_miner.sh
Restart=always
RestartSec=10

[Install]
WantedBy=default.target
EOL

# --- Reload et enable du service ---
systemctl --user daemon-reload
systemctl --user enable astminer.service
systemctl --user start astminer.service

echo "Installation terminée ! Le miner tourne dans un screen nommé 'astatine'."
