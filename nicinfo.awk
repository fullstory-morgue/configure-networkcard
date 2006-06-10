#!/usr/bin/gawk -f

func return_first_regexp_from_cmd(cmd, regexp) {
	while ((cmd | getline) > 0) {
		if ($0 ~ regexp) {
			return
		}
	}
}

func get_sysfs_attr(attr) {
	attr_regexp = sprintf("^[ \t]+%s==\".+\"", attr)
	iface_udevinfo = sprintf("udevinfo -a -p /sys/class/net/%s", iface)
	return_first_regexp_from_cmd(iface_udevinfo, attr_regexp)
	close(iface_udevinfo)
	gsub(/(^[ \t]+.+==|")/, "")
}

func is_wireless_or_wired() {
	iface_regexp = sprintf ("^%s.*", iface)
	iface_iwconfig = sprintf ("iwconfig %s 2>/dev/null", iface)
	return_first_regexp_from_cmd(iface_iwconfig, iface_regexp)
	close(iface_iwconfig)
	if ($0 ~ iface_regexp) {
		type = "wireless"
	}
	else {
		type = "wired"
	}
	print type
}

BEGIN {
	IGNORECASE=1

	if (ARGV[1] != "lo") {
		iface = ARGV[1]
		delete ARGV[1]
	}
	else { 
		exit 1
	}

	get_sysfs_attr("SYSFS{type}")	
	if (!/^(1|24)/) { 
		exit 1
	}

	for (i = 0; i < ARGC; i++) {
		if (ARGV[i] == "type") {
			is_wireless_or_wired()
		}
		else if (ARGV[i] == "mac") {
			get_sysfs_attr("SYSFS{address}")
			mac = toupper($0)
			print mac
		}
		else if (ARGV[i] == "driver") {
			get_sysfs_attr("DRIVER")
			driver = $0
			print driver
		}
		else if (ARGV[i] == "desc") {
			get_sysfs_attr("BUS")
			if (/^pci$/) {
				get_sysfs_attr("SYSFS{device}")
				device = $0
				get_sysfs_attr("SYSFS{vendor}")
				vendor = $0
				lspci = sprintf("lspci -d %s:%s", vendor, device)
				if ((lspci | getline) > 0) {
					desc = gensub(/^.+:[ \t]+/,"","g",$0)
				}
			}
			else if (/^usb$/) {
				get_sysfs_attr("SYSFS{product}")
				product = $0
				get_sysfs_attr("SYSFS{manufacturer}")
				manufacturer = $0
				desc = sprintf("%s %s", manufacturer, product)
			}
			else if (/^ieee1394$/) {
				desc = "IEEE1394 (FireWire) Network Adapter"
			}
			commercialbans = "[ \t]?+(corporation|communications|technologies|technology|group|inc\\.|ltd\\.|co\\.|\\(tm\\)|\\(rev .+\\)),?"
			gsub (commercialbans,"", desc)
			print desc
		}
		delete ARGV[i]
	}
}
