#!/usr/bin/python3
import cgi
import os

print("Content-type: text/html")
print("")
print(cgi.escape(os.environ["REMOTE_ADDR"]))
