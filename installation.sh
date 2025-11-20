#!/usr/bin/env bash

set -e

# --- Configuration ---
INSTALL_DIR="$HOME/miner/astatine"
SERVICE_NAME="astminer"
SCREEN_NAME="astatine"

# --- Créer le dossier d'installation ---
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

# --- Installer les dépendances de base ---
echo "Installation des dépendances..."
sudo apt update
sudo apt install -y curl git build-essential screen nodejs npm

# --- Node.js >=18 check ---
NODE_VER=$(node -v | grep -oP '\d+')
if [ "$NODE_VER" -lt 18 ]; then
    echo "Node.js >=18 requis, installation..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt install -y nodejs
fi

# --- Sélection du nombre de threads ---
if [ ! -f "$INSTALL_DIR/thread_count.txt" ]; then
    echo "Sélectionnez le nombre de threads pour le miner :"
    select THREADS in 24 28 32; do
        if [[ -n "$THREADS" ]]; then
            echo "$THREADS" > "$INSTALL_DIR/thread_count.txt"
            break
        fi
    done
fi
THREADS=$(cat "$INSTALL_DIR/thread_count.txt")

# --- Seed --- 
if [ ! -f "$INSTALL_DIR/seed.txt" ]; then
    read -sp "Entrez votre seed phrase: " USER_SEED
    echo "$USER_SEED" > "$INSTALL_DIR/seed.txt"
    echo
fi

# --- Télécharger le miner CLI directement depuis Astatine ---
echo "Téléchargement du miner..."
curl -fsSL https://raw.githubusercontent.com/astminer/cli/main/miner.ts -o miner.ts
curl -fsSL https://raw.githubusercontent.com/astminer/cli/main/tsconfig.miner.json -o tsconfig.miner.json
npm install ts-node

# --- Créer script de lancement ---
cat > "$INSTALL_DIR/run_miner.sh" <<EOL
#!/usr/bin/env bash
cd "$INSTALL_DIR"
while true; do
    ts-node -P tsconfig.miner.json miner.ts --threads $THREADS --seed "\$(cat seed.txt)"
    echo "Le miner a planté. Redémarrage dans 10 secondes..."
    sleep 10
done
EOL

chmod +x "$INSTALL_DIR/run_miner.sh"

# --- Lancer dans screen ---
echo "Démarrage du miner dans screen '$SCREEN_NAME'..."
screen -dmS "$SCREEN_NAME" bash "$INSTALL_DIR/run_miner.sh"

echo "Installation terminée. Pour rejoindre le screen : screen -r $SCREEN_NAME"
