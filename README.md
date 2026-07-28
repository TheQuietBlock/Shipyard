# Shipyard

Docker Compose setup for a single Raspberry Pi 5 running an ADS-B flight tracking
station. It feeds FlightRadar24 and FlightAware, and serves a local map and
system graphs.

Built on the excellent images from [sdr-enthusiasts](https://github.com/sdr-enthusiasts).

> No Docker Swarm — this is a plain `docker compose` deployment on one host.

## 🗂️ Services

All services live in a single stack: [flight-tracking/docker-compose.yml](flight-tracking/docker-compose.yml).

| Service | Image | Purpose |
| --- | --- | --- |
| `ultrafeeder` | `sdr-enthusiasts/docker-adsb-ultrafeeder` | ADS-B decoder, aggregator feeder, TAR1090 map, graphs1090 |
| `fr24` | `sdr-enthusiasts/docker-flightradar24` | FlightRadar24 feeder |
| `piaware` | `sdr-enthusiasts/docker-piaware` | FlightAware feeder |
| `portainer` | `portainer/portainer-ee` | Container management UI |
| `watchtower` | `nickfedor/watchtower` | Automatic image updates + cleanup |

### Ports

| Port | Service |
| --- | --- |
| `8080` | Ultrafeeder web interface (TAR1090 map, graphs1090) |
| `8754` | FlightRadar24 feeder status |
| `9000` / `9443` | Portainer UI (HTTP / HTTPS) |
| `8000` | Portainer Edge agent tunnel |

`fr24` and `piaware` both pull their data from `ultrafeeder` over Beast on the
Compose network, so only `ultrafeeder` needs the SDR.

## 🔌 Hardware

- Raspberry Pi 5
- RTL-SDR USB dongle + 1090 MHz antenna

Install the udev rules so the dongle is accessible without root:

```bash
sudo cp flight-tracking/60-rtl-sdr.rules /etc/udev/rules.d/
sudo udevadm control --reload-rules && sudo udevadm trigger
```

## ⚙️ Configuration

Create `flight-tracking/.env` (git-ignored):

```bash
# Location / identity
FEEDER_TZ=Europe/Amsterdam
FEEDER_LAT=52.3676
FEEDER_LONG=4.9041
FEEDER_ALT_M=10
FEEDER_NAME="My ADS-B Station"

# Feeder keys (obtain from the respective services)
FR24_SHARING_KEY=your_fr24_sharing_key_here
FLIGHTAWARE_FEEDER_ID=your_flightaware_feeder_id_here

# Portainer Business Edition license
PORTAINER_LICENSE_KEY=your_portainer_license_key_here

# Optional: HeyWhatsThat range rings
FEEDER_HEYWHATSTHAT_ID=your_heywhatsthat_id
FEEDER_HEYWHATSTHAT_ALTS=12192,24384,36576
```

Get the keys here:
- FlightRadar24 — https://www.flightradar24.com/share-your-data
- FlightAware — https://flightaware.com/adsb/piaware/

## 🚀 Running

```bash
cd flight-tracking
docker compose pull
docker compose up -d
```

Ultrafeeder persists data to `/opt/adsb/ultrafeeder/` on the host. The
containers create these directories on first run; to pre-create them:

```bash
sudo mkdir -p /opt/adsb/ultrafeeder/globe_history /opt/adsb/ultrafeeder/graphs1090
```

Then open the map at `http://<pi-address>:8080`.

## 🤖 Remote setup

[setup_remote.sh](setup_remote.sh) provisions the Pi from scratch: it clones this
repo to `~/git/Shipyard`, installs `~/update_shipyard.sh`, registers a daily
cronjob at 03:00 that pulls and redeploys, and runs the first deployment.

Run it **on the Pi**:

```bash
curl -fsSL https://raw.githubusercontent.com/TheQuietBlock/Shipyard/main/setup_remote.sh | bash
```

The script will not overwrite an existing `flight-tracking/.env` — copy yours
into place before or after the first run.

## 📂 Layout

```
.
├── flight-tracking/
│   ├── docker-compose.yml     # The whole stack
│   ├── 60-rtl-sdr.rules       # RTL-SDR udev rules
│   └── .env                   # Your config (git-ignored, create this)
├── setup_remote.sh            # Pi provisioning + auto-update cronjob
└── README.md
```

## 🛠️ Troubleshooting

```bash
cd flight-tracking
docker compose ps
docker compose logs -f ultrafeeder
docker compose logs -f fr24
docker compose logs -f piaware
```

- **RTL-SDR not detected** — check `lsusb`, confirm the udev rules are installed,
  and make sure no host process (e.g. `dump1090`) is holding the dongle.
- **No aircraft on the map** — verify the antenna connection and that
  `FEEDER_LAT`/`FEEDER_LONG` are set; an unset location breaks MLAT.
- **Empty environment variables** — Compose reads `.env` from the directory you
  run it in, so run `docker compose` from inside `flight-tracking/`.
- **Auto-update log** — `~/update_shipyard.log` on the Pi.

## 🔒 Notes

- Ports are exposed on the LAN only; there is no reverse proxy or TLS in this repo.
- Portainer and Watchtower both mount the Docker socket — anyone reaching those
  has full control of the host's containers. Keep them off the public internet.

## 📚 Resources

- [docker-adsb-ultrafeeder](https://github.com/sdr-enthusiasts/docker-adsb-ultrafeeder)
- [Watchtower](https://containrrr.dev/watchtower/)
