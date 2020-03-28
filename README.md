# Jitsi Meet

Jitsi in a single docker.

## Quick start

### Setup with NAT

    docker run -d --name jitsi -p 443:443 -p 10000:10000/udp -v /path/to/your/config_dir:/config -e HOSTNAME=meet.example.com flowlee/jitsi

Jitsi will use a self-signed SSL certificate by default.

### Optional setup with NAT and nginx as reverse proxy for LetsEncryt:

Choose port to forward to (example `8443`):

    docker run -d --name jitsi -p 8443:443 -p 5280:5280 -p 10000:10000/udp -v /path/to/your/config_dir:/config -e HOSTNAME=meet.example.com flowlee/jitsi

Example nginx config on docker host:

```
server {
      listen 443;
      listen   [::]:443;
      add_header Strict-Transport-Security "max-age=31536000; includeSubdomains";
      ssl on;
      server_name meet.example.com;    
      ssl_ciphers ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-RSA-AES256-SHA;
      ssl_ecdh_curve secp521r1;
      ssl_prefer_server_ciphers on;
      ssl_protocols TLSv1.2 TLSv1.1 TLSv1;
      ssl_stapling on; 
    
      location / {
        ssi on;
        proxy_pass https://localhost:8443/;
        proxy_set_header X-Forwarded-For $remote_addr;
        proxy_set_header Host $host;
      }
      # BOSH
      location /http-bind {
          proxy_pass      http://localhost:5280/http-bind;
          proxy_set_header X-Forwarded-For $remote_addr;
          proxy_set_header Host $http_host;
      }
      # xmpp websockets
      location /xmpp-websocket {
          proxy_pass http://localhost:5280;
          proxy_http_version 1.1;
          proxy_set_header Upgrade $http_upgrade;
          proxy_set_header Connection "upgrade";
          proxy_set_header Host $host;
          tcp_nodelay on;
      }

    ssl_certificate /path/to/your/cert
    ssl_certificate_key /path/to/your/key

}
```

### Setup without NAT

    docker run -d --name jitsi --net=host -v /path/to/your/config_dir:/config -e HOSTNAME=meet.example.com -e NAT=0 flowlee/jitsi

