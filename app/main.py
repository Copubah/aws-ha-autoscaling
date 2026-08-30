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
        return "local-development"


@app.get("/", response_class=HTMLResponse)
def root():

    instance_id = get_metadata("instance-id")

    availability_zone = get_metadata(
        "placement/availability-zone"
    )

    hostname = socket.gethostname()

    current_time = datetime.now(
        timezone.utc
    ).strftime("%Y-%m-%d %H:%M:%S UTC")

    return f"""
    <!DOCTYPE html>

    <html>

    <head>

        <title>AWS HA Architecture</title>

        <style>

            body {{
                font-family: Arial, sans-serif;
                background: #111827;
                color: white;
                display: flex;
                align-items: center;
                justify-content: center;
                height: 100vh;
            }}

            .card {{
                background: #1f2937;
                padding: 40px;
                border-radius: 15px;
                width: 500px;
            }}

            h1 {{
                color: #f59e0b;
            }}

            .status {{
                color: #22c55e;
                font-weight: bold;
            }}

            .value {{
                font-family: monospace;
                color: #93c5fd;
            }}

        </style>

    </head>

    <body>

        <div class="card">

            <h1>AWS HA Demo</h1>

            <p>Status:
                <span class="status">
                    Healthy
                </span>
            </p>

            <p>
                Instance ID:
                <span class="value">
                    {instance_id}
                </span>
            </p>

            <p>
                Availability Zone:
                <span class="value">
                    {availability_zone}
                </span>
            </p>

            <p>
                Hostname:
                <span class="value">
                    {hostname}
                </span>
            </p>

            <p>
                Request time:
                <span class="value">
                    {current_time}
                </span>
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
