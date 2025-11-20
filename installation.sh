#!/bin/bash
set -e

# ------------------------------
# Variables à adapter si besoin
# ------------------------------
INSTALL_DIR="$HOME/miner/astatine"
SCREEN_NAME="astatine"
THREADS=24

# ------------------------------
# Création du dossier d'installation
# ------------------------------
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

# ------------------------------
# Installer Node.js si nécessaire
# ------------------------------
if ! command -v node >/dev/null 2>&1; then
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt install -y nodejs
fi

# ------------------------------
# Installer dépendances système
# ------------------------------
sudo apt update
sudo apt install -y build-essential screen git

# ------------------------------
# Clone ou met à jour le repo officiel
# ------------------------------
if [ ! -d "$INSTALL_DIR/.git" ]; then
    git clone https://github.com/astatinework/astatine-cli.git "$INSTALL_DIR"
else
    git pull
fi

# ------------------------------
# Installer dépendances Node.js
# ------------------------------
npm install

# ------------------------------
# Demande la seed une seule fois
# ------------------------------
if [ ! -f "$INSTALL_DIR/.seed" ]; then
    read -sp "Entrez votre seed phrase: " USER_SEED
    echo "$USER_SEED" > "$INSTALL_DIR/.seed"
    echo ""
fi

# ------------------------------
# Création du script de lancement
# ------------------------------
cat > "$INSTALL_DIR/run_miner.sh" <<EOL
#!/bin/bash
cd "$INSTALL_DIR"
while true; do
    ts-node -P tsconfig.miner.json miner.ts --threads $THREADS --seed \$(cat .seed)
    echo "Miner crashed! Restarting in 10 seconds..."
    sleep 10
done
EOL

chmod +x "$INSTALL_DIR/run_miner.sh"

# ------------------------------
# Lancer le miner dans un screen
# ------------------------------
screen -dmS $SCREEN_NAME "$INSTALL_DIR/run_miner.sh"

echo "Installation terminée. Le miner tourne dans le screen '$SCREEN_NAME'."
echo "Pour rejoindre le screen: screen -r $SCREEN_NAME"
