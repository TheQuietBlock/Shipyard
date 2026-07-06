#!/bin/bash
set -e

echo "Ensuring ~/git directory exists..."
mkdir -p ~/git

# Move .env if it exists in old Shipyard
if [ -f ~/Shipyard/.env ]; then
    echo "Backing up old .env..."
    cp ~/Shipyard/.env ~/.env.backup
fi

echo "Cleaning up old Shipyard deployment..."
if [ -d ~/Shipyard ]; then
    cd ~/Shipyard
    if [ -f start_all.sh ]; then
        # Take down the old stack if it's there
        docker stack rm shipyard || true
    fi
    # Also stop containers just in case
    docker ps -a | grep -E 'ultrafeeder|piaware|fr24|watchtower' | awk '{print $1}' | xargs -r docker stop || true
    docker ps -a | grep -E 'ultrafeeder|piaware|fr24|watchtower' | awk '{print $1}' | xargs -r docker rm || true
    
    cd ~
    echo "Removing old ~/Shipyard directory..."
    rm -rf ~/Shipyard
fi

echo "Setting up new repository in ~/git/Shipyard..."
cd ~/git
if [ ! -d Shipyard ]; then
    git clone git@github.com:TheQuietBlock/Shipyard.git
else
    cd Shipyard
    git pull
fi

echo "Restoring .env to flight-tracking..."
if [ -f ~/.env.backup ]; then
    cp ~/.env.backup ~/git/Shipyard/flight-tracking/.env
    echo ".env restored."
fi

echo "Creating daily update script..."
cat << 'EOF' > ~/update_shipyard.sh
#!/bin/bash
set -e
cd /home/patrick/git/Shipyard
git pull
cd flight-tracking
docker compose pull
docker compose up -d --remove-orphans
docker system prune -f
EOF

chmod +x ~/update_shipyard.sh

echo "Setting up cronjob for daily update..."
# Remove any existing update_shipyard cronjob
(crontab -l 2>/dev/null | grep -v 'update_shipyard.sh' || true) | crontab -
# Add the new cronjob (run daily at 3 AM)
(crontab -l 2>/dev/null; echo "0 3 * * * /home/patrick/update_shipyard.sh >> /home/patrick/update_shipyard.log 2>&1") | crontab -

echo "Running initial update/deployment..."
~/update_shipyard.sh

echo "Done!"
