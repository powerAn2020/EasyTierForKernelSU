#!/system/bin/sh

###
### easytier for KSU - api.sh
###
### Usage:
###   api.sh <api_type> [options]
###
### Options:
###   -h                                            -- Show this message.
###
### Example:
###   help
###     sh api.sh -h
###

MODDIR=${0%/*}
ARCH=$(grep "arch=" /data/adb/modules/easytierForKSU/module.prop | cut -d'=' -f2)

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
CORE_BIN=${ETPATH}/bin/easytier-core
CLI_BIN=${ETPATH}/bin/easytier-cli
WEB_BIN=${ETPATH}/bin/easytier-web
CADDY_BIN=${ETPATH}/bin/caddy
CADDY_CONF=${ETPATH}/conf/Caddyfile

MANUAL=${ETPATH}/MANUAL
KEEP_ON_UNINSTALL=${ETPATH}/KEEP_ON_UNINSTALL
PRIVATE_DEPLOYMENT=${ETPATH}/PRIVATE_DEPLOYMENT
CMDLINE=${ETPATH}/CMDLINE
current_time=$(date +"%I:%M %P")

# apiToken=$(grep -v '^[[:space:]]*$' $TOKENAUTH)

help() {
  sed -rn 's/^### ?//;T;p;' "$0"
}

status_service() {
  // core进程号
  corePid=$(pgrep -f "easytier-core")
  // 卸载保留数据
  uninstallKeep=true
  if [ ! -f "${KEEP_ON_UNINSTALL}" ]; then
    uninstallKeep=false
  fi
  // 开机自启
  autoStart=false
  if [ ! -f "${MANUAL}" ]; then
    autoStart=true
  fi
  // 私有化web部署
  privateDeployment=false
  if [ -f "${PRIVATE_DEPLOYMENT}" ]; then
    // web进程号
    privateDeployment=$(pgrep -f "easytier-web")
  fi
  // 命令行输出
  cliStatus=$(${ETPATH}/bin/easytier-core -V)
  if [ $? != 0 ]; then
    cliStatus=''
  fi
  // 构建返回数据
  data='{"enable":"'${corePid}'","privateDeployment":"'${privateDeployment}'","autoStart":'${autoStart}',"uninstallKeep":'${uninstallKeep}',"version":"'${cliStatus}'"}'
  echo $data
}
start_service() {
  corePid=$(pgrep -f "easytier-core")
  if [ -z $corePid ]; then
    # 启动服务
    echo "starting $CORE_BIN  \c"
    if [ -f ${ETPATH}/state/disable ]; then
      rm ${ETPATH}/state/disable
    fi
    sh ${CMDLINE} &
    zt_rc=$?
    if [ $zt_rc -ne 0 ]; then
      echo "$0: Error ${zt_rc} starting ${CORE_BIN}... bailing."
      exit $zt_rc
    fi
    # 私有化部署启动caddy
    if [ -f "${PRIVATE_DEPLOYMENT}" ]; then
      # 监听配置文件变化并自动重启
      ${CADDY_BIN} --config ${ETPATH}/conf/Caddyfile --watch start
    fi

    sed -Ei "s/^description=(\[.*][[:space:]]*)?/description=[ $current_time | ✔︎ service is running ] /g" $MODDIR/module.prop
  else
    echo "service is running,pid:$corePid"
  fi
}
stop_service() {
  corePid=$(pgrep -f "easytier-core")
  webPid=$(pgrep -f "easytier-web")
  if [ ! -z $webPid ]; then
    kill -9 ${webPid}
  else
    echo "web is stop"
  fi
  if [ -f "${PRIVATE_DEPLOYMENT}" ]; then
    ${CADDY_BIN} stop
  fi
  if [ ! -z $corePid ]; then
    kill -9 ${corePid}
  else
    echo "core is stop"
  fi
}
# 更新
download_and_install() {
  local download_url=$1
  local app_name=$2

  if [ ! -d "${ETPATH}/tmp" ]; then
    mkdir -p "${ETPATH}/tmp"
  fi

  # 下载
  $busybox wget -O "${ETPATH}/tmp/${app_name}" "$download_url"
  # 判断是否下载成功，如果成功则进行解压并移动到 /data/adb/modules/easytierForKSU/bin/
  if [ $? -ne 0 ]; then
    {
      echo "Failed to download $app_name binary."
      exit 1
    }
  else
    # 解压
    if [ "${app_name}" = "caddy" ]; then
      $busybox tar -zxvf "${ETPATH}/tmp/${app_name}" -C "${ETPATH}/tmp/"
      mv -f "${ETPATH}/tmp/${app_name}" "${ETPATH}/bin/"
    elif [ "${app_name}" = "easytier" ]; then
      $busybox unzip "${ETPATH}/tmp/${app_name}" -D "${ETPATH}/tmp/"
      mv -f "${ETPATH}/tmp/easytier-linux-*/*" "${ETPATH}/bin/"
    else
      {
        echo "Unknown app name: $app_name"
        exit 1
      }
    fi
    # 删除临时文件夹的内容
    rm -rf ${ETPATH}/tmp/*
    chmod +x "${ETPATH}/bin/*"
    echo "$app_name updated successfully."
  fi
}
start_inotifyd() {
  PIDs=$(pgrep -f inotifyd)
  for PID in "${PIDs[@]}"; do
    if grep -q "easytier.inotify" "/proc/$PID/cmdline"; then
      kill -9 "$PID"
    fi
  done
  echo "inotifyd ${ETPATH}/state"
  sed -Ei "s/^description=(\[.*][[:space:]]*)?/description=[ $current_time | inotifyd is running ] /g" $MODDIR/module.prop
  inotifyd "${MODDIR}/easytier.inotify" "${ETPATH}/state" >>/dev/null 2>&1 &
}

# =========================== main ===========================
case $1 in
status)
  status_service
  ;;
start)
  start_service
  ;;
stop)
  stop_service
  ;;
restart)
  stop_service
  start_service
  ;;
caddyport)
  shift
  local target_port=$1
  sed -i "s/:[0-9]\+/:$target_port/g" ${CADDY_CONF}
  ;;
upgrade)
  shift
  local type=$1
  if [ -z $type ]; then
    {
      echo "update type is empty,support [caddy,easytier]" 1>&2
      exit 1
    }
  elif [ "$type" = "caddy"]; then
    # 从github获取最新版 caddy 版本号，并下载
    if [ -f "${CADDY_BIN}" ]; then
      ${CADDY_BIN} upgrade
    else
      echo "caddy is not exist, download it"
      # https://github.com/caddyserver/caddy/releases/download/v2.9.1/caddy_2.9.1_linux_arm64.tar.gz.sig
      app_latest_version=$(wget --no-check-certificate -qO- "https://api.github.com/repos/caddyserver/caddy/releases/latest" | grep "tag_name" | grep -oE "[0-9.]*" | head -1)
      app_download_link="https://github.com/caddyserver/caddy/releases/download/${app_latest_version}/caddy_${app_latest_version#*v}_linux_${ARCH}.tar.gz"
      download_and_install ${app_download_link} caddy
    fi
  elif [ "$type" = "easytier"]; then
    # 更新easyTier
    # 从github获取最新版 EasyTier 版本号，并下载
    # https://github.com/EasyTier/EasyTier/releases/download/v2.2.4/easytier-linux-aarch64-v2.2.4.zip
    app_latest_version=$(wget --no-check-certificate -qO- "https://api.github.com/repos/EasyTier/EasyTier/releases/latest" | grep "tag_name" | grep -oE "[0-9.]*" | head -1)
    app_download_link="https://github.com/EasyTier/EasyTier/releases/download/${app_latest_version}/easytier-linux-${ARCH}-${app_latest_version}.zip"
    download_and_install ${app_download_link} easytier
  else
    {
      echo "update type is error,support [caddy,easytier]"
      exit 1
    }
  fi
  ;;
inotifyd)
  start_inotifyd
  ;;
*)
  help
  ;;
esac
