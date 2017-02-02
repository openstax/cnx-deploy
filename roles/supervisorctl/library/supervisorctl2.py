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
version: "2.1"
short_description:  Manage supervisord managed services
description:
    - Controls supervisor managed services on remote hosts.
      (Note, supervisord must be installed)
options:
    name:
        required: false
        description:
        - Name of the service. (required if group is not supplied)
    group:
        required: false
        description:
        - Name of the service group. (required if name is not supplied)
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
- supervisorctl2: name=httpd state=started
# Example action to stop service httpd, if running
- supervisorctl2: name=httpd state=stopped
# Example action to restart service httpd, in all cases
- supervisorctl2: name=httpd state=restarted
# Example action to restart the supervisor group programs under the name servu
- supervisorctl2: group=servu state=restarted
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


def start_group(server, group, wait=True):
    return bool(server.supervisor.startProcessGroup(group, wait)), None


def stop_group(server, group, wait=True):
    return bool(server.supervisor.stopProcessGroup(group, wait)), None


def restart_group(server, group, sleep=None):
    stopped, message = stop_group(server, group)
    started, message = start_group(server, group)
    if not started:
        return started, message
    if sleep:
        time.sleep(sleep)
    return True, None


def main():
    module = AnsibleModule(
        argument_spec = dict(
            name = dict(required=False),
            group = dict(required=False),
            state = dict(choices=['started', 'stopped', 'restarted']),
            sleep = dict(required=False, type='int', default=None),
            url = dict(required=False, default=DEFAULT_URL),
        ),
        required_one_of=[('name', 'group')],
        supports_check_mode=True,
    )

    # Only supporting local connections at this time.
    server_url = module.params['url']
    transport = SupervisorTransport(None, None, serverurl=server_url)
    server = ServerProxy('http://127.0.0.1', transport=transport)

    name = module.params['name']
    if name:
        classification = 'proc'
    else:
        name = module.params['group']
        classification = 'group'

    state_funcs = {
        ('started', 'proc'): partial(start, server),
        ('stopped', 'proc'): partial(stop, server),
        ('restarted', 'proc'): partial(restart, server,
                                       sleep=module.params['sleep']),
        ('started', 'group'): partial(start_group, server),
        ('stopped', 'group'): partial(stop_group, server),
        ('restarted', 'group'): partial(restart_group, server,
                                        sleep=module.params['sleep']),
    }

    func = state_funcs[(module.params['state'], classification,)]

    try:
        success, message = func(name)
    except Fault as exc:
        message = exc.faultString
        return module.fail_json(msg=message)
    else:
        return module.exit_json(changed=success is not None,
                                msg=message)


if __name__ == '__main__':
    main()
