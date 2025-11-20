#!/bin/bash
set -e

echo "=== AST Miner Installation - Début ==="

# Mettre à jour le système et installer dépendances
sudo apt update && sudo apt install -y git curl wget build-essential numactl gpg jq screen ca-certificates openssl linux-tools-common linux-tools-$(uname -r)

# Installer NVM (dernière version stable)
export NVM_DIR="$HOME/.nvm"
if [ ! -d "$NVM_DIR" ]; then
    echo "Installation de la dernière version stable de NVM..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash
fi
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Installer la dernière LTS de Node.js via NVM
echo "Installation de la dernière LTS de Node.js..."
nvm install --lts
nvm use --lts
nvm alias default 'lts/*'
npm install -g npm

echo "Node $(node -v) | npm $(npm -v) installé"

# Créer l'utilisateur et dossier du miner
sudo useradd -m -s /bin/bash astminer || true
sudo mkdir -p /opt/ast-miner-cli
sudo chown -R astminer:astminer /opt/ast-miner-cli

# Cloner ou mettre à jour le repo du miner
if [ -d "/opt/ast-miner-cli/.git" ]; then
    echo "Mise à jour du repo existant..."
    sudo -u astminer git -C /opt/ast-miner-cli pull
else
    echo "Clonage du repo du miner..."
    sudo -u astminer git clone https://github.com/snailovv/astatine_miner_optimised.git /opt/ast-miner-cli
fi

# Installer les dépendances npm
sudo -u astminer bash -c "cd /opt/ast-miner-cli && npm install"

# Créer le dossier de configuration et seed
sudo mkdir -p /etc/astminer
sudo chown -R astminer:astminer /etc/astminer

# Demander la seed (une seule fois)
echo "=== ONE-TIME: Entrer seed phrase ==="
sudo -u astminer bash -c "read -s -p 'Entrez votre seed phrase : ' SEED; echo; echo \$SEED | gpg --symmetric --cipher-algo AES256 -o /etc/astminer/seed.gpg"

echo "Seed chiffrée et stockée dans /etc/astminer/seed.gpg"

# Créer un script de lancement du miner
cat << 'EOF' | sudo tee /usr/local/bin/astminer-run.sh
#!/bin/bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
cd /opt/ast-miner-cli
screen -dmS astatine sudo -u astminer node miner.js
EOF

sudo chmod +x /usr/local/bin/astminer-run.sh

# Créer le service systemd
cat << 'EOF' | sudo tee /etc/systemd/system/astminer.service
[Unit]
Description=AST Astatine Miner
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/astminer-run.sh
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable astminer
sudo systemctl start astminer

echo "=== INSTALLATION COMPLETE ==="
echo "Vérifier logs : sudo journalctl -u astminer -f"
echo "Rejoindre le screen du miner : screen -r astatine"
