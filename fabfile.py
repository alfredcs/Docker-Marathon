#!/usr/bin/env python
from fabric.api import *
from fabric.operations import run, put

def uptime():
  local('uptime')
  run('uptime')

def helloworld():
  print('Hello World - everything works in Fabric')

def scp(srcfile=None,destdir=None):
  if srcfile and destdir:
    with warn_only():
      run('[[ ! -d '+destdir+' ]] && mkdir -p '+destdir)
      put(srcfile, destdir)
      run('chmod a+x '+srcfile)

def exe(prog="uname"):
  with warn_only():
    run(prog)
