ACPI patch
==========
The patch registers the system fan as a simple ACPI fan (PNP0C0B)

```sh
% ls -l /sys/class/thermal/cooling_device0/
total 0
-rw-r--r-- 1 root root 4096 23 oct.  16:09 cur_state
lrwxrwxrwx 1 root root    0 23 oct.  16:07 device -> ../../../platform/PNP0C0B:00
-r--r--r-- 1 root root 4096 23 oct.  16:07 max_state
drwxr-xr-x 2 root root    0 23 oct.  16:07 power
lrwxrwxrwx 1 root root    0 23 oct.   2023 subsystem -> ../../../../class/thermal
-r--r--r-- 1 root root 4096 23 oct.  16:07 type
-rw-r--r-- 1 root root 4096 23 oct.   2023 uevent
```

```sh
% ls -l /sys/class/thermal/cooling_device0/device/firmware_node/
total 0
-r--r--r-- 1 root root 4096 23 oct.  16:21 fan_speed_rpm
-r--r--r-- 1 root root 4096 23 oct.  16:21 fine_grain_control
-r--r--r-- 1 root root 4096 23 oct.  16:21 hid
-r--r--r-- 1 root root 4096 23 oct.  16:21 modalias
-r--r--r-- 1 root root 4096 23 oct.  16:21 path
lrwxrwxrwx 1 root root    0 23 oct.  16:10 physical_node -> ../../../../platform/PNP0C0B:00
drwxr-xr-x 2 root root    0 23 oct.  16:21 power
-r--r--r-- 1 root root 4096 23 oct.  16:21 state0
-r--r--r-- 1 root root 4096 23 oct.  16:21 state1
lrwxrwxrwx 1 root root    0 23 oct.   2023 subsystem -> ../../../../../bus/acpi
-rw-r--r-- 1 root root 4096 23 oct.  16:21 uevent
-r--r--r-- 1 root root 4096 23 oct.  16:21 uid
```

Install
-------
Install acpia tools

```sh
pacman -S acpica
# or
apt install acpica-tools
```

```sh
sudo make install
```

Add the acpi_override before the initframfs in grub config.
```
initrd /boot/acpi_override /boot/initramfs-linux.img
```

TODO
----

there need to be a way to change between manual and automatic mode

set ```\_SB.PCI0.LPCB.H_EC.FSP1``` to 0x14 to be able to control the fan speed
set ```\_SB.PCI0.LPCB.H_EC.FSP1``` to 0x04 for automatic mode

I would prefer avoiding something like that:
```asl
Method (_FSL, 1) {
  If ((Arg0 = Zero))
  {
    Store (0x04, \_SB.PCI0.LPCB.H_EC.FSP1)
  }
  Else
  {
    Local0 = ((0xff - Arg0 - 1) << One)
    Store (0x14, \_SB.PCI0.LPCB.H_EC.FSP1)
    Store (Local0, \_SB.PCI0.LPCB.H_EC.FSC1)
  }
}
```

Reference
---------
ACPI Specification (fan): https://uefi.org/htmlspecs/ACPI_Spec_6_4_html/11_Thermal_Management/fan-device.html
Arch wiki: https://wiki.archlinux.org/title/DSDT
kernel source: https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/tree/drivers/acpi/fan_core.c?h=v6.5.8

