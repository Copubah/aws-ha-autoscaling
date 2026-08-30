#!/bin/bash

set -e

dnf update -y

dnf install -y python3 python3-pip git

mkdir -p /opt/ha-app

cat > /opt/ha-app/main.py <<'EOF'
from fastapi import FastAPI
from fastapi.responses import HTMLResponse
import socket
import urllib.request
from datetime import datetime, timezone

app = FastAPI()


def get_metadata(path):

    try:

        token_request = urllib.request.Request(
            "http://169.254.169.254/latest/api/token",
            method="PUT",
            headers={
                "X-aws-ec2-metadata-token-ttl-seconds": "21600"
            },
        )

        token = urllib.request.urlopen(
            token_request,
            timeout=1
        ).read().decode()

        request = urllib.request.Request(
            f"http://169.254.169.254/latest/meta-data/{path}",
            headers={
                "X-aws-ec2-metadata-token": token
            },
        )

        return urllib.request.urlopen(
            request,
            timeout=1
        ).read().decode()

    except Exception:

        return "unknown"


@app.get("/", response_class=HTMLResponse)
def root():

    instance_id = get_metadata("instance-id")

    availability_zone = get_metadata(
        "placement/availability-zone"
    )

    hostname = socket.gethostname()

    now = datetime.now(
        timezone.utc
    ).strftime("%Y-%m-%d %H:%M:%S UTC")

    return f"""
    <html>

    <head>

        <title>AWS HA Demo</title>

        <style>

            body {{
                font-family: Arial;
                background: #111827;
                color: white;
                display: flex;
                justify-content: center;
                align-items: center;
                height: 100vh;
            }}

            .card {{
                background: #1f2937;
                padding: 40px;
                border-radius: 15px;
                width: 520px;
            }}

            h1 {{
                color: #f59e0b;
            }}

            .status {{
                color: #22c55e;
            }}

            code {{
                color: #93c5fd;
            }}

        </style>

    </head>

    <body>

        <div class="card">

            <h1>AWS High Availability Demo</h1>

            <p>
                Status:
                <strong class="status">
                    Healthy
                </strong>
            </p>

            <p>
                Instance:
                <code>{instance_id}</code>
            </p>

            <p>
                Availability Zone:
                <code>{availability_zone}</code>
            </p>

            <p>
                Hostname:
                <code>{hostname}</code>
            </p>

            <p>
                Request time:
                <code>{now}</code>
            </p>

        </div>

    </body>

    </html>
    """


@app.get("/health")
def health():

    return {
        "status": "healthy"
    }
EOF

pip3 install fastapi uvicorn

cat > /etc/systemd/system/ha-app.service <<'EOF'

[Unit]
Description=AWS HA FastAPI Application
After=network.target

[Service]
User=root
WorkingDirectory=/opt/ha-app

ExecStart=/usr/local/bin/uvicorn main:app \
--host 0.0.0.0 \
--port 8000

Restart=always

[Install]
WantedBy=multi-user.target

EOF

systemctl daemon-reload

systemctl enable ha-app

systemctl start ha-app
