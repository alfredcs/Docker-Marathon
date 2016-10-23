#!/usr/bin/env python
import getopt,sys,os,socket,httplib,json
from urllib import urlencode

STATE_OK = 0
STATE_WARNING = 1
mesos_ip=socket.gethostname()
mesos_port="5050"

def usage(message=None):
  print "Usage: %s [-h] [-n|--host <host>] [-p|--port <port>]" % (sys.argv[0])
  print "-h|--help: show this message"
  print "-n|--host: Mesos hostname or IP"
  print "-p|--port: Mesos http service port"
  sys.exit(-1)

#import pdb; pdb.set_trace()
if os.path.isfile('/etc/mesos-master/ip') :
  with open('/etc/mesos-master/ip', 'r') as myfile:
    this_ip=myfile.read().replace('\n', '')
if os.path.isfile('/etc/mesos-master/http_port') :
  with open('/etc/mesos-master/http_port', 'r') as myfile:
    mesos_port=myfile.read().replace('\n', '')

try:
    (opts, args) = getopt.getopt(sys.argv[1:], "n:p:h", \
      ["summary", "help"])
except getopt.GetoptError:
    usage()
for o, a in opts:
    if o in ["-h", "--help"]:
      usage()
    elif o in ["-n", "--host"]:
      mesos_ip=a
    elif o in ["-p", "--port"]:
      mesos_port=a


headers = { "Content-Type": "application/json" }
params=urlencode({})
#conn = httplib.HTTPConnection(host=mesos_host, port=mesos_port, timeout=2)
conn = httplib.HTTPConnection(host=mesos_ip if this_ip is None else mesos_ip, port=mesos_port, timeout=2)

try:
    conn.request("GET", "/metrics/snapshot", params, headers)
    response = json.loads(conn.getresponse().read())
    if not response :
        raise Exception("Mesos master is not available")
    elif int(response['master/elected']) != 1:
        raise Exception("Not a Mesos master")
    else :
	print "HTTP/1.1 200 Mesos Master OK"
        sys.exit(STATE_OK)

except Exception as e:
    print str(e)
    sys.exit(STATE_WARNING)
