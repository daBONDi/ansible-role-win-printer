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

#Requires -Module Ansible.ModuleUtils.SID.psm1

$ErrorActionPreference = 'Stop';

$result = @{
  changed = $false
}

$params = Parse-Args -arguments $args -supports_check_mode $true;
$check_mode = Get-AnsibleParam -obj $params -name "_ansible_check_mode" -type "bool" -default $false;
$diff_mode = Get-AnsibleParam -obj $params -name "_ansible_diff" -type "bool" -default $false;

$printer = Get-AnsibleParam -obj $params -name "printer" -type "string" -failifempty $true
$user = Get-AnsibleParam -obj $params -name "user" -type "string" -failifempty $true

$print = Get-AnsibleParam -obj $params -name "print" -type "bool" -default $true;
$manage_docs = Get-AnsibleParam -obj $params -name "manage_docs" -type "bool" -default $true;
$manage_printer = Get-AnsibleParam -obj $params -name "manage_printer" -type "bool" -default $false;

$state = Get-AnsibleParam -obj $params -name "state" -validateset "present","absent" -default "present";

function Set-SDDLForPrinter($PrinterName, $SDDL)
{
  try {
    Get-Printer -Name $PrinterName | Set-Printer -PermissionSDDL $SDDL
  }catch{
    Fail-Json -obj $result -message "Error on Setting SDDL Object on Printer $($PrinterName): $($_.Exception.Message)"
  }
}

function Get-SDDLFromPrinter($PrinterName)
{

  try {
    return (Get-Printer -Name $PrinterName -Full).PermissionSDDL
  }catch{
    Fail-Json -obj $result -message "Error getting SDDL Object from Printer $($PrinterName): $($_.Exception.Message)"
  }
}

function Add-PrintPermission($SDDL,$UserSID)
{
  $SecurityDescriptor = New-Object -TypeName Security.AccessControl.CommonSecurityDescriptor $true, $false, $SDDL;
  $AddAccessResult = $SecurityDescriptor.DiscretionaryAcl.AddAccess(
    [System.Security.AccessControl.AccessControlType]::Allow,
    $UserSID,
    131080,
    [System.Security.AccessControl.InheritanceFlags]::None,
    [System.Security.AccessControl.PropagationFlags]::None
  );
  return $SecurityDescriptor.GetSddlForm("ALL");
}

function Add-DocumentManagementPermission($SDDL,$UserSID)
{
  $SecurityDescriptor = New-Object -TypeName Security.AccessControl.CommonSecurityDescriptor $true, $false, $SDDL;
  $AddAccessResult = $SecurityDescriptor.DiscretionaryAcl.AddAccess(
    [System.Security.AccessControl.AccessControlType]::Allow,
    $UserSID,
    983088,
    [System.Security.AccessControl.InheritanceFlags]::ObjectInherit,
    [System.Security.AccessControl.PropagationFlags]::InheritOnly
  )

  # Read Permission for Sub Objects Needed
  $AddAccessResult = $SecurityDescriptor.DiscretionaryAcl.AddAccess(
    [System.Security.AccessControl.AccessControlType]::Allow,
    $UserSID,
    131072,
    [System.Security.AccessControl.InheritanceFlags]::ContainerInherit,
    [System.Security.AccessControl.PropagationFlags]::InheritOnly
  )
  return $SecurityDescriptor.GetSddlForm("ALL");
}

function Add-PrinterManagentPermission($SDDL,$UserSID)
{
  $SecurityDescriptor = New-Object -TypeName Security.AccessControl.CommonSecurityDescriptor $true, $false, $SDDL;

  $AddAccessResult = $SecurityDescriptor.DiscretionaryAcl.AddAccess(
    [System.Security.AccessControl.AccessControlType]::Allow,
    $UserSID,
    983052,
    [System.Security.AccessControl.InheritanceFlags]::None,
    [System.Security.AccessControl.PropagationFlags]::None
  )

  return $SecurityDescriptor.GetSddlForm("ALL");
}

function Test-AccessMask($SDDL,$AccessMask,$UserSID)
{
  $SecurityDescriptor = New-Object -TypeName Security.AccessControl.CommonSecurityDescriptor $true, $false, $SDDL;
  $acls = $SecurityDescriptor.DiscretionaryAcl | Where-Object { $_.SecurityIdentifier -eq $UserSID}
  foreach($acl in $acls)
  {
    if($acl.AccessMask -eq $AccessMask)
    {
      return $true
    }
  }
  return $false;
}

function Get-UserACLfromSDDL($SDDL,$UserSID)
{
  $SecurityDescriptor = New-Object -TypeName Security.AccessControl.CommonSecurityDescriptor $true, $false, $SDDL;
  $acls = $SecurityDescriptor.DiscretionaryAcl | Where-Object { $_.SecurityIdentifier -eq $UserSID}
  return $acls;
}

function Test-PrinterManagentPermission($SDDL,$UserSID){
  if( Test-AccessMask -SDDL $SDDL -AccessMask 983052 -UserSID $UserSID) { return $true}
  return $false;
}

function Test-DocumentManagementPermission($SDDL,$UserSID)
{
  $readManage = Test-AccessMask -SDDL $SDDL -AccessMask 131072 -UserSID $UserSID
  $docManage = Test-AccessMask -SDDL $SDDL -AccessMask 983088 -UserSID $UserSID
  $printManage = Test-AccessMask -SDDL $SDDL -AccessMask 983052 -UserSID $UserSID
  if($readManage -and $docManage)
  {
    return $true;
  }
  if($printManage -and $docManage)
  {
    return $true;
  }
  return $false;
}

function Test-PrintPermission($SDDL,$UserSID)
{
  if( Test-AccessMask -SDDL $SDDL -AccessMask 131080 -UserSID $UserSID) { return $true}
  if( Test-AccessMask -SDDL $SDDL -AccessMask 983052 -UserSID $UserSID) { return $true}
  return $false;
}

function Remove-PrinterACL($SDDL,$UserSID)
{
  $SecurityDescriptor = New-Object -TypeName Security.AccessControl.CommonSecurityDescriptor $true, $false, $SDDL;
  $acls = $SecurityDescriptor.DiscretionaryAcl | Where-Object { $_.SecurityIdentifier -eq $UserSID};
  foreach($acl in $acls)
  {
    $RemoveAccessResult = $SecurityDescriptor.DiscretionaryAcl.RemoveAccess(
      [System.Security.AccessControl.AccessControlType]::Allow,
      $acl.SecurityIdentifier,
      $acl.AccessMask,
      $acl.InheritanceFlags,
      $acl.PropagationFlags)
  }
  return $SecurityDescriptor.GetSddlForm("ALL");
}


function Get-NeedChange($SDDL,$UserSID, $AllowPrint, $AllowManageDocs, $AllowManagePrinter)
{
  if((Test-PrintPermission -SDDL $SDDL -UserSID $UserSID) -and !$AllowPrint){ return $true };
  if(-not (Test-PrintPermission -SDDL $SDDL -UserSID $UserSID) -and $AllowPrint){ return $true };
  
  if((Test-DocumentManagementPermission -SDDL $SDDL -UserSID $UserSID) -and !$AllowManageDocs) { return $true};
  if(-not (Test-DocumentManagementPermission -SDDL $SDDL -UserSID $UserSID) -and $AllowManageDocs) { return $true};

  if((Test-PrinterManagentPermission -SDDL $SDDL -UserSID $UserSID) -and !$AllowManagePrinter) { return $true};
  if(-not (Test-PrinterManagentPermission -SDDL $SDDL -UserSID $UserSID) -and $AllowManagePrinter) { return $true};
  return $false;
}

$user_sid = Convert-ToSid($user);
$prev_sddl = Get-SDDLFromPrinter -PrinterName $printer;
$new_sddl = $prev_sddl;

if($state -ne "absent")
{
  if( (Get-NeedChange -SDDL $new_sddl -UserSID $user_sid -AllowPrint $print -AllowManageDocs $manage_docs -AllowManagePrinter $manage_printer))
  {
    $new_sddl = Remove-PrinterACL -SDDL $new_sddl -UserSID $user_sid;

    # Print Permission
    if(-not (Test-PrintPermission -SDDL $new_sddl -UserSID $user_sid) -and $print)
    {
      $new_sddl = Add-PrintPermission -SDDL $new_sddl -UserSID $user_sid;
      $result.changed = $true;
    }

    # Document Management Permission
    if(-not (Test-DocumentManagementPermission -SDDL $new_sddl -UserSID $user_sid) -and $manage_docs)
    {
      $new_sddl = Add-DocumentManagementPermission -SDDL $new_sddl -UserSID $user_sid;
      $result.changed = $true;
    }

    if(-not (Test-PrinterManagentPermission -SDDL $new_sddl -UserSID $user_sid) -and $manage_printer)
    {
      $new_sddl = Add-PrinterManagentPermission -SDDL $new_sddl -UserSID $user_sid;
      $result.changed = $true;
    }
  }

}else{
  # Remove ACLs
  if(Get-UserACLfromSDDL -SDDL $new_sddl -UserSID $user_sid)
  {
    $new_sddl = Remove-PrinterACL -SDDL $new_sddl -UserSID $user_sid;
    $result.changed = $true;
  }
}

if(-not $check_mode -and $result.changed)
{
  Set-SDDLForPrinter -PrinterName $printer -SDDL $new_sddl;
}

if($result.changed)
{
  $result.prev_sddl = $prev_sddl;
  $result.new_sddl = $new_sddl;
}

Exit-Json $result