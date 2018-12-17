# win-printer

> CAUTION! This role is a version for a internal System, it is not maintaned or supported by me(@daBONDi)
> Use it only as reference and ideas!

Create/Configure a Windows Printer

This Role Combines multiple Modules to create/config a network printer

## Requirements

- Ensure setprinter.exe is under files directory
  - Download it from Windows 2003 Server Resource Kit
- Ensure Windows Printing Service Feature is installed, see rol: **win-print-service**
- Ensure the Drivers are already preinstalled, see role: **win-printer-driver**

## Typical Usage

Create a host_var file **printers.yml** for the printer server and define a list of printers

```yaml
printers:
  - name: "les308plsw"
    printer_type: "{{ printer_type.CE459A }}"
    permission: "{{ printer_permission_type.employe_printer }}"
    location: "FJ-Schloss-Lehrerzimmer-S308"
    network:
      ip_address: "172.16.100.36"
      mac_address: "3c4a9244da15"

  - name: "les303plsw"
    printer_type: "{{ printer_type.CE459A }}"
    permission: "{{ printer_permission_type.employe_printer }}"
    location: "FJ-Schloss-Lehrerzimmer-S303"
    network:
      ip_address: "172.16.100.45"
      mac_address: "3C4A9244CACA"
```

Create a host_var file **printer-drivers** to install also the desired drivers

## Example

```yaml
- win_printer:
    printers:
    - name: "les308plsw"
      printer_type:
        driver_name: "HP Universal Printing PCL 6 (v6.6.0)"
        product_name: "HP LaserJet P2055dn"
        product_number: "CE459A"
        color: no
        type: 'Laser'
        duplex: yes
        papersize: 'A4'
        driver_settings:
          - name: "dmPaperSize"
            value: 9
          - name: "dmDuplex"
            value: 1
      permission:
        admins:
          - aug-printermanagement
        users:
          - ug-employe
      location: "FJ-Schloss-Lehrerzimmer-S308"
      network:
        ip_address: "172.16.100.36"
        mac_address: "3c4a9244da15"

    - name: "les303plsw"
      printer_type: "{{ printer_type.CE459A }}"
      permission: "{{ printer_permission_type.employe_printer }}"
      location: "FJ-Schloss-Lehrerzimmer-S303"
      network:
        ip_address: "172.16.100.45"
        mac_address: "3C4A9244CACA"
```

> Have a Role var 'only_with_printer' to filter execution only on 1 Printer in the List

```yaml
roles:
  - { role: win-printer, only_with_printer: EDV7PLSW }
```

## Included Modules

### win_printer_settings

Change Printer Settings with the tool setprinter.exe

#### Example

```yaml
- win_printer_settings:
    printer: servplsw
    name: "dmDuplex"
    value: 2
```

### win_printer

Ensure the printer is added

#### Example

```yaml
  win_printer:
    name: "drucker1"
    share_name: "drucker1"
    comment: "A4, Laser, Schwarzweß"
    location: "Büro"
    publish: false
    printer_port: "172.16.11.12"
    printer_driver: "HP Universal Printing PS (v6.6.0)"
```

### win_printer_port

Ensure the local tcp port is present

#### Example

```yaml
- win_printer_port:
    port_name: "172.16.100.12"
    host_address: "172.16.100.12"
    snmp_index: 1
    snmp_community: "public32"
    snmp_enabled: yes
```

### win_printer_permission

Ensure the printer share permission

#### Example

```yaml
- win_printer_permission:
    printer: "printer1"
    user: "allow-to-print"
```

### win_printer_queue

Ensure the printer Queue parameters

Default is to Set "Start printing after last page is spooled" and enable "Print spooled documents first"

```yaml
# Set the Optione "Start printing after last page is spooled"
# Disable the Option "Print spooled documents first"
- win_printer_queue
    printer: "printer1"
    queued: true
    do_complete_first: false
```
