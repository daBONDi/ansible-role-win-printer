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

  name:
    description:
      - Name of the property to change

  value:
    description:
      - Value of the property to change
    required: true
  
  printer_level:
    description:
      - Printer Level where the settings can be found(setprint.exe)
    required: false
    default: 8
  
  setprinter_util_path:
    description:
      - path to the setprinter utility
    required: false
    default "C:/data/tools/setprinter.exe"
    
author: David Baumann
'''

EXAMPLES = '''
- name: "Ensure Duplex"
  win_printer_settings:
    printer: servplsw
    name: "dmDuplex"
    value: 2

# Check Values
#   setprinter.exe -notcached -show servplsw 8
#
# Set Values
#   setprinter.exe -notcached servplsw 8 pdevmode=dmDuplex=2
'''
