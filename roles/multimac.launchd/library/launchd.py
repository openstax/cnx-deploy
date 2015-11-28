#!/usr/bin/python
# -*- coding: utf-8 -*-

# ---
# YANKED FROM https://github.com/ansible/ansible-modules-extras/pull/995
# ---

# (c) 2015, David Symons <Mult1m4c@gmail.com>
#
# This file is part of Ansible
#
# This module is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This software is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this software.  If not, see <http://www.gnu.org/licenses/>.
import json
import plistlib

DOCUMENTATION = '''
---
module: launchd
author: David Symons (multimac)
short_description: Manage launchd on OS X
version_added: "2.0"
requirements:
  - OS X 10.10+
description:
  - Loads, unloads, enables, disables, starts, stops and restarts jobs via launchd
options:
  state:
    choices: [loaded, unloaded, enabled, disabled, started, stopped, restarted, status]
    default: loaded
    description:
      - The state the job should be in, or restarted to start/restart the job.
    required: false
  domain:
    description:
      - The name of the domain the module should affect.
      - See 'man launchctl' on OS X 10.10+ for an explanation of the domains.
    required: true
  label:
    aliases: [name]
    default: None
    description:
      - The label of the job to be affected.
      - This is not required for the loaded/unloaded states.
      - It can also be read from the plist specified by the path option.
    required: false
  path:
    description:
    default: None
      - The path of the launchd plist to be loaded/unloaded.
      - Only required by the loaded/unloaded states, however the label can be inferred from this option so it may be valuable to specify it anyway.
    required: false
  auto_enable:
    default: yes
    description:
      - Whether to enable the job upon loading it, or leave it in its current state
    required: false
  force_kill:
    default: no
    description:
      - Whether to send a SIGKILL or a SIGTERM when stopping a job
    required: false
'''

EXAMPLES = '''
# Loads the launchd plist '/Library/LaunchDaemons/com.ansible.test.plist' to the 'system' domain
- launchd: domain=system path=/Library/LaunchDaemons/com.ansible.test.plist state=loaded

# Enables the 'com.ansible.test' job (normally unneeded when auto_enable=yes when loading the job)
- launchd: domain=system label=com.ansible.test state=enabled

# Starts the 'com.ansible.test' job
- launchd: domain=system label=com.ansible.test state=started

# Retrieve the status of the 'com.ansible.test' job
- launchd: domain=system label=com.ansible.test state=status

# Force the 'com.ansible.test' job to stop
- launchd: domain=system label=com.ansible.test state=stopped force_kill=yes
'''

class LaunchCtl(object):

    def __init__(self, module):
        self.module = module
        
        self.domain = module.params['domain']
        self.label = module.params['label']
        self.path = module.params['path']

        self.auto_enable = module.params['auto_enable']
        self.force_kill = module.params['force_kill']

        # Check whether label is specified, and if not load from plist
        if self.path and not self.label:
            # Read the label from the plist
            plist_file = open(self.path, 'r')
            plist = plistlib.readPlist(plist_file)

            self.label = plist['Label']

        # Fail if we don't have a label as it's required (either specified or read from plist)
        if self.label is None:
            self.module.fail_json(msg="'label' or 'path' must be specified to infer the job label")

        self.target = self.domain + '/' + self.label

    def _get_launchctl_disabled(self, domain, is_disabled=True):
        """Retrieves the enabled/disabled jobs in the given domain.

        Note:
            This only returns jobs which have been enabled/disabled
            by 'launchctl [enable/disable]' or 'launchctl [load/unload] -w'.
            Any jobs which aren't specified are enabled by default.

            This also doesn't account for the 'Disabled' key in launchd plists.
        """

        cmd = ['launchctl', 'print-disabled', domain]
        (rc, out, err) = self.module.run_command(cmd)

        if is_disabled:
            ending = 'true'
        else:
            ending = 'false'

        # Parse the output of 'launchctl print-disabled [domain]' to retrieve only disabled/enabled jobs
        out = '\n'.join(
            map(lambda l: l.strip(), 
                filter(lambda l: l.endswith(ending), out.splitlines())
            )
        )

        return (rc, out, err)

    def get_job_status(self, target):
        """Returns the status of the given target"""
        cmd = ['launchctl', 'print', target]
        return self.module.run_command(cmd)

    def get_disabled_jobs(self, domain):
        """Returns all jobs which are disabled"""
        return self._get_launchctl_disabled(domain, True)

    def get_enabled_jobs(self, domain):
        """Returns all jobs which are enabled"""
        return self._get_launchctl_disabled(domain, False)

    def get_status(self):
        """Returns the status of this job"""
        return self.get_job_status(self.target)

    def is_enabled(self):
        """Returns whether this job is enabled"""
        quoted_label = "\"" + self.label + "\""
        return quoted_label not in self.get_disabled_jobs(self.domain)[1]

    def is_loaded(self):
        """Returns whether this job is loaded"""
        return self.get_status()[0] == 0

    def is_running(self):
        """Returns whether this job is running"""
        return "state = running" in self.get_status()[1]

    def load(self):
        """Load this job into launchd

        Note:
            Requires 'self.path' to be specified
        """
        if self.path is None:
            self.module.fail_json(msg="'path' is required for loading jobs")

        cmd = ['launchctl', 'bootstrap', self.domain, self.path]
        return self.module.run_command(cmd)

    def unload(self):
        """Unload this job into launchd

        Note:
            Requires 'self.path' to be specified
        """
        if self.path is None:
            self.module.fail_json(msg="'path' is required for unloading jobs")

        cmd = ['launchctl', 'unload', self.path]
        return self.module.run_command(cmd)

    def enable(self):
        """Enable this job in launchd"""
        cmd = ['launchctl', 'enable', self.target]
        return self.module.run_command(cmd)

    def disable(self):
        """Disable this job in launchd"""
        cmd = ['launchctl', 'disable', self.target]
        return self.module.run_command(cmd)

    def start(self):
        """Force this job to start"""
        cmd = ['launchctl', 'kickstart', self.target]
        return self.module.run_command(cmd)

    def stop(self):
        """Force this job to stop"""
        if self.force_kill:
            signal = '-9'
        else:
            signal = '-15'

        cmd = ['launchctl', 'kill', signal, self.target]
        return self.module.run_command(cmd)

    def restart(self):
        """Force a restart of this job"""
        cmd = ['launchctl', 'kickstart', '-k', self.target]
        return self.module.run_command(cmd)

def handle_loaded(launchctl):
    rc = None
    out = ''
    err = ''

    # Enable this job and add the output if requested
    if launchctl.auto_enable:
        (rc, enable_out, enable_err) = handle_enabled(launchctl)

        out = (out + '\n' + enable_out).strip('\n')
        err = (err + '\n' + enable_err).strip('\n')

    if not launchctl.is_loaded():
        if not launchctl.is_enabled():
            launchctl.module.fail_json(msg="attempted to load a disabled job", label=launchctl.label)

        (rc, load_out, load_err) = launchctl.load()
        if rc != 0:
            launchctl.module.fail_json(msg=load_err, rc=rc, label=launchctl.label)

        out = (out + '\n' + load_out).strip('\n')
        err = (err + '\n' + load_err).strip('\n')

    return (rc, out, err)

def handle_unloaded(launchctl):
    rc = None
    out = ''
    err = ''

    if launchctl.is_loaded():
        (rc, out, err) = launchctl.unload()
        if rc != 0:
            launchctl.module.fail_json(msg=err, rc=rc, label=launchctl.label)

    return (rc, out, err)

def handle_enabled(launchctl):
    rc = None
    out = ''
    err = ''

    if not launchctl.is_enabled():
        (rc, out, err) = launchctl.enable()
        if rc != 0:
            launchctl.module.fail_json(msg=err, rc=rc, label=launchctl.label)

    return (rc, out, err)

def handle_disabled(launchctl):
    rc = None
    out = ''
    err = ''

    if launchctl.is_enabled():
        (rc, out, err) = launchctl.disable()
        if rc != 0:
            launchctl.module.fail_json(msg=err, rc=rc, label=launchctl.label)

    return (rc, out, err)

def handle_started(launchctl):
    rc = None
    out = ''
    err = ''

    if not launchctl.is_loaded():
        launchctl.module.fail_json(msg="attempted to start an unloaded job", label=launchctl.label)

    if not launchctl.is_running():
        (rc, out, err) = launchctl.start()
        if rc != 0:
            launchctl.module.fail_json(msg=err, rc=rc, label=launchctl.label)

    return (rc, out, err)

def handle_stopped(launchctl):
    rc = None
    out = ''
    err = ''

    if not launchctl.is_loaded():
        launchctl.module.fail_json(msg="attempted to stop an unloaded job", label=launchctl.label)
        
    if launchctl.is_running():
        (rc, out, err) = launchctl.stop()
        if rc != 0:
            launchctl.module.fail_json(msg=err, rc=rc, label=launchctl.label)

    return (rc, out, err)

def handle_restarted(launchctl):
    rc = None
    out = ''
    err = ''

    if not launchctl.is_loaded():
        launchctl.module.fail_json(msg="attempted to restart an unloaded job", label=launchctl.label)
        
    (rc, out, err) = launchctl.restart()
    if rc != 0:
        launchctl.module.fail_json(msg=err, rc=rc, label=launchctl.label)

    return (rc, out, err)

def handle_status(launchctl):
    rc = None
    out = ''
    err = ''

    if not launchctl.is_loaded():
        launchctl.module.fail_json(msg="attempted to get the status of an unloaded job", label=launchctl.label)
        
    (rc, out, err) = launchctl.get_status()
    if rc != 0:
        launchctl.module.fail_json(msg=err, rc=rc, label=launchctl.label)

    return (rc, out, err)    


def main():
    state_choices = ['loaded', 'unloaded', 'enabled', 'disabled', 'started', 'stopped', 'restarted', 'status']
    module = AnsibleModule(
        argument_spec = dict(
            state=dict(default='loaded', choices=state_choices, type='str'),
            domain=dict(required=True, type='str'),
            label=dict(default=None, alias=['name'], type='str'),
            path=dict(default=None, type='path'),
            auto_enable=dict(default='yes', type='bool'),
            force_kill=dict(default='no', type='bool')
        ),
        supports_check_mode=False
    )

    launchctl = LaunchCtl(module)

    rc = None
    out = ''
    err = ''

    result = { }
    result['state'] = module.params['state']
    result['label'] = launchctl.label

    state = module.params['state']
    if state == 'loaded':
        (rc, out, err) = handle_loaded(launchctl)
    elif state == 'unloaded':
        (rc, out, err) = handle_unloaded(launchctl)
    elif state == 'enabled':
        (rc, out, err) = handle_enabled(launchctl)
    elif state == 'disabled':
        (rc, out, err) = handle_disabled(launchctl)
    elif state == 'started':
        (rc, out, err) = handle_started(launchctl)
    elif state == 'stopped':
        (rc, out, err) = handle_stopped(launchctl)
    elif state == 'restarted':
        (rc, out, err) = handle_restarted(launchctl)
    elif state == 'status':
        (rc, out, err) = handle_status(launchctl)

    if rc is None:
        result['changed'] = False
    else:
        result['changed'] = True

    if out:
        result['stdout'] = out
    if err:
        result['stderr'] = err

    module.exit_json(**result)


from ansible.module_utils.basic import *

if __name__ == '__main__':
    main()
