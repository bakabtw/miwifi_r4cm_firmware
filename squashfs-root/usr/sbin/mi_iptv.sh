#!/bin/sh
# mi_iptv

iptv_logger() {
    echo "mi_iptv: $1" > /dev/console
    #logger -t mi_iptv "$1"
}

iptv_usage() {
    echo "usage: ./mi_iptv.sh on|off"
    echo "value: on -- enable iptv "
    echo "value: off -- disable iptv"
    echo ""
}

restoreEsw()
{
	switch reg w 14 5555
	switch reg w 40 1001
	switch reg w 44 1001
	switch reg w 48 1001
	switch reg w 4c 1
	switch reg w 50 2001
	switch reg w 70 ffffffff
	switch reg w 98 7f7f
	switch reg w e4 7f

	#clear mac table if vlan configuration changed
	switch clear
}

configEsw()
{
	switch reg w 14 405555
	switch reg w 50 2001
	switch reg w 98 7f3f
	switch reg w e4 3f

	#r4cm use CONFIG_WAN_AT_P0 but LWLL,wan is at P1
	switch reg w 40 2002
	switch reg w 44 1001
	switch reg w 48 1001
	switch reg w 70 ffff437c
	#clear mac table if vlan configuration changed
	switch clear
}

reset_switch()
{
	restoreEsw
	[ -f '/usr/bin/longloopd' ] && {
	    /usr/bin/longloopd stop
	}
}

set_iptv()
{
	local lan_vid=$1
	local wan_vid=$2

	switch reg w 14 405555
	switch reg w 50 2001
	switch reg w 98 7f3f
	switch reg w e4 3f

	#r4cm use CONFIG_WAN_AT_P0 but LWLL,wan is at P1
	local LAN_PVID="1001"
	if [ "$lan_vid" == "2" ]; then
		LAN_PVID="2002"
	fi

	local PONE=`printf %03x $wan_vid`
	local PTWO=`printf %x $wan_vid`
	local WAN_PVID=$PTWO$PONE

	switch reg w 40 $WAN_PVID
	switch reg w 44 $LAN_PVID
	switch reg w 48 $LAN_PVID

	switch vlan set 0 $lan_vid 0011111
	switch vlan set 1 $wan_vid 1100001

	switch reg w 14 425555
	switch reg w 98 7f3d
	switch reg w e4 3d

	echo "lan_vid: $lan_vid:$LAN_PVID  wan_vid: $wan_vid:$WAN_PVID"
	#clear mac table if vlan configuration changed
	switch clear
}

iptv_close_config() {
	local new_wan_ifname="eth0.2"
	local old_wan_ifname="$(uci -q get network.wan.ifname)"

	if [ "x$new_wan_ifname" != "x$old_wan_ifname" ]; then
		uci -q batch <<EOF
		set network.wan.ifname=$new_wan_ifname
		commit network
EOF
	fi

	echo "close wan_ifname : $old_wan_ifname -> $new_wan_ifname"
}

iptv_open_config() {
	local internet_tag=$(uci -q get mi_iptv.settings.internet_tag)
	local internet_vid=$(uci -q get mi_iptv.settings.internet_vid)
	local wan_ifname=$WAN_IFNAME

	if [ "$internet_tag" != "1" ]; then
		return
	fi

	if [ "x$internet_vid" == "x" ]; then
		return
	fi

	[ $internet_vid -le 1 -o $internet_vid -gt 4094 ] && {
		echo "invalid internet_vid $internet_vid"
		return
	}

	local wan_vid=$internet_vid

	local new_wan_ifname="eth0.${wan_vid}"
	local old_wan_ifname="$(uci -q get network.wan.ifname)"

	if [ "x$new_wan_ifname" != "x$old_wan_ifname" ]; then
		uci -q batch <<EOF
		set network.wan.ifname=$new_wan_ifname
		commit network
EOF
	fi

	echo "open wan_ifname : $old_wan_ifname -> $new_wan_ifname"
}

iptv_open_switch() {
	local internet_tag=$(uci -q get mi_iptv.settings.internet_tag)
	local internet_vid=$(uci -q get mi_iptv.settings.internet_vid)
	local wan_ifname=$WAN_IFNAME

	if [ "$internet_tag" != "1" ]; then
		return
	fi

	if [ "x$internet_vid" == "x" ]; then
		return
	fi

	[ $internet_vid -le 1 -o $internet_vid -gt 4094 ] && {
		echo "invalid internet_vid $internet_vid"
		return
	}

	if [ -f "/proc/vlan_enable" ]; then
                echo 1 > /proc/vlan_enable
	fi

	set_iptv 1 $internet_vid
}

iptv_close_switch() {
	configEsw
	# enforce negotiate, make dhcp client send re-lease request.
	mii_mgr -s -p 0 -r 0 -v 3300
	mii_mgr -s -p 1 -r 0 -v 3300
	mii_mgr -s -p 2 -r 0 -v 3300
	mii_mgr -s -p 3 -r 0 -v 3300
	mii_mgr -s -p 4 -r 0 -v 3300
	WAN_SPEED=`uci get xiaoqiang.common.WAN_SPEED`
	if [ "$WAN_SPEED" -ne "10" ]
	then
		[ -f '/usr/bin/longloopd' ] && {
		/usr/bin/longloopd start
		}
	fi
}

iptv_to_lanap() {
	local internet_tag=$(uci -q get mi_iptv.settings.internet_tag)

	if [ "$internet_tag" != "1" ]; then
		return
	fi
	iptv_close_switch
	iptv_close_config
	/sbin/ifup wan
	sleep 5
}

iptv_to_ap() {
	local internet_tag=$(uci -q get mi_iptv.settings.internet_tag)

	if [ "$internet_tag" != "1" ]; then
		return
	fi
	iptv_open_switch
	iptv_open_config
	/sbin/ifup wan
}

iptv_to_close_lanap() {
	local internet_tag=$(uci -q get mi_iptv.settings.internet_tag)

	if [ "$internet_tag" != "1" ]; then
		return
	fi
	iptv_open_switch
	iptv_open_config
}


mi_iptv_lock="/var/run/mi_iptv.lock"
trap "lock -u $mi_iptv_lock; exit 1" SIGHUP SIGINT SIGTERM
lock $mi_iptv_lock

case "$1" in
	on_switch)
		iptv_open_switch
		;;
	off_switch)
		iptv_close_switch
		;;
	on)
		iptv_open_config
		;;
	off)
		iptv_close_config
		;;
	iptv_lanap)
		iptv_to_lanap
		;;
	iptv_ap)
		iptv_to_ap
		;;
	iptv_close_lanap)
		iptv_to_close_lanap
		;;
	restart)
		iptv_close_config
		iptv_open_config
		;;
	*)
		iptv_usage
		;;
esac

lock -u $mi_iptv_lock

return 0
