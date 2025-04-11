#!/sbin/sh

# ASH_STANDALONE=1
ETPATH=/data/adb/easytier
### INSTALLATION ###

if [ "$BOOTMODE" != true ]; then
  ui_print "-----------------------------------------------------------"
  ui_print "! Please install in Magisk Manager or KernelSU Manager"
  ui_print "! Install from recovery is NOT supported"
  abort "-----------------------------------------------------------"
elif [ "$KSU" = true ] && [ "$KSU_VER_CODE" -lt 11551 ]; then
  abort "ERROR: Please update your KernelSU and KernelSU Manager"
fi

# 检查架构
ui_print "OS ARCH is $ARCH"
# ARCH (string): 设备的 CPU 架构。值为 arm 、arm64 、x86 或 x64
# 缓存到prop中用于后续更新判断
echo "arch=${ARCH}"

# check version
if [ "$KSU" = true ]; then
  ui_print "- kernelSU version: $KSU_VER ($KSU_VER_CODE)"
else
  ui_print "- Magisk version: $MAGISK_VER ($MAGISK_VER_CODE)"
fi

ui_print "- Installing easytier for KSU"

if [ ! -d "${ETPATH}" ]; then
  mkdir -p ${ETPATH}/{state,logs,conf,bin}
  mv $MODPATH/Caddyfile ${ETPATH}/conf
fi

ui_print "- Setting permissions"
set_perm_recursive $MODPATH 0 0 0755 0644
set_perm_recursive ${ETPATH} 0 0 0755 0644
ui_print "- Installation is complete, reboot your device"
