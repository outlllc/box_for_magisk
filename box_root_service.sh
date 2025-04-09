#!/system/bin/sh

(
    until [ $(getprop init.svc.bootanim) = "stopped" ]; do
        sleep 10
    done

    if [ -f "/data/adb/boxroot/scripts/start.sh" ]; then
        chmod 755 /data/adb/boxroot/scripts/*
        /data/adb/boxroot/scripts/start.sh
    else
        echo "File '/data/adb/boxroot/scripts/start.sh' not found"
    fi
)&