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

  name:
    description:
      - Name of the Printer
    required: true

  share_name:
    description:
     - Name of the Printer Share
    required: true

  comment:
    description:
      - comment of the printer
    required: false
    default: null
  
  location:
    description:
      - Location String of the Printer
    required: false
    default: null
    
  publish:
    description
      - Publish this Printer into Active Directory
    default: false

  printer_port:
    description:  
      - Name of the Printer Port to Use
    required: true
  
  printer_driver:
    description:
      - Name of the Printer Driver to use
    required: true

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
- name: "Ensure Printer drucker1"
  win_printer:
    name: "drucker1"
    share_name: "drucker1"
    comment: "A4, Laser, Schwarzweß"
    location: "Büro"
    publish: false
    printer_port: "172.16.11.12"
    printer_driver: "HP Universal Printing PS (v6.6.0)"
'''
