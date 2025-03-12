#!/system/bin/sh

if [ ! -f "/data/adb/easytier/KEEP_ON_UNINSTALL" ]; then
  rm -rf /data/adb/easytier
fi
