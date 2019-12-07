#!/usr/bin/python
# -*- coding: utf-8 -*-

# Copyright Block
# Copyright (c) 2018, [New Contributor(s) - REPLACE THIS]
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

# ANSIBLE_METADATA Block
# ANSIBLE_METADATA contains information about the module for use by other tools. At the moment, it informs other tools which type of maintainer the module has and to what degree users can rely on a module’s behaviour remaining the same over time.
ANSIBLE_METADATA = {
    'metadata_version': '1.0',
    'status': ['preview'],
    'supported_by': 'community'
}

DOCUMENTATION = '''
---
module: win_apfw_scheduledtask
version_added: "0.1"
short_description: This module creates or remove the schedule task needed for apfw_patching
description:
 - This will create or remove the schedule task that is needed for apfw_patching. This module uses schtasks.exe to create or remove the tasks so that it works on Windows 2008 / R2 where the schedule tasks com object is not available even on later versions of Powershell.
options:
notes:
author:
'''

EXAMPLES = '''
- name: Create schedule task "Install_Patch"
  modulename: win_apfw_scheduledtask_legacy
    name: Install_Patch
    state: present
'''

RETURN = '''
...
'''

# Ref
# https://docs.ansible.com/ansible/2.3/dev_guide/developing_modules_documenting.html
