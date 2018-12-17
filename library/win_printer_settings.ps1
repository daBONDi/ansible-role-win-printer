#!powershell
# (c) 2017, David Baumann <daBONDi@users.noreply.github.com>, and others
# No Licence Defined
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

$printer = Get-AnsibleParam -obj $params -name "printer" -type "str" -failifempty $true;
$property_name = Get-AnsibleParam -obj $params -name "name" -type "str" -failifempty $true;
$property_value = Get-AnsibleParam -obj $params -name "value" -failifempty $true;
$printer_level = Get-AnsibleParam -obj $params -name "printer_level" -type "int" -default 8;

$setprinter_exe = Get-AnsibleParam -obj $params -name "setprinter_util_path" -type "str" -default "C:/data/tools/setprinter.exe";

function Set-Property()
{
  $set_command_data = $null;
  if($property_value -is [int32])
  {
    $set_command_data = "pdevmode=$($property_name)=$($property_value)"
  }else{
    $set_command_data = "pdevmode=$($property_name)=""$($property_value)"""
  }
  try{
    $output = (& $setprinter_exe "-notcached" $printer $printer_level $set_command_data);
  }catch{
    Fai-Json -obj $result -message "Failed to set the value $property_value of $(property_name):$($_.Exception.Message)"
  }
  $result.output = $output;
}

function Get-Property
{
  $output = (& $setprinter_exe "-notcached" "-show" $printer $printer_level);

  $property_lines = $output | Where-Object { $_.Contains($property_name + "=") } | ForEach-Object { $_.ToString().Trim(); }

  $property_objects = $property_lines | ConvertFrom-StringData;

  $property_object = $null;
  if($property_objects -is [array])
  {
    $property_object = $property_objects[0];
  }else{
    $property_object = $property_objects;
  };

  $value =  $property_object[$property_name];

  # Detect if Value is a String
  if($value -is [String])
  {
    # Trim Additional "<value>"
    if($value.SubString(0,1) -eq '"')
    {
      $value = $value.SubString(1,($value.Length -1));
      $value = $value.SubString(0,($value.Length -1));
    }
  }

  if($property_value -is [int32])
  {
    try{
      return [int32]$value;
    }catch{
      Fail-Json -obj $result -message "Faild to parse current system value to int32, maybe you pass a wrong value?";
    }
  }
  if($property_value -is [string])
  {
    return [string]$value;
  }
  return $value;
}

$current_value = Get-Property

if($current_value -ne $property_value)
{
  if(-not $check_mode)
  {
    Set-Property;
  }
  $result.changed = $true;
}

$result.current = $current_value
$result.desired = $property_value

Exit-Json -obj $result