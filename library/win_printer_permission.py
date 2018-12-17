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
module: win_printer_permission
version_added: "2.3"
short_description: Manage Windows Printer Share Permissions
description: |
     Manage Windows Printer Share Permissions
options:

  printer:
    description:
      - Name of the logical printer
    required: true
    default: null

  user:
    description:
      - User or Group to ensure permission

  print:
    description:
      - Allow printing to logical printer
    required: false
    default: true
  
  manage_docs:
    description:
      - Allow managing logical printer queue
    required: false
    default: true
  
  manage_printer:
    description:
      - Allow managing logical printer
  
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
- name: "Allow group to print
  win_printer_permission:
    printer: "printer1"
    user: "allow-to-print"
'''
