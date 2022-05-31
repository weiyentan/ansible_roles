#!/usr/bin/python
# -*- coding: utf-8 -*-

# Copyright: (c) 2012, Michael DeHaan <michael.dehaan@gmail.com>, and others
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

# this is a windows documentation stub.  actual code lives in the .ps1
# file of the same name

ANSIBLE_METADATA = {}

DOCUMENTATION = r'''
---
module: win_apfwcompliance
version_added: "0.1"
short_description: Checks the value of the pathching status on a computer
description:
  - Checks the patching status of the computer using the APFW framework.
  - This is for Windows nodes.
options:
  data:
    description:
      - 
notes:
  - Requires the AutomatedPatching playbook to be run on the machine.
  - 
author:
- Wei-Yen Tan (@weiyen)
'''

EXAMPLES = r'''
# Check Windows Patching status on machines that are being patched
# by the AutomatedPatching playbook.
# Example from an Ansible Playbook
- win_apfwcompliance:

RETURN = '''
win_apfwcompliance:
    description: default output from job
    
ok: [] => {
    "Patchesremaining": 0,
    "Patchstatus": "success",
    "changed": false

'''