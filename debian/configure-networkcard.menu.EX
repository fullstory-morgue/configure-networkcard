?package(configure-networkcard): \
	needs="X11" \
	section="Applications/System/Administration" \
	hints="sidux,Config" \
	title="Configure Network" \
	icon32x32="/usr/share/pixmaps/configure-networkcard.xpm" \
	icon16x16="/usr/share/pixmaps/configure-networkcard-16.xpm" \
	command="/usr/sbin/netcardconfig"
