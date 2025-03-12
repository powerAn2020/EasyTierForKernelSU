#!/system/bin/sh

###
### easytier for KSU - api.sh
###
### Usage:
###   api.sh <api_type> [options]
###
### Options:
###   -h                                            -- Show this message.
###   <api_type>   local/central
###     local
###       status                                    -- Show Node Status
###       service                                    -- Manage easytier-One Service Status
###         action     value:[ start | stop ]
###       network                                   -- When the action is "list", "networkid" and "bodydata" are optional. When the action is "leave", "bodydata" is optional. When the action is "join", "networkid" and "bodydata" are required.
###         action     value:[ list | leave | join ]
###         networkid  value:[ networkid ](optional)
###         bodydata   value:[ JSON object ](optional)
###       peer                                      -- All the nodes your node knows about
###       firewall                                  -- Control the firewall to allow traffic into port 9993
###         action     value:[ A | D ]
###       router                                    -- Set the easytier traffic routing method
###         router     value:[ routing (unrealized) | main ]
###         action     value:[ A | D ]
###       orbit                                     -- Join Private Root Servers
###         moonid     value:[ moonid ]
###     central
###       status                                    -- Show Center Status
###       network                                   -- When the action is "list", "networkid" and "bodydata" are optional. When the action is "remove", "bodydata" is optional. When the action is "add", No parameters are required. When the action is "modify", "networkid" and "bodydata" are required.
###         action     value:[ list | remove | add | modify ]
###         networkid  value:[ networkid ](optional)
###         bodydata   value:[ JSON object ](optional)
###       member                                     -- When the action is "list", "bodydata" and "memberID" are optional. When the action is "remove", "bodydata" is optional. When the action is "modify", "networkid", "memberID" and "bodydata" are required.
###         action     value:[ list | remove | modify ]
###         networkid  value:[ networkid ] (optional)
###         memberID   value:[ memberID ] (optional)
###         bodydata   value:[ JSON object ] (optional)
###     apiToken                                    -- Manage the tokenAuth for accessing the central API
###       action       value:[ show | update ]
###       key          value:[ apiToken ]
###
### Example:
###   help
###     sh api.sh -h
###
###   local
###     sh api.sh local status
###     sh api.sh local service start
###     sh api.sh local service stop
###     sh api.sh local peer
###     sh api.sh local firewall A
###     sh api.sh local firewall D
###     sh api.sh local router routing A (unrealized)
###     sh api.sh local router routing D (unrealized)
###     sh api.sh local router main A
###     sh api.sh local router main D
###     sh api.sh local orbit yourMoonid
###     sh api.sh local network list
###     sh api.sh local network leave yourNetworkid (suggest: use command `easytier-cli leave yourNetworkid`)
###     sh api.sh local network join  yourNetworkid {} (suggest: use command `easytier-cli join yourNetworkid`)
###
###   central
###     sh api.sh central status
###     sh api.sh central network list
###     sh api.sh central network remove yourNetworkid
###     sh api.sh central network add
###     sh api.sh central network modify yourNetworkid {}
###     sh api.sh central member list yourNetworkid
###     sh api.sh central member remove yourNetworkid memberID
###     sh api.sh central member modify yourNetworkid memberID '{"hidden":false,"config":{"authorized":true}}'
###
###   apiToken
###     sh api.sh apiToken show
###     sh api.sh apiToken update xxxxxxxxx
###

MODDIR=${0%/*}

if [ -f "/data/adb/ksu/bin/busybox" ]; then
  # busybox KSU
  busybox="/data/adb/ksu/bin/busybox"
elif [ -f "/data/adb/ap/bin/busybox" ]; then
  # busybox APatch
  busybox="/data/adb/ap/bin/busybox"
else
  # busybox Magisk
  busybox="/data/adb/magisk/busybox"
fi

ETPATH=/data/adb/easytier
MANUAL=${ETPATH}/MANUAL

PIDFILE=$ETPATH/easytier-one.pid
easytierD=$MODDIR/easytier-one
SECRETFILE=$ETPATH/authtoken.secret
TOKENAUTH=$ETPATH/TOKENAUTH
TOKEN=$(cat ${SECRETFILE})
apiToken=$(grep -v '^[[:space:]]*$' $TOKENAUTH)
CurlBIN="${MODDIR}/bin/curl -s -A 'easytierForKSU' --connect-timeout 5"
localAPIBase='http://localhost:9993'
remoteAPIBase='https://api.easytier.com/api/v1'
export CURL_CA_BUNDLE=${MODDIR}/bin/cacert.pem
# =========================== local service ===========================
local_status() {
  $CurlBIN -H "X-ZT1-Auth: $TOKEN" ${localAPIBase}/status
}

local_networks() {
  # $1 operation GET/POST/DELETE
  # $2 jsondata {}
  # $3 /networkid
  if [ "$1" = "GET" -o "$1" = "DELETE" ]; then
    $CurlBIN -X $1 -H "X-ZT1-Auth: $TOKEN" ${localAPIBase}/network${3}
  else
    $CurlBIN -X $1 -H "X-ZT1-Auth: $TOKEN" -H "Content-Type:application/json" -d "$2" ${localAPIBase}/network$3
  fi
}

local_peer() {
  $CurlBIN -H "X-ZT1-Auth: $TOKEN" ${localAPIBase}/peer
}
# $1 :A 和 D
local_firewall() {
  if [ "$1" = "A" ]; then
    touch ${ETPATH}/ALLOW_9993
  elif [ "$1" = "D" ]; then
    rm ${ETPATH}/ALLOW_9993
  else
    echo "only [A,D]"
    exit 1
  fi
  iptables -$1 INPUT -p udp --dport 9993 -j ACCEPT
  ip6tables -$1 INPUT -p udp --dport 9993 -j ACCEPT
}
# join moon
local_orbit() {
  sh ${MODDIR}/easytier-cli orbit $1 $1
}

local_router() {
  if [ "$1" = "routing" ]; then
    echo "Unrealized"
    #TODO android默认ip rule不走main表 除了提升main表优先级,是否还有其它解决方案?
    # Reference https://yotam.net/posts/network-management-in-android-routing/
    # Reference https://unix.stackexchange.com/questions/424314/changing-default-ip-rule-priority-for-main-table
    # Reference https://github.com/easytier/easytierOne/issues/1715#issuecomment-1780625754

    # ip route add table $your_selected_table_id $cide/$prefix dev $zt_iface_name proto kernel scope link
  else
    # Reference https://blog.csdn.net/G_Rookie/article/details/109679262
    if [ "$2" = "add" ]; then
      ip rule add from all lookup main pref 9000
    else
      ip rule del from all lookup main pref 9000
    fi
  fi
}
local_service() {
  if [ "$1" = "start" ]; then
    if [ ! -f "${ETPATH}/state/disable" ];then
      touch ${ETPATH}/state/disable
    fi
    rm ${ETPATH}/state/disable
  else
    touch ${ETPATH}/state/disable
  fi
}
# =========================== Central API ===========================
api_networks() {
  # $1 operation GET/POST/DELETE
  # $2 jsondata {}
  # $3 /networkid
  if [ "$1" = "GET" -o "$1" = "DELETE" ]; then
    $CurlBIN -X $1 -H "Authorization: token $apiToken" ${remoteAPIBase}/network${3}
  else
    $CurlBIN -X $1 -H "Content-Type:application/json" -H "Authorization: token $apiToken" -d "$2" ${remoteAPIBase}/network${3}
  fi
}

api_members() {
  # $1 operation GET/POST/DELETE
  # $2 networkid
  # $3 /memberID
  # $4 jsondata {}
  if [ "$1" = "GET" -o "$1" = "DELETE" ]; then
    $CurlBIN -X ${1} -H "Authorization: token $apiToken" ${remoteAPIBase}/network/${2}/member${3}
  else
    $CurlBIN -X $1 -H "Content-Type:application/json" -H "Authorization: token $apiToken" -d "$4" ${remoteAPIBase}/network/${2}/member${3}
  fi
}
remote_status() {
  $CurlBIN -X GET -H "Authorization: token $apiToken" ${remoteAPIBase}/status
}
check_apiToken() {
  if [ ! -f ${TOKENAUTH} -o -z "$apiToken" ]; then
    # 重定向提示内容给webui
    {
      echo "The api token was not found. Use 'api.sh update xxxx' to add it." 1>&2
      exit 1
    }
  fi
}
help() {
  sed -rn 's/^### ?//;T;p;' "$0"
}
# =========================== main ===========================
case $1 in
local)
  shift
  case $1 in
  status)
    local_status
    ;;
  service)
    shift
    local_service $1
    ;;
  network)
    shift
    action=$1
    networkid=$2
    bodydata=$3
    if [ -z "${bodydata}" ]; then
      bodydata="{}"
    fi
    if [ ! -z "${networkid}" ]; then
      networkid='/'"${networkid}"
    fi
    case $action in
    list)
      local_networks "GET" "${bodydata}" ${networkid}
      ;;
    leave)
      local_networks "DELETE" "${bodydata}" ${networkid}
      ;;
    join)
      local_networks "POST" "${bodydata}" ${networkid}
      ;;
    esac
    ;;
  peer)
    local_peer
    ;;
  firewall)
    shift
    local_firewall $1
    ;;
  router)
    shift
    local_router $@
    ;;
  orbit)
    shift
    local_orbit $@
    ;;
  esac
  ;;
central)
  check_apiToken
  shift
  case $1 in
  status)
    remote_status
    ;;
  network)
    shift
    action=$1
    networkid=$2
    bodydata=$3
    if [ -z "${bodydata}" ]; then
      bodydata="{}"
    fi
    if [ ! -z "${networkid}" ]; then
      networkid='/'"${networkid}"
    fi
    case $action in
    list)
      api_networks "GET" "${bodydata}" ${networkid}
      ;;
    remove)
      api_networks "DELETE" "${bodydata}" ${networkid}
      ;;
    add)
      api_networks "POST" "${bodydata}" ""
      ;;
    modify)
      api_networks "POST" "${bodydata}" ${networkid}
      ;;
    esac
    ;;
  member)
    shift
    action=$1
    networkid=$2
    memberID=$3
    bodydata=$4
    if [ -z "${bodydata}" ]; then
      bodydata="{}"
    fi
    if [ ! -z "${memberID}" ]; then
      memberID='/'"${memberID}"
    fi
    case $action in
    list)
      api_members "GET" ${networkid} ${memberID}
      ;;
    remove)
      api_members "DELETE" ${networkid} ${memberID}
      ;;
    modify)
      api_members "POST" ${networkid} ${memberID} "${bodydata}"
      ;;
    esac
    ;;
  esac
  ;;
apiToken)
  shift
  action=$1
  key=$2
  case $action in
  show)
    check_apiToken
    echo "${apiToken}"
    ;;
  update)
    echo "${key}" >${TOKENAUTH}
    echo "done"
    ;;
  esac
  ;;
*)
  help
  ;;
esac
