#!/bin/bash

export PATH="/bin:/sbin:/usr/bin:/usr/sbin"

#((UID)) && exec kanotix-su $0 "$@"

TMPPATH=$(mktemp -d)
trap "{ rm -rf $TMPPATH; }" SIGINT SIGTERM EXIT

#LIBPATH=/usr/lib/netcardconfig-kanotix
LIBPATH=$PWD
source $LIBPATH/get_netdev_functions || exit 1
source $LIBPATH/display_functions || exit 1

source ssft.sh || exit 1
SSFT_FRONTEND=$(ssft_choose_frontend)

get_netdev_valid_ifaces

if [[ ! ${WIRED_IFACES[*]} && ! ${WIRELESS_IFACES[*]} ]]
then
	display_error "No valid network devices detected"
	exit 1
elif [[ ! ${WIRELESS_IFACES[*]} && ${WIRED_IFACES[*]} ]]
then
	TYPE=LAN
	get_netdev_description ${WIRED_IFACES[*]}
elif [[ ! ${WIRED_IFACES[*]} && ${WIRELESS_IFACES[*]} ]]
then
	TYPE=WiFi
	get_netdev_description ${WIRELESS_IFACES[*]}
else
	SSFT_DEFAULT="Local Area Network"
	if display_wired_or_wireless  "Local Area Network  (LAN)" "Wireless Network  (WiFi)"
	then
		case "$SSFT_RESULT" in
			"Local Area Network"*)
				TYPE=LAN
				get_netdev_description ${WIRED_IFACES[*]}
				;;
			"Wireless Network"*)
				TYPE=WiFi
				get_netdev_description ${WIRELESS_IFACES[*]}
				;;
		esac
	fi
fi

until [[ $IFACE ]]
do
	if display_iface_list "$TYPE" "${IFACE[@]}"
	then
		if display_confirmation "Configure $TYPE settings for ${SSFT_RESULT%% *} ?"
		then
			IFACE=${SSFT_RESULT%% *}
		fi
	else
		display_error "Please select a network interface."
	fi
done

echo $IFACE
