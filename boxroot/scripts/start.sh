#!/system/bin/sh
# Validate settings.ini
if ! /system/bin/sh -n /data/adb/boxroot/settings.ini 2>"/data/adb/boxroot/run/settings_err.log"; then
  echo "Err: settings.ini contains a syntax error" | tee -a "/data/adb/boxroot/run/settings_err.log"
  exit 1
fi

scripts_dir="${0%/*}"
file_settings="/data/adb/boxroot/settings.ini"
moddir="/data/adb/modules/box_root"

# busybox Magisk/KSU/Apatch
busybox="/data/adb/magisk/busybox"
[ -f "/data/adb/ksu/bin/busybox" ] && busybox="/data/adb/ksu/bin/busybox"
[ -f "/data/adb/ap/bin/busybox" ] && busybox="/data/adb/ap/bin/busybox"

wait_for_data_ready() {
  while [ ! -f "/data/system/packages.xml" ] ; do
    sleep 1
  done
}

refresh_box() {
  if [ -f "/data/adb/boxroot/run/box.pid" ]; then
    "${scripts_dir}/box.service" stop > "/dev/null" 2>&1
    "${scripts_dir}/box.iptables" disable > "/dev/null" 2>&1
  fi
}

start_service() {
  if [ ! -f "${moddir}/disable" ]; then
    "${scripts_dir}/box.service" start > "/dev/null" 2>&1
  fi
}

enable_iptables() {
  PIDS=("clash" "xray" "sing-box" "v2fly")
  PID=""
  i=0
  while [ -z "$PID" ] && [ "$i" -lt "${#PIDS[@]}" ]; do
    PID=$($busybox pidof "${PIDS[$i]}")
    i=$((i+1))
  done

  if [ -n "$PID" ]; then
    "${scripts_dir}/box.iptables" enable > "/dev/null" 2>&1
  fi
}

net_inotifyd() {
  net_dir="/data/misc/net"
  ctr_dir="/data/misc/net/rt_tables"

  # Start inotifyd to watch for network-related changes.
  # - The /proc filesystem cannot be monitored with inotify.
  # - Polling in a loop is inefficient, so inotify is used instead.
  # - Here we monitor /data/misc/net and /data/misc/net/rt_tables
  #   because they reflect changes in routing tables and interfaces.

  # Wait until at least one of the target files/directories exists
  while [ ! -f "$ctr_dir" ] && [ ! -f "$net_dir" ]; do
      sleep 3
  done

  # Launch inotifyd handlers in the background
  inotifyd "${scripts_dir}/ctr.inotify" "$ctr_dir" >/dev/null 2>&1 &
  inotifyd "${scripts_dir}/net.inotify" "$net_dir" >/dev/null 2>&1 &
}

start_inotifyd() {
  PIDs=($($busybox pidof inotifyd))
  for PID in "${PIDs[@]}"; do
    if grep -q -e "box.inotify" -e "net.inotify" "/proc/$PID/cmdline"; then
      kill -9 "$PID"
    fi
    # if grep -q "box.inotify" "/proc/$PID/cmdline"; then
      # kill -9 "$PID"
    # fi
  done
  inotifyd "${scripts_dir}/box.inotify" "${moddir}" > "/dev/null" 2>&1 &
  net_inotifyd
}

mkdir -p /data/adb/boxroot/run/
if [ -f "/data/adb/boxroot/manual" ]; then
  if [ -f "/data/adb/boxroot/run/box.pid" ]; then
      rm -rf /data/adb/boxroot/run/box.pid
  fi
  net_inotifyd
  exit 1
fi

if [ -f "$file_settings" ] && [ -r "$file_settings" ] && [ -s "$file_settings" ]; then
  wait_for_data_ready
  refresh_box
  start_service
  enable_iptables
fi

start_inotifyd
