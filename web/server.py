from http.server import ThreadingHTTPServer, SimpleHTTPRequestHandler
import socket
import select
import time

# Fake latency in seconds for WebSocket proxy (0 = no latency)
FAKE_LATENCY = 0.0

class COOPHandler(SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        super().end_headers()

    def do_GET(self):
        # Proxy WebSocket upgrade requests to the actual WebSocket server
        if self.path.startswith('/ws'):
            try:
                # Connect to the WebSocket server on port 2356
                backend = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                backend.connect(('localhost', 2356))

                # Forward the HTTP upgrade request
                request_line = f"{self.command} {self.path} {self.request_version}\r\n"
                backend.sendall(request_line.encode())

                for header, value in self.headers.items():
                    backend.sendall(f"{header}: {value}\r\n".encode())
                backend.sendall(b"\r\n")

                # Set sockets to non-blocking mode
                self.connection.setblocking(False)
                backend.setblocking(False)

                # Bidirectional forwarding loop
                while True:
                    readable, _, exceptional = select.select(
                        [self.connection, backend],
                        [],
                        [self.connection, backend],
                        1.0
                    )

                    if exceptional:
                        break

                    if self.connection in readable:
                        try:
                            data = self.connection.recv(4096)
                            if not data:
                                break
                            if FAKE_LATENCY > 0:
                                time.sleep(FAKE_LATENCY)
                            backend.sendall(data)
                        except:
                            break

                    if backend in readable:
                        try:
                            data = backend.recv(4096)
                            if not data:
                                break
                            if FAKE_LATENCY > 0:
                                time.sleep(FAKE_LATENCY)
                            self.connection.sendall(data)
                        except:
                            break

                backend.close()
            except Exception as e:
                print(f"WebSocket proxy error: {e}")
                try:
                    self.send_error(502, "Bad Gateway")
                except:
                    pass
            return

        # Normal file serving for non-WebSocket requests
        super().do_GET()

ThreadingHTTPServer(("localhost", 8000), COOPHandler).serve_forever()