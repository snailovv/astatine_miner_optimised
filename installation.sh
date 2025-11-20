#!/bin/bash

# --- Variables ---
INSTALL_DIR="$HOME/miner/astatine"
SERVICE_FILE="$HOME/.config/systemd/user/astminer.service"

# --- Préparation des dossiers ---
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR" || exit

# --- Installer Node.js si besoin ---
if ! command -v node &> /dev/null; then
    echo "Node.js non trouvé. Installation..."
    curl -fsSL https://deb.nodesource.com/setup_24.x | sudo -E bash -
    sudo apt install -y nodejs
fi

# --- Installer dépendances ---
sudo apt update
sudo apt install -y git build-essential screen

# --- Demander la seed une seule fois ---
if [ ! -f "$INSTALL_DIR/.seed" ]; then
    read -sp "Entrez votre seed phrase (elle sera stockée localement, pas sur GitHub) : " USER_SEED
    echo "$USER_SEED" > "$INSTALL_DIR/.seed"
    echo
else
    USER_SEED=$(cat "$INSTALL_DIR/.seed")
fi

# --- Choix du nombre de threads ---
echo "Choisissez le nombre de threads pour le mining :"
echo "1) 24"
echo "2) 28"
echo "3) 32"
read -p "Entrez le chiffre correspondant [1-3]: " THREAD_CHOICE
case $THREAD_CHOICE in
    1) THREADS=24 ;;
    2) THREADS=28 ;;
    3) THREADS=32 ;;
    *) THREADS=24 ;;
esac
echo "Threads sélectionnés : $THREADS"

# --- Cloner ou mettre à jour le miner ---
if [ ! -d "$INSTALL_DIR/ast-cli-miner" ]; then
    git clone https://github.com/Astatine-Project/ast-cli-miner.git
else
    cd ast-cli-miner || exit
    git pull
    cd ..
fi

# --- Créer script de lancement ---
LAUNCH_SCRIPT="$INSTALL_DIR/run_miner.sh"
cat > "$LAUNCH_SCRIPT" <<EOL
#!/bin/bash
cd "$INSTALL_DIR/ast-cli-miner"
while true; do
    ts-node -P tsconfig.miner.json miner.ts --threads $THREADS --seed "$USER_SEED"
    echo "Miner planté, redémarrage dans 10 secondes..."
    sleep 10
done
EOL

chmod +x "$LAUNCH_SCRIPT"

# --- Lancer dans un screen ---
screen -dmS astatine bash "$LAUNCH_SCRIPT"

echo "Installation terminée. Le miner tourne maintenant dans un screen nommé 'astatine'."
echo "Pour y accéder : screen -r astatine"
