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
module: win_printer_queue
version_added: "2.3"
short_description: Manage Windows Printer Queue Settings
description: |
     Manage Windows Printer Queue Settings
options:

  printer:
    description:
      - Name of the printer queue
    required: true
    default: null
    aliases: []

  queued:
    description:
     - if true, printer queue will wait until last page is in the spooler and then send it to the printer
     - if false, printer queue will send immediately after first page in the spooler to the printer
    required: false
    choices:
      - "yes"
      - "No
    aliases: []
    default: true

  do_complete_first:
    description:
      - if true, will print queued print jobs first
      - if false, will print next print job
    required: false
    alias: []
    default: true
    
author: David Baumann
'''

EXAMPLES = '''
- name: "Ensure Printer Port"
  win_printer_queue:
    queued: no
'''
