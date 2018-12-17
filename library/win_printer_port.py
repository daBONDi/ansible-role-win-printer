#!/usr/bin/python
# -*- coding: utf-8 -*-

# (c) 2018, David Baumann <daBONDi@users.noreply.github.com>
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.


DOCUMENTATION = '''
---
module: win_printer_port
version_added: "2.3"
short_description: Manage Windows Printer Ports
description: |
     Manage Windows Printer Ports
options:

  port_name:
    description:
      - Name of the Ports
    required: true
    default: null
    aliases: []

  host_address:
    description:
     - Printer Host Address
    required: true
    aliases: []

  snmp_index:
    description:
      - SNMP Index of the Printer
    requried: false
    default: 1
  
  snmp_community:
    description:
      - SNMP community where the printer port query status
    required: false
    default: public
  
  snmp_enabled:
    description
      - SNMP Status query enabled
    required: false
    default: true

  state:
    description:
      - If present driver will be installed, if absent driver will be removed
    choices:
      - "present"
      - "absent"
    default: "present
    
author: David Baumann
'''

EXAMPLES = '''
- name: "Ensure Printer Port"
  win_printer_port:
    port_name: "172.16.100.12"
    host_address: "172.16.100.12"
    snmp_index: 1
    snmp_community: "public32"
    snmp_enabled: yes
'''
