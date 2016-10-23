#!/usr/bin/env python
import getopt,base64,sys,os,socket,httplib,json,ssl
from urllib import urlencode

def usage(message=None):
  print "Usage: %s [-h] [-n|--host <host>] [-p|--port <port>] [-P|--Port]" % (sys.argv[0])
  print "-h|--help: show this message"
  print "-n|--host: Marathon DB hostname ot IP"
  print "-p|--port: Marathon http service port"
  print "-P|--port: Marathon https service port"
  sys.exit(-1)



STATE_OK = 0
STATE_WARNING = 1
this_hostname=socket.gethostname()
marathon_port="8080"
marathon_https_port=""

#import pdb; pdb.set_trace()
if os.path.isfile('/etc/marathon/conf/hostname') :
  with open('/etc/marathon/conf/hostname', 'r') as myfile:
    marathon_hostname=myfile.read().replace('\n', '')
if os.path.isfile('/etc/marathon/conf/https_port') :
  with open('/etc/marathon/conf/https_port', 'r') as myfile:
    marathon_https_port=myfile.read().replace('\n', '')
if os.path.isfile('/etc/marathon/conf/http_credentials') :
  with open('/etc/marathon/conf/http_credentials', 'r') as myfile:
    http_credentials=myfile.read().replace('\n', '')
    username=http_credentials.split(':')[0]
    password=http_credentials.split(':')[1]

try:
    (opts, args) = getopt.getopt(sys.argv[1:], "n:p:P:h", \
      ["summary", "help"])
except getopt.GetoptError:
    usage()
for o, a in opts:
    if o in ["-h", "--help"]:
      usage()
    elif o in ["-n", "--host"]:
      marathon_hostname=a
      this_hostname=a
    elif o in ["-p", "--port"]:
      marathon_port=a
    elif o in ["-P", "--Port"]:
      marathon_https_port=a

headers = { "Content-Type": "application/json" }
headers["Authorization"] = "Basic {0}".format(base64.b64encode("{0}:{1}".format(username, password)))
params=urlencode({})
#conn = httplib.HTTPConnection(host=mesos_host, port=mesos_port, timeout=2)
if marathon_https_port :
	conn = httplib.HTTPSConnection(host=this_hostname if marathon_hostname is None else marathon_hostname, port=marathon_https_port, timeout=2, context=ssl._create_unverified_context())
else:
	conn = httplib.HTTPConnection(host=this_hostname if marathon_hostname is None else marathon_hostname, port=marathon_port, timeout=2)

try:
    conn.request("GET", "/v2/leader", params, headers)
    response = json.loads(conn.getresponse().read())
    if not response :
        raise Exception("Marathon master is not available")
    elif  this_hostname not in response['leader'] :
        raise Exception("Not a Marathon master")
    else :
	print "HTTP/1.1 200 Merathon Master is", this_hostname
        sys.exit(STATE_OK)

except Exception as e:
    print str(e)
    sys.exit(STATE_WARNING)
