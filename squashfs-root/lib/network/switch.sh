#!bin/sh
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
if [ "$CONFIG_RAETH_SPECIAL_TAG" == "y" ]; then
	switch reg w e4 40043f  
else
	switch reg w e4 3f
fi

	if [ "$1" = "LLLLW" ]; then
if [ "$CONFIG_RAETH_SPECIAL_TAG" == "y" ]; then
		switch reg w 40 7007
		switch reg w 44 7007
		switch reg w 48 7008
		switch reg w 70 48444241
		switch reg w 74 50ef6050
else
		switch reg w 40 1001
		switch reg w 44 1001
		switch reg w 48 1002
		switch reg w 70 ffff506f
fi
	elif [ "$1" = "WLLLL" ]; then
if [ "$CONFIG_RAETH_SPECIAL_TAG" == "y" ]; then
		switch reg w 40 7008
		switch reg w 44 7007
		switch reg w 48 7007
		switch reg w 70 48444241
		switch reg w 74 41fe6050
else
        #r4cm use CONFIG_WAN_AT_P0 but LWLL,wan is at P1
		switch reg w 40 2002
		switch reg w 44 1001
		switch reg w 48 1001
		switch reg w 70 ffff437c
fi
	elif [ "$1" = "W1234" ]; then
		switch reg w 40 1005
		switch reg w 44 3002
		switch reg w 48 1004
		switch reg w 70 50484442
		switch reg w 74 ffffff41
	elif [ "$1" = "12345" ]; then
		switch reg w 40 2001
		switch reg w 44 4003
		switch reg w 48 1005
		switch reg w 70 48444241
		switch reg w 74 ffffff50
	elif [ "$1" = "GW" ]; then
		switch reg w 40 1001
		switch reg w 44 1001
		switch reg w 48 2001
		switch reg w 70 ffff605f
	elif [ "$1" = "G01234" ]; then
		switch reg w 40 2001
		switch reg w 44 4003
		switch reg w 48 6005
		switch reg w 70 48444241
		switch reg w 74 ffff6050
	fi

	#clear mac table if vlan configuration changed
	switch clear
}

setup_switch()
{
    model=`cat /proc/xiaoqiang/model`
    case $model in
	"R1CL" )
	    configEsw LLLLW
	    ;;
	"R3L"|"R3A"|"R4CM" )
	    configEsw WLLLL
	    ;;
	"*")
	    echo "setup_switch unknown model"
	    ;;
    esac

    local internet_tag=$(uci -q get mi_iptv.settings.internet_tag)
    local internet_vid=$(uci -q get mi_iptv.settings.internet_vid)
    local miptv="mclose"

    if [ "$internet_tag" == "1" ]; then
         local rmode=$(uci -q get xiaoqiang.common.NETMODE)
         if [ "$rmode" = "lanapmode" -o "$rmode" = "wifiapmode" -o "$rmode" = "whc_re" ]; then
             miptv="mclose"
         else
             if [ "x$internet_vid" != "x" ]; then
                 if [ $internet_vid -le 1 -o $internet_vid -gt 4094 ]; then
                     miptv="mclose"
                 else
                     miptv="mopen"
                 fi
             fi
         fi
    fi

    if [ "$miptv" == "mopen" ]; then
        /etc/init.d/mi_iptv iptv_switch_on
    fi

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

reset_switch()
{
    restoreEsw
    [ -f '/usr/bin/longloopd' ] && {
	/usr/bin/longloopd stop
    }
}
