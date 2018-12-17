#!powershell

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

#
# WANT_JSON
# POWERSHELL_COMMON

$ErrorActionPreference = 'Stop';


$result = @{
  changed = $false
}

$params = Parse-Args -arguments $args -supports_check_mode $true;
$check_mode = Get-AnsibleParam -obj $params -name "_ansible_check_mode" -type "bool" -default $false;
$diff_mode = Get-AnsibleParam -obj $params -name "_ansible_diff" -type "bool" -default $false;

$printer = Get-AnsibleParam -obj $params -name "printer" -type "str" -failifempty $true
$queued = Get-AnsibleParam -obj $params -name "queued" -type "bool" -default $true
$do_complete_first = Get-AnsibleParam -obj $params -name "do_complete_first" -type "bool" -default $true


$printerObject = Get-WmiObject win32_printer -Filter "name='$printer'";

if(-not $printerObject)
{
  Fail-Json -Message "Could not find Printer $printer"
}

$result.currentQueued = $printerObject.Queued;
$result.desiredQueued = $queued;
$result.currentDoCompleteFirst = $printerObject.DoCompleteFirst
$result.desiredDoCompleteFirst = $do_complete_first

if($queued -ne $printerObject.Queued)
{
  $printerObject.Queued = $queued;
  $result.changed = $true;
}
if($do_complete_first -ne $printerObject.DoCompleteFirst)
{
  $printerObject.DoCompleteFirst = $do_complete_first;
  $result.changed = $true;
}
if($result.changed -and (-not $check_mode))
{
  $printerObject.Put(); # Save Changes
}

Exit-Json -obj $result
