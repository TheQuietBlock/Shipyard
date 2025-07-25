# Docker Swarm Services

This repository contains Docker Compose configurations for various self-hosted services, designed to be easily deployed and managed.

## 🗂️ Services Overview

### 📡 AdGuard Home (`adguard/`)
DNS ad blocker and private DNS server that provides network-wide ad and tracker blocking.

**Services:**
- `adguard`: AdGuard Home DNS server with web UI

**Ports:**
- `3000`: Web UI (setup and configuration)
- `53`: DNS server (UDP)
- `80`: HTTP web interface
- `443`: HTTPS web interface  
- `853`: DNS-over-TLS

**Features:**
- Network-wide ad blocking
- DNS filtering and custom rules
- Query logging and statistics
- Parental controls
- Host network mode for easy DNS port binding

### ✈️ Flight Tracking (`fr24feed/`)
ADS-B flight tracking setup with multiple feeders and web interfaces.
With help of https://github.com/sdr-enthusiasts 

**Services:**
- `ultrafeeder`: Multi-purpose ADS-B decoder and feeder with web interface
- `fr24`: FlightRadar24 feeder service
- `piaware`: FlightAware feeder service

**Ports:**
- `8080`: Ultrafeeder web interface (TAR1090 map)
- `8754`: FlightRadar24 status interface

**Features:**
- Real-time aircraft tracking and display
- Multiple flight tracking service integration
- Interactive web-based flight map
- Range and altitude visualization
- MLAT (Multilateration) support
- Requires RTL-SDR dongle for ADS-B reception

**Hardware Requirements:**
- RTL-SDR USB dongle for ADS-B reception
- udev rules included (`60-rtl-sdr.rules`) for proper USB device access

### 🤖 Ansible Automation (`ansible/`)
Ansible playbooks for automated deployment and system setup.

**Available Playbooks:**
- `install-docker.yml`: Automated Docker installation on Ubuntu/Raspberry Pi systems

## 🚀 Quick Start

### Prerequisites
- Docker installed and Swarm mode initialized
- For flight tracking: RTL-SDR dongle and appropriate antenna

> **Tip:** Use the included Ansible playbook to automatically install Docker:
> ```bash
> cd ansible && ansible-playbook -i your_inventory playbooks/install-docker.yml
> ```

### Configuration
Create a `.env` file in the root directory with required environment variables:

**Example `.env` file:**
```bash
# Timezone
TZ=America/New_York

# AdGuard data directories (create these directories first)
CONFIG_DIR=/opt/adguard/conf
WORK_DIR=/opt/adguard/work

# Flight tracking location settings (required for accurate tracking)
FEEDER_TZ=America/New_York
FEEDER_LAT=40.7128
FEEDER_LONG=-74.0060
FEEDER_ALT_M=10
FEEDER_NAME="My ADS-B Station"

# Flight tracking service keys (obtain from respective services)
FR24_SHARING_KEY=your_fr24_sharing_key_here
FLIGHTAWARE_FEEDER_ID=your_flightaware_feeder_id_here

# Optional: HeyWhatsThat integration for range rings
FEEDER_HEYWHATSTHAT_ID=your_heywhatsthat_id
FEEDER_HEYWHATSTHAT_ALTS=12192,24384,36576
```

**Important:** Create the data directories before starting services:
```bash
# Create AdGuard data directories
sudo mkdir -p /opt/adguard/conf /opt/adguard/work
sudo chown -R 1000:1000 /opt/adguard

# Create flight tracking data directories (optional, containers will create them)
sudo mkdir -p /opt/adsb/ultrafeeder/globe_history /opt/adsb/ultrafeeder/graphs1090
```

### Starting Services

#### Deploy All Services
Use the provided script to deploy all Compose files as a Docker Swarm stack:
```bash
./start_all.sh
```

This script will:
- Load environment variables from `.env` if present
- Ensure the `radar-network` overlay network exists
- Find all `docker-compose.yml` files and deploy them with `docker stack deploy`

#### Deploy Individual Services
You can deploy a specific Compose file as its own stack:
```bash
# Example: deploy only the flight tracking services
docker stack deploy -c fr24feed/docker-compose.yml fr24feed
```

## 🔧 Service Management

### AdGuard Home
1. **Initial Setup**: Navigate to `http://your-host:3000` for first-time setup
2. **Web Interface**: Access at `http://your-host` (port 80) after setup
3. **DNS Configuration**: Point your devices to your server's IP address for DNS

### Flight Tracking
1. **Web Interface**: Access the flight map at `http://your-host:8080`
2. **Service Registration**: 
   - Register with FlightRadar24 and FlightAware to obtain sharing keys
   - Configure your location coordinates for accurate tracking
3. **Hardware Setup**: 
   - Connect RTL-SDR dongle
   - Install udev rules: `sudo cp fr24feed/60-rtl-sdr.rules /etc/udev/rules.d/`
   - Reload udev rules: `sudo udevadm control --reload-rules`

## 📂 Directory Structure
```
.
├── adguard/
│   └── docker-compose.yml      # AdGuard Home service
├── fr24feed/
│   ├── docker-compose.yml      # Flight tracking services
│   └── 60-rtl-sdr.rules       # RTL-SDR udev rules
├── ansible/
│   └── playbooks/             # Ansible automation (optional)
├── start_all.sh               # Automated startup script
├── .env                       # Environment configuration (create this)
└── README.md                  # This file
```

## 🔒 Security Considerations
- Review exposed ports and adjust firewall rules as needed
- Use strong passwords and enable authentication where available
- Consider using reverse proxy for HTTPS termination
- Regularly update container images for security patches

## 🛠️ Troubleshooting

### Common Issues
- **Permission Issues**: Ensure Docker daemon is running and user has proper permissions
- **Port Conflicts**: Check that required ports are not in use by other services
- **RTL-SDR Not Detected**: Verify udev rules are installed and USB device permissions
- **Environment Variables**: Ensure `.env` file is properly configured with required values

### Logs
View service logs:
```bash
# View logs for a service in the stack
docker service logs shipyard_ultrafeeder
```

## 📚 Additional Resources
- [AdGuard Home Documentation](https://github.com/AdguardTeam/AdGuardHome)
- [docker-adsb-ultrafeeder Documentation](https://github.com/sdr-enthusiasts/docker-adsb-ultrafeeder)
- [FlightRadar24 Feeder Setup](https://www.flightradar24.com/share-your-data)
- [FlightAware PiAware Documentation](https://flightaware.com/adsb/piaware/)
