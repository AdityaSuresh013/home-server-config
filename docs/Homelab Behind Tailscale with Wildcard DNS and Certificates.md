# Secure Remote Access to Your Homelab with Tailscale, Traefik, and Cloudflare

This guide provides step-by-step instructions to securely access your homelab services remotely using Tailscale, Traefik, and Cloudflare. By leveraging these tools, you can ensure that only you have access to specific parts of your homelab.

## Requirements

- **Tailscale Account**: Sign up at [Tailscale](https://tailscale.com).
- **Cloudflare Account**: Sign up at [Cloudflare](https://www.cloudflare.com).
- **Cloudflare Managed Domain**: Ensure you have a registered domain managed by Cloudflare.

## Setting Up Cloudflare API Keys

To enable Traefik to update DNS records on Cloudflare, you'll need to create an API key:

1. Log in to your Cloudflare account and navigate to the [API Tokens](https://dash.cloudflare.com/profile/api-tokens) page.
2. Select **Create Token**.
3. Choose the **Edit zone DNS** template.
4. Ensure the permissions are set to **Zone / DNS / Edit**.
5. Specify the zone resource for your domain.
6. Review the summary, adjust if necessary, and select **Create Token**.
7. **Save the API Key** for later use.

## Creating a Wildcard DNS Record

To differentiate between public and Tailscale-accessible domain names, create a wildcard DNS record:

1. Log in to the Cloudflare dashboard and select your account and domain.
2. Go to **DNS > Records**.
3. Click **Add Record**.
4. Set the record type to **CNAME**.
5. Enter `*.ts` for the **Name**.
6. For the **Target**, use the Magic DNS name of your Tailscale Traefik container (e.g., `traefik.yourtailnet.ts.net`).
7. Set the **Proxy Status** to **DNS Only**.
8. Click **Save**.

## Generating a Tailscale Auth Key

You need an Auth Key for the Tailscale container to access your Tailnet:

1. Go to the **Keys** page in the Tailscale admin console.
2. Select **Generate Auth Key**.
3. Fill out the fields to specify the Auth Key characteristics (description, expiration, etc.).
4. Click **Generate Key**.
5. **Save the Auth Key** for later use.

## Docker Setup

You will create a `docker-compose.yml` file to set up both Tailscale and Traefik containers.

### Create `docker-compose.yml`

```yaml
version: '3.8'

services:
  tailscale-traefik:
    image: tailscale/tailscale
    container_name: tailscale
    hostname: traefik
    environment:
      - TS_AUTHKEY=${TS_AUTHKEY}
      - TS_STATE_DIR=/var/lib/tailscale
      - TS_USERSPACE=false
    volumes:
      - ./tailscale-traefik/state:/var/lib/tailscale
      - /dev/net/tun:/dev/net/tun
    cap_add:
      - net_admin
      - sys_module
    restart: unless-stopped

  traefik:
    image: traefik
    container_name: traefik
    restart: unless-stopped
    security_opt:
      - no-new-privileges:true
    environment:
      - TZ=Europe/Amsterdam # Change this to your timezone
      - CF_API_EMAIL=${CF_API_EMAIL}
      - CF_DNS_API_TOKEN=${CF_DNS_API_TOKEN}
    depends_on:
      - tailscale-traefik
    network_mode: service:tailscale-traefik
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro # Docker socket to watch for Traefik
      - traefik-certs:/certs # Docker volume to store the acme file for the Certificates
    command:
      - --providers.docker=true
      - --providers.docker.exposedByDefault=false
      - --api.dashboard=true
      - --certificatesresolvers.letsencrypt.acme.dnschallenge=true
      - --certificatesresolvers.letsencrypt.acme.dnschallenge.provider=cloudflare
      - --certificatesresolvers.letsencrypt.acme.email=${LE_EMAIL}
      - --certificatesresolvers.letsencrypt.acme.storage=/certs/acme.json
      - --entrypoints.web.address=:80
      - --entrypoints.web.http.redirections.entrypoint.to=websecure
      - --entrypoints.web.http.redirections.entrypoint.scheme=https
      - --entrypoints.websecure.address=:443
      - --entrypoints.websecure.http.tls=true
      - --entrypoints.websecure.http.tls.certResolver=letsencrypt
      - --entrypoints.websecure.http.tls.domains[0].main=${DOMAIN}
      - --entrypoints.websecure.http.tls.domains[0].sans=${SANS_DOMAIN}
    labels:
      - "traefik.enable=true"
      - 'traefik.http.routers.traefik.rule=Host(`traefik.ts.example.com`)'
      - "traefik.http.routers.traefik.entrypoints=websecure"
      - "traefik.http.routers.traefik.tls.certresolver=letsencrypt"
      - "traefik.http.routers.traefik.service=api@internal"
      - "traefik.http.services.traefik.loadbalancer.server.port=8080"

volumes:
  traefik-certs:
    name: traefik-certs
```

> **Note:** Replace `traefik.ts.example.com` with your actual domain name.

### Create the Environment Variables File

Create a `.env` file in the same directory as your `docker-compose.yml`:

```bash
nano .env
```

Add the following content, replacing the placeholders with your actual values:

```plaintext
CF_API_EMAIL=<Cloudflare email>
CF_DNS_API_TOKEN=<Cloudflare API Token>
TS_AUTHKEY=<Tailscale Auth Key>
LE_EMAIL=<Your email for LetsEncrypt>
DOMAIN=ts.example.com
SANS_DOMAIN=*.ts.example.com
```

## Starting the Containers

To start the containers, run the following command:

```bash
docker compose up -d
```

## Accessing Traefik Dashboard

If everything is configured correctly, both containers should be running within a few minutes. Depending on your configuration, you might need to approve the `tailscale-traefik` device in the Tailscale Admin Console.

Once connected to your Tailnet, you can access the Traefik dashboard at `traefik.ts.example.com`. It will use the wildcard certificate for `ts.example.com`.

## Adding Services

You can now add any services to Traefik with the `*.ts.example.com` domain name. These services will be accessible only through your Tailnet, ensuring privacy and security.

## Conclusion

You have successfully set up a secure and private access system for your homelab services using Tailscale, Traefik, and Cloudflare. This configuration helps keep your services safe from public exposure while allowing easy access for you. Enjoy managing your homelab securely!