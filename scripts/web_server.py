import http.server
import socketserver
import os
import sys
import socket

PORT = 44819
DIRECTORY = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "flutter_app", "build", "web")

def get_local_ip():
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(('10.254.254.254', 1)) # Dummy IP
        IP = s.getsockname()[0]
    except Exception:
        IP = '127.0.0.1'
    finally:
        s.close()
    return IP

class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)

class MyTCPServer(socketserver.TCPServer):
    allow_reuse_address = True

if __name__ == "__main__":
    if not os.path.exists(DIRECTORY):
        print(f"Error: Directory {DIRECTORY} does not exist.")
        sys.exit(1)
        
    local_ip = get_local_ip()
    os.chdir(DIRECTORY)
    
    # Binding to the specific local IP ensures it is accessible on the LAN 
    # but not via external interfaces (unless port forwarded at the router)
    try:
        with MyTCPServer((local_ip, PORT), Handler) as httpd:
            print(f"Serving Smart Home Web App at http://{local_ip}:{PORT}")
            httpd.serve_forever()
    except Exception as e:
        print(f"Fatal error: {e}")
        sys.exit(1)
