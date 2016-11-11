#!/usr/bin/python
# -*- coding: utf-8 -*-
import time
from functools import partial
from xmlrpclib import Fault, ServerProxy

__requires__ = 'supervisor'
import pkg_resources

from ansible.module_utils.basic import AnsibleModule
from supervisor.xmlrpc import SupervisorTransport


DOCUMENTATION = """
---
module: supervisorctl
version: "1.0"
short_description:  Manage supervisord managed services
description:
    - Controls supervisor managed services on remote hosts.
      (Note, supervisord must be installed)
options:
    name:
        required: true
        description:
        - Name of the service.
    state:
        required: true
        choices: [ started, stopped, restarted ]
        description:
          - C(started)/C(stopped) are idempotent actions that will not run
            commands unless necessary.  C(restarted) will always bounce the
            service.
    sleep:
        required: false
        description:
        - If the service is being C(restarted) then sleep this many seconds
          between the stop and start command. This helps to workaround badly
          behaving init scripts that exit immediately after signaling a process
          to stop.
    url:
        required: false
        description:
        - If given, C(url) will be used to connect to via XML-RPC.
          This C(url) should be in the form of a local socket connection URL.
          The default for this is unix:///var/run/supervisor.sock.
"""

EXAMPLES = """
# Example action to start service httpd, if not running
- supervisorctl: name=httpd state=started
# Example action to stop service httpd, if running
- supervisorctl: name=httpd state=stopped
# Example action to restart service httpd, in all cases
- supervisorctl: name=httpd state=restarted
"""

DEFAULT_URL = 'unix:///var/run/supervisor.sock'


def get_state(server, name):
    info = server.supervisor.getProcessInfo(name)
    state = info['state']
    return state


def start(server, name, wait=True):
    state = get_state(server, name) 
    if 10 <= state <= 20:
        return None, None
    return server.supervisor.startProcess(name, wait), None


def stop(server, name, wait=True):
    state = get_state(server, name) 
    if state == 0:
        return None, None
    try:
        return server.supervisor.stopProcess(name, wait), None
    except Fault as exc:
        return False, exc.faultString


def restart(server, name, sleep=None):
    stopped, message = stop(server, name)
    started, message = start(server, name)
    if not started:
        return started, message

    if sleep:
        time.sleep(sleep)
    return True, None


def main():
    module = AnsibleModule(
        argument_spec = dict(
            name = dict(required=True),
            state = dict(choices=['started', 'stopped', 'restarted']),
            sleep = dict(required=False, type='int', default=None),
            url = dict(required=False, default=DEFAULT_URL),
        ),
        supports_check_mode=True,
    )

    # Only supporting local connections at this time.
    server_url = module.params['url']
    transport = SupervisorTransport(None, None, serverurl=server_url)
    server = ServerProxy('http://127.0.0.1', transport=transport)

    state_funcs = {
        'started': partial(start, server),
        'stopped': partial(stop, server),
        'restarted': partial(restart, server,
                             sleep=module.params['sleep']),
    }

    func = state_funcs[module.params['state']]

    try:
        success, message = func(module.params['name'])
    except Fault as exc:
        message = exc.faultString
        return module.fail_json(msg=message)
    else:
        return module.exit_json(changed=success is not None,
                                msg=message)


if __name__ == '__main__':
    main()
