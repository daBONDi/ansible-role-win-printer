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


$ErrorActionPreference = 'Stop';


$result = @{
  changed = $false
}

$default_port_number = 9100
$default_protocol = 1 # 1 = Raw 2 = LPR
$default_temporary_port = "LPT1:"

$params = Parse-Args -arguments $args -supports_check_mode $true;
$check_mode = Get-AnsibleParam -obj $params -name "_ansible_check_mode" -type "bool" -default $false;
$diff_mode = Get-AnsibleParam -obj $params -name "_ansible_diff" -type "bool" -default $false;

$port_name = Get-AnsibleParam -obj $params -name "port_name" -type "str" -failifempty $true
$host_address = Get-AnsibleParam -obj $params -name "host_address" -type "str" -failifempty $true
$snmp_index = Get-AnsibleParam -obj $params -name "snmp_index" -type "int" -default 1
$snmp_community = Get-AnsibleParam -obj $params -name "snmp_community" -type "str" -default "public"
$snmp_enabled = Get-AnsibleParam -obj $params -name "snmp_enabled" -type "bool" -default $true
$state = Get-AnsibleParam -obj $params -name "state" -validateset "present","absent" -default "present";

function Test-PrinterPortExists()
{
  If( (Get-PrinterPort -Name $port_name -ErrorAction SilentlyContinue) )
  {
    return $true
  }
  return $false
}

function Test-IsPrinterPortInUse()
{
    If( (Get-Printer | Where-Object { $_.PortName -eq $port_name; }) )
    {
        return $true
    }
    return $false
}

function Test-NeedUpdate()
{
  $current = Get-PrinterPort -Name $port_name
  if($current){
    if($current.PrinterHostAddress.ToString() -ne $host_address)
    {
      return $true
    }
    if($current.SNMPIndex -ne $snmp_index)
    {
      return $true
    }
    if($current.SNMPCommunity.ToString() -ne $snmp_community)
    {
      return $true
    }
    if($current.SNMPEnabled -ne $snmp_enabled)
    {
      return $true
    }
  }
  return $false;
}

function Update-PrinterPortObject()
{
  # We cannot Update a Port so we need to Remove it
  $PrinterToMove = Get-Printer | Where-Object { $_.PortName -eq $port_name }
  $PrinterToMove | Set-Printer -PortName $default_temporary_port

  Get-PrinterPort -Name $port_name | Remove-PrinterPort
  Add-PrinterPortObject

  $PrinterToMove | Set-Printer -Portname $port_name
}

function Add-PrinterPortObject()
{
  try{
    $port = [WMIClass]"Win32_TcpIpPrinterPort"
    $port.psbase.scope.options.EnablePrivileges = $true
    $newPort = $port.CreateInstance()
    $newport.name = "$port_name"
    $newport.Protocol = $default_protocol  # 1 = RAW
    $newport.HostAddress = $host_address
    $newport.PortNumber = $default_port_number
    $newport.SnmpEnabled = $snmp_enabled
    $newport.SNMPCommunity = $snmp_community
    $newport.SNMPDevIndex = $snmp_index
    $newport.Put()
  }catch{
    Fail-Json -obj $result -message "Unkown Error on Add Printer Port: $($_.Exception.Message)"
  }
}


if(-not ($state -eq "absent"))
{
  if(-not (Test-PrinterPortExists) )
  {
    # Add new one
    if(-not $check_mode){ Add-PrinterPortObject; };
    $result.changed = $true
  }else{
    # Update current one
    if(Test-NeedUpdate)
    {
      if(-not $check_mode) { Update-PrinterPortObject };
      $result.changed = $true
    }
  }
}else{
  if(Test-PrinterPortExists)
  {
    if(-not $check_mode)
    {
      if( Test-IsPrinterPortInUse )
      {
        Fail-Json -obj $result -message "We cannot remove the printer port it is currenlty in use by a printer!";
      }
      try{
        Remove-PrinterPort -Name $port_name;
      }catch{
        Fail-Json -obj $result -message "Error on removing printer port $($port_name):$($_.Exception.Message)";
      }
    }
    $result.changed = $true
  }
}

Exit-Json -obj $result