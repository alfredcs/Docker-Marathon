#!/usr/bin/env python
import getopt,base64,sys,os,socket,httplib,json,ssl
from urllib import urlencode

def usage(message=None):
  print "Usage: %s [-h] [-v][-n|--host <host>] [-p|--port <port>] [-i --uri <action uri>]" % (sys.argv[0])
  print "-h|--help: show this message"
  print "-v|--verbose: show URL ouput"
  print "-n|--host: Docker DB hostname ot IP"
  print "-p|--port: Docker http service port"
  print "-i|--uri: Action uri string"
  sys.exit(-1)



STATE_OK = 0
STATE_WARNING = 1
verbose=0
docker_hostname=socket.gethostname()
docker_port="4243"
action_uri="/images/json"

try:
    (opts, args) = getopt.getopt(sys.argv[1:], "n:p:i:hv", \
      ["summary", "help"])
except getopt.GetoptError:
    usage()
for o, a in opts:
    if o in ["-h", "--help"]:
      usage()
    if o in ["-v", "--help"]:
      verbose=1
    elif o in ["-n", "--host"]:
      docker_hostname=a
    elif o in ["-p", "--port"]:
      docker_port=a
    elif o in ["-i", "--uri"]:
      action_uri=a

headers = { "Content-Type": "application/json" }
params=urlencode({})
conn = httplib.HTTPConnection(host=docker_hostname, port=docker_port, timeout=2)
#import pdb;pdb.set_trace()
try:
    conn.request("GET", action_uri, params, headers)
    response = json.loads(conn.getresponse().read())
    if not response :
        raise Exception("Docker is not available")
    elif  len(response) < 1 :
        raise Exception("Docker is down or without an image!")
    else :
	if verbose > 0 :
	  print(json.dumps(response, indent=3,separators=(',', ': ')))
	print "HTTP/1.1 200 OK"
        sys.exit(STATE_OK)

except Exception as e:
    print str(e)
    print "HTTP/1.1 503 Service Unavailable"
    sys.exit(STATE_WARNING)
