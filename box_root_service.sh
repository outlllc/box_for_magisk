#!/system/bin/sh

(
    until [ "$(getprop init.svc.bootanim)" = "stopped" ]; do
        sleep 10
    done

    if [ -f "/data/adb/boxroot/scripts/start.sh" ]; then
        chmod -R 755 /data/adb/boxroot/scripts/
        /data/adb/boxroot/scripts/start.sh >/dev/null 2>&1
    else
        echo "File /data/adb/boxroot/scripts/start.sh not found" > "/data/adb/boxroot/run/box_service.log"
    fi
) &