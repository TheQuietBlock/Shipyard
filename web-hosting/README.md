# Web Hosting on Shipyard

This repository contains the configuration needed to run static websites in Docker containers, securely tunneled through Cloudflare.

## Architecture
- Two `nginx` containers serve static website content.
- One `cloudflared` container creates a secure tunnel to Cloudflare.
- The websites are loaded from `/var/www/site1.example.com` and `/var/www/site2.example.com` on the host machine.

## Prerequisites
1. Docker and Docker Compose must be installed on the host.
2. The host must have `/var/www/site1.example.com` and `/var/www/site2.example.com` directories created, containing the website files (e.g., via `git clone`).
3. You must set up your Cloudflare tunnel and copy the `config.yml` and credentials JSON file to the `cloudflared/` directory.

## Deployment Instructions

1. Copy `.env.example` to `.env` and fill in your Tunnel UUID:
   ```bash
   cp .env.example .env
   ```

2. (First-time setup only) Clone your websites into the appropriate host directories:
   ```bash
   sudo mkdir -p /var/www/site1.example.com
   sudo chown -R $USER:$USER /var/www/site1.example.com
   cd /var/www/site1.example.com
   git clone git@github.com:YourUsername/your-repo.git .
   ```

3. Spin up the containers in detached mode:
   ```bash
   docker compose up -d
   ```

4. To automate updates, set up a cronjob to pull the latest code on a schedule:
   ```bash
   crontab -e
   # Example: Pull updates every Sunday at midnight
   0 0 * * 0 cd /var/www/site1.example.com && git pull origin main > /dev/null 2>&1
   ```
