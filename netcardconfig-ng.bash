#!/bin/bash

export PATH="/bin:/sbin:/usr/bin:/usr/sbin"

#((UID)) && exec kanotix-su $0 "$@"

source ssft.sh || exit 1

if [[ $DISPLAY ]]
then
	export SSFT_FRONTEND="kdialog"
else
	export SSFT_FRONTEND="dialog"
fi

function error () {
	ssft_display_error ERROR "$@"
	exit 1
}

function get_valid_netdevs () {
	local count iface netdev_type
	for i in /sys/class/net/*
	do
		((count++))
		iface=$(basename $i)
		# TODO: /usr/lib/netcardconfig-kanotix perhaps
		netdev_type=$(awk -f $PWD/nicinfo.awk $iface type)
		case $netdev_type in
			wired)
				WIRED_IFACES[$count]=$iface
				;;
			wireless)
				WIRELESS_IFACES[$count]=$iface
				;;
		esac
	done
}

function get_netdev_desc () {
	local count iface desc
	for i in "$@"
	do
		((count++))
		iface=$i
		desc=$(awk -f $PWD/nicinfo.awk $iface desc)
		IFACE[$count]="$iface    [$desc]"
	done
}

function display_netdev_wire_or_wifi () {
	local tit msg
	tit="Network Type"
	msg="What type of network would you like to setup?"
	ssft_select_single "$tit" "$msg" "$@"
}

function display_netdev_list () {
	local tit msg type
	type=$1
	shift
	tit="Choose Network Device"
	msg="What $type device is to be configured?"
	ssft_select_single "$tit" "$msg" "$@"
}

get_valid_netdevs

if [[ ! ${WIRED_IFACES[*]} && ! ${WIRELESS_IFACES[*]} ]]
then
	error "No valid network devices detected"
fi

if [[ ! ${WIRELESS_IFACES[*]} ]]
then
	TYPE=LAN
	get_netdev_desc ${WIRED_IFACES[*]}
elif [[ ! ${WIRED_IFACES[*]} ]]
then
	TYPE=WiFi
	get_netdev_desc ${WIRELESS_IFACES[*]}
else
	SSFT_DEFAULT="Local Area Network"
	if display_netdev_wire_or_wifi "Local Area Network" "Wireless Network"
	then
		case "$SSFT_RESULT" in
			"Local Area Network")
				TYPE=LAN
				get_netdev_desc ${WIRED_IFACES[*]}
				;;
			"Wireless Network")
				TYPE=WiFi
				get_netdev_desc ${WIRELESS_IFACES[*]}
				;;
		esac
	fi
fi

if display_netdev_list "$TYPE" "${IFACE[@]}"
then
	IFACE=$(echo $SSFT_RESULT | awk '{ print $1 }')
fi

echo $IFACE
