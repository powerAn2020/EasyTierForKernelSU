#!/system/bin/sh
MODDIR=${0%/*}
ETPATH=/data/adb/easytier
TOKENAUTH=$ETPATH/TOKENAUTH

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
(
    until [ $(getprop init.svc.bootanim) = "stopped" ]; do
        sleep 10
    done
    if [ ! -f "${TOKENAUTH}" ]; then
      touch $TOKENAUTH
    fi
    ${MODDIR}/easytier.sh inotifyd
    # inotifyd "${MODDIR}/build.inotify" "/sdcard/Download/dist" &
    if [ ! -f "${MANUAL}" ]; then
      sh ${MODDIR}/easytier.sh start
    else
      touch ${ETPATH}/state/disable
    fi
  
)&