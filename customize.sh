#!/sbin/sh

# ASH_STANDALONE=1

### INSTALLATION ###

if [ "$BOOTMODE" != true ]; then
  ui_print "-----------------------------------------------------------"
  ui_print "! Please install in Magisk Manager or KernelSU Manager"
  ui_print "! Install from recovery is NOT supported"
  abort "-----------------------------------------------------------"
elif [ "$KSU" = true ] && [ "$KSU_VER_CODE" -lt 11551 ]; then
  abort "ERROR: Please update your KernelSU and KernelSU Manager"
fi

ui_print "OS ARCH is $ARCH"

# check version
if [ "$KSU" = true ]; then
  ui_print "- kernelSU version: $KSU_VER ($KSU_VER_CODE)"
else
  ui_print "- Magisk version: $MAGISK_VER ($MAGISK_VER_CODE)"
fi

ui_print "- Installing easytier for KSU"

if [ ! -d "/data/adb/easytier" ]; then
  mkdir -p /data/adb/easytier/state
  set_perm /data/adb/easytier 0 0 0755
  set_perm /data/adb/easytier/state 0 0 0755
fi

ui_print "- Setting permissions"
set_perm_recursive $MODPATH 0 0 0755 0644

ui_print "- Installation is complete, reboot your device"
