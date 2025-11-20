#!/bin/bash
set -e

# ==============================
# AST Miner Installation Optimisée - Multi-rig
# ==============================

echo "=== AST Miner Installation - Début ==="

# 1️⃣ Installer les dépendances système
sudo apt update
sudo apt install -y git curl wget build-essential numactl gpg jq screen ca-certificates openssl linux-tools-common linux-tools-$(uname -r)

# 2️⃣ Installer ou mettre à jour NVM
export NVM_DIR="$HOME/.nvm"
if [ ! -d "$NVM_DIR" ]; then
  echo "Installation de NVM..."
  wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.9/install.sh | bash
else
  echo "Mise à jour de NVM..."
  cd "$NVM_DIR"
  git fetch origin
  git checkout v0.39.9
fi

# Charger NVM
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# 3️⃣ Installer ou mettre à jour Node.js LTS (v24) et npm
echo "Installation de Node.js LTS..."
nvm install --lts --reinstall-packages-from=default
nvm use --lts
nvm alias default lts/*
echo "Node $(node -v) | npm $(npm -v) installé"

# 4️⃣ Cloner ou mettre à jour le repo AST Miner
if [ ! -d "/opt/ast-miner-cli" ]; then
  sudo git clone https://github.com/snailovv/astatine_miner_optimised.git /opt/ast-miner-cli
else
  echo "Mise à jour du repo existant..."
  cd /opt/ast-miner-cli
  sudo git reset --hard
  sudo git pull
fi
cd /opt/ast-miner-cli

# 5️⃣ Installer les packages npm (sans sudo)
npm install

# 6️⃣ Créer l'utilisateur astminer et dossier seed si nécessaire
if ! id "astminer" &>/dev/null; then
  sudo useradd -m -s /bin/bash astminer
fi
sudo mkdir -p /etc/astminer
sudo chown $USER:$USER /etc/astminer

# 7️⃣ Saisie et chiffrement de la seed
if [ ! -f /etc/astminer/seed.gpg ]; then
  echo "=== ONE-TIME: Entrer votre seed phrase ==="
  read -s -p "Entrez votre seed phrase: " SEED
  echo
  echo "$SEED" | gpg --symmetric --cipher-algo AES256 -o /etc/astminer/seed.gpg
  echo "Seed chiffrée et stockée dans /etc/astminer/seed.gpg"
fi

# 8️⃣ Création du script de lancement dans screen avec optimisation Ryzen
sudo tee /usr/local/bin/astminer-run.sh >/dev/null <<'EOF'
#!/bin/bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
cd /opt/ast-miner-cli
# Lancer le miner dans screen avec optimisation CPU Ryzen 9950X
screen -dmS astatine numactl --interleave=all npm start
EOF
sudo chmod +x /usr/local/bin/astminer-run.sh

# 9️⃣ Lancer le miner
/usr/local/bin/astminer-run.sh

echo "=== INSTALLATION COMPLETE ==="
echo "Le miner tourne dans screen nommé 'astatine'."
echo "Pour rejoindre le screen: screen -r astatine"
