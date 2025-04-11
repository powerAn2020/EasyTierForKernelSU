#!/system/bin/sh
MODDIR=${0%/*}
ETPATH=/data/adb/easytier

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

MANUAL=${ETPATH}/MANUAL
(
  until [ $(getprop init.svc.bootanim) = "stopped" ]; do
    sleep 10
  done

  ${MODDIR}/api.sh inotifyd
  # inotifyd "${MODDIR}/build.inotify" "/sdcard/Download/dist" &
  if [ ! -f "${MANUAL}" ]; then
    sh ${MODDIR}/api.sh start
  else
    touch ${ETPATH}/state/disable
  fi

) &
