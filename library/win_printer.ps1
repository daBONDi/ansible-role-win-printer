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

# WANT_JSON
# POWERSHELL_COMMON

$ErrorActionPreference = 'Stop';

$result = @{
  changed = $false
}

$params = Parse-Args -arguments $args -supports_check_mode $true;
$check_mode = Get-AnsibleParam -obj $params -name "_ansible_check_mode" -type "bool" -default $false;
$diff_mode = Get-AnsibleParam -obj $params -name "_ansible_diff" -type "bool" -default $false;

$name = Get-AnsibleParam -obj $params -name "name" -type "str" -failifempty $true
$share_name = Get-AnsibleParam -obj $params -name "share_name" -type "str" -failifempty $true
$comment = Get-AnsibleParam -obj $params -name "comment" -type "str"
$location = Get-AnsibleParam -obj $params -name "location" -type "str"
$publish = Get-AnsibleParam -obj $params -name "publish" -type "bool" -default $false
$printer_port = Get-AnsibleParam -obj $params -name "printer_port" -type "str" -failifempty $true
$printer_driver = Get-AnsibleParam -obj $params -name "printer_driver" -type "str" -failifempty $true

$state = Get-AnsibleParam -obj $params -name "state" -validateset "present","absent" -default "present";

$result.desired = @{
  name = $name
  share_name = $share_name
  comment = $comment
  location = $location
  publish = $publish
  printer_port = $printer_port
  printer_driver = $printer_driver
  state = $state
}

function test_printer_port()
{
  If(Get-PrinterPort -Name $printer_port -ErrorAction SilentlyContinue)
  {
    return $true
  }
  Fail-Json -obj $result -message "Could not found Printer Port $printer_port on System!"
}

function test_printer_driver()
{
  if( (Get-PrinterDriver -Name $printer_driver -ErrorAction SilentlyContinue))
  {
    return $true
  }
  Fail-Json -obj $result -message "Could not found Printer Driver $printer_driver on System!"
  return $false
}

function printer_exists()
{
  if( (Get-Printer -Name $name -ErrorAction SilentlyContinue | Where-Object { $_.DeviceType -eq "Print"; }) )
  {
    return $true
  }
  return $false
}

function printer_need_update()
{
  $printers = Get-Printer -Name $name | Where-Object { $_.DeviceType -eq "Print"; } 
  foreach($printer in $printers)
  {
    if($printer.isShared -eq $false){ return $true; };
    if($printer.ShareName -ne $share_name -and $printer.isShared -eq $true ){ return $true; };
    if($printer.Location -ne $location){ return $true; };
    if($printer.Comment -ne $comment){ return $true; };
    if($printer.DriverName -ne $printer_driver){ return $true; };
    if($printer.PortName -ne $printer_port){ return $true; };
  } 
  return $false
}

function remove_printer()
{
  $printer = Get-Printer -Name $name
  $printer | Remove-Printer -Confirm:$false
}

function add_printer()
{ 
 
  test_printer_port;
  test_printer_driver;

  $addParams = @{
    Name = $name
    DriverName = $printer_driver
    Comment = $comment
    Location = $location
    PortName = $printer_port
    ShareName =  $share_name;
    Publish = $Publish
    Shared = $true
  };
  try{
    Add-Printer @addParams
  }catch{
    $result.PrinterAddParams = $addParams;
    Fail-Json -obj $result -message "Error on Adding Printer: $($_.Exception.Message) - $($_.Exception)"
  }
  
}

function update_printer()
{
  test_printer_port
  test_printer_driver;
  
  $printer = Get-Printer -Name $name | Where-Object { $_.DeviceType -eq "Print"; } 

  $updateParams = @{
    DriverName = $printer_driver
    Comment = $comment
    Location = $location
    PortName = $printer_port
    ShareName =  $share_name;
    Publish = $Publish
    Shared = $true
  }
  try{
    $printer | Set-Printer @updateParams
  }catch{
    $result.PrinterUpdateParams = $updateParams;
    Fail-Json -obj $result -message "Error on Updating Printer: $($_.Exception.Message) - $($_.Exception)"
  }
}

if(-not ($state -eq "absent"))
{
  if(printer_exists)
  {
    
    if(printer_need_update)
    {
      if(-not ($check_mode))
      {
        update_printer
      }
      $result.changed = $true
    }
  }else{
    add_printer
    $result.changed = $true
  }

}else{
  if(printer_exists)
  {
    if(-not ($check_mode))
    {
      remove_printer
    }
    $result.changed = $true
  }
}

Exit-Json -obj $result