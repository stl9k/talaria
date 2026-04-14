# Talaria
Cozy VPS setup for Nginx as a reverse proxy with Element + Matrix chat, X-Ray (3x-ui), telemt

### Setup on clean new VPS

1. Install docker:
curl -fsSL https://get.docker.com | sudo sh

2. Install required packages:
apt install git curl wget vim htop make -y

3. Clone this repository
git clone

### Xray routing rules

After deployment, apply the routing rules manually:

1. Open 3X-UI panel: `https://${DOMAIN}/${XUI_PATH}/`
2. Go to **Xray Configs** -> **Advanced** -> **Routing Rules**
3. Copy contents of `3x-ui/routing.json.template` and paste
4. Save and restart Xray