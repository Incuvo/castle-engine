import socket
import select
import sys
import os
import SocketServer

# patch for brokern pipe (haproxy check health status)
def _finish(self,*args,**kw):
    try:
        if not self.wfile.closed:
            self.wfile.flush()
            self.wfile.close()
    except socket.error:
        pass
    self.rfile.close()

SocketServer.StreamRequestHandler.finish = _finish

