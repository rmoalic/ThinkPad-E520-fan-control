all: acpi_override

dsdt.dsl:
	sudo acpidump > acpidump
	acpixtract acpidump
	iasl -d dsdt.dat

patched: dsdt.dsl fan.patch
	patch -b dsdt.dsl fan.patch
	touch patched

dsdt.aml: dsdt.dsl patched
	iasl -ve dsdt.dsl

acpi_override: dsdt.aml
	mkdir -p kernel/firmware/acpi
	cp dsdt.aml kernel/firmware/acpi/dsdt.aml
	find kernel | cpio -H newc --create > acpi_override

install: 
	cp acpi_override /boot

clean:
	rm -f *.dat
	rm -f *.dsl
	rm -f acpidump dsdt.aml acpi_override patched
	rm -f *dsl.orig *dsl.rej
	rm -rf kernel