ThinkPad E520 fan control for Linux
===================================

This software is about controlling the fan speed for the [Lenovo ThinkPad Edge E520](https://www.thinkwiki.org/wiki/Category:E520).

Most ThinkPad have full access to the fans through the [thinkpad-acpi](https://www.kernel.org/doc/Documentation/laptops/thinkpad-acpi.txt) module.
Unfortunately, this laptop is one of the few that uses a different fan controller and is not supported.

On Windows, the fan can be controlled using [TPFanControl](https://thinkwiki.de/TPFanControl), a specific version of the software exist for this machine:
* [tpfc_v062e.zip (E520 only version)](https://thinkwiki.de/tpfancontrol/tpfc_v062e.zip)

Technical info
--------------

The [Embedded Controller](https://en.wikipedia.org/wiki/Embedded_controller) controls the fan on this system.

| Address | Size | Value                                                |
|---------|------|------------------------------------------------------|
| 0x93    | 8    | fan control register (0x04: automatic, 0x14: manual) |
| 0x94    | 8    | fan desired speed (0xff: max, 0x00: off)             |
| 0x95    | 8    | fan current speed (same as above max is about 0x66)  |

In automatic mode, setting the desired fan speed does nothing.
Switching to manual mode without providing a desired fan speed set the speed to 0xa9.

The fan is a `Delta KSB0405HB`, the datasheet indicate that the max speed is 3150 RPM.
```3150 / (0xff - 0x66) = 20.6```
The fan RPM can be approximated by doing `(255 - current_speed) * 21` (I don't have a tachometer to verify that).

On Linux there are three ways to get a fan supported:
* building a kernel module
* modifying the ACPI DSDT table (see [acpi](./acpi) folder)
* accessing the device through the debug interface (see ```fan_control.c``` and ```fan_gui.tcl```)

The first two options allow the use of Linux thermal zones, and the (thermald)[https://wiki.debian.org/thermald] daemon to set a new fan curve.
The last requires custom software to be build.

The Embedded Controller debug interface can be accessed using the ```ec_sys``` kernel module (```modprobe ec_sys write_support=1```).
This creates the ```/sys/kernel/debug/ec/ec0/io``` file, providing a direct mapping of the ec memory registers.

fan_control
-----------

```sh
$ gcc -o fan_control fan_control.c
$ sudo modprobe ec_sys write_support=1
$ sudo ./fan_control -p
         fan mode : 14
Selected fan speed: 229 (0xe5)
Actual   fan speed: 226 (0xe2)
$ sudo ./fan_control -s 255
Set to speed 255 (0xff)
$ sudo ./fan_control -a
Set to auto
```

Consider installing it to /usr/bin and setting the sticky bit (or add it to the sudoers file).

```sh
# cp ./fan_control /usr/bin
# chown root:root /usr/bin/fan_control
# chmod +s /usr/bin/fan_control

$ fan_control -a
```

Consider loading ```ec_sys``` on boot.

fan_gui
-------

```sh
$ chmod +x ./fan_gui.tcl
$ sudo ./fan_gui.tcl
```
!! Don't set the sticky bit on the tcl interpreter.

