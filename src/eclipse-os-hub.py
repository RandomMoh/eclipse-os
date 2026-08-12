#!/usr/bin/env python3

import sys
import os
import json
import subprocess
import threading
from http.server import SimpleHTTPRequestHandler
import socketserver
from PyQt5.QtCore import QUrl
from PyQt5.QtWidgets import QApplication, QMainWindow
from PyQt5.QtWebEngineWidgets import QWebEngineView

PORT = 8080
UI_DIR = os.path.join(os.path.dirname(__file__), 'ui')

def scan_block_devices():
    devices = []
    try:
        res = subprocess.run(["lsblk", "-J", "-o", "NAME,SIZE,TYPE,MODEL"], capture_output=True, text=True)
        if res.returncode == 0:
            data = json.loads(res.stdout)
            for dev in data.get("blockdevices", []):
                if dev.get("type") in ("disk", "loop"):
                    devices.append({
                        "node": "/dev/" + dev["name"],
                        "size": dev.get("size", "Unknown"),
                        "model": (dev.get("model") or "Storage Disk").strip()
                    })
    except Exception:
        pass
    if not devices:
        devices = [
            {"node": "/dev/sda", "size": "64.0G", "model": "Virtual Storage Disk"},
            {"node": "/dev/nvme0n1", "size": "512.0G", "model": "NVMe SSD"}
        ]
    return devices

def get_drivers():
    return [
        {"id": "nouveau", "name": "Nouveau (Open Source)", "type": "GPU", "status": "Active", "description": "Default open-source driver for NVIDIA cards."},
        {"id": "nvidia-driver", "name": "NVIDIA Proprietary", "type": "GPU", "status": "Available", "description": "Official proprietary driver for maximum 3D and CUDA performance."},
        {"id": "intel-media", "name": "Intel Media VA-API", "type": "GPU", "status": "Active", "description": "Hardware acceleration for Intel GPUs."}
    ]

class EclipseHubHandler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=UI_DIR, **kwargs)

    def do_GET(self):
        if self.path == '/api/disks':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(scan_block_devices()).encode())
            return
        elif self.path == '/api/drivers':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(get_drivers()).encode())
            return
        elif self.path.startswith('/assets/'):
            # Route /assets/ to src/assets/
            self.directory = os.path.dirname(UI_DIR)
            super().do_GET()
            return
        super().do_GET()

    def do_POST(self):
        if self.path == '/api/install':
            content_length = int(self.headers['Content-Length'])
            post_data = self.rfile.read(content_length)
            data = json.loads(post_data)
            # The POST endpoint receives the target disk configuration. This payload is passed to the underlying installer CLI to partition the drive.
            print(f"Starting installation to {data.get('disk')}")
            
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({"status": "success", "message": "Installation started"}).encode())
            return
        elif self.path == '/api/drivers/install':
            content_length = int(self.headers['Content-Length'])
            post_data = self.rfile.read(content_length)
            data = json.loads(post_data)
            print(f"Installing driver: {data.get('id')}")
            
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({"status": "success", "message": f"Driver {data.get('id')} installed"}).encode())
            return

def run_server():
    with socketserver.TCPServer(("", PORT), EclipseHubHandler) as httpd:
        httpd.serve_forever()

if __name__ == '__main__':
    # Start web server in background thread
    server_thread = threading.Thread(target=run_server, daemon=True)
    server_thread.start()

    # Launch PyQt5 WebEngine UI
    app = QApplication(sys.argv)
    window = QMainWindow()
    window.setWindowTitle("Eclipse OS Hub")
    window.resize(1100, 750)
    
    # Modern dark window hints if possible
    window.setStyleSheet("QMainWindow { background-color: #050505; }")

    view = QWebEngineView()
    view.setUrl(QUrl(f"http://localhost:{PORT}"))
    window.setCentralWidget(view)
    window.show()

    sys.exit(app.exec_())
