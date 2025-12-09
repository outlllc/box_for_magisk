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

delete_op_coloros16_fw_rules() {
    brand=$(getprop ro.product.brand | tr '[:upper:]' '[:lower:]')
    case "$brand" in
        oppo|oneplus|realme|oplus)
            ;;
        *)
            return 0
            ;;
    esac
    sleep 60
    CHAINS="fw_INPUT fw_OUTPUT"
    PROTOS="ipv4 ipv6"
    for proto in $PROTOS; do
        case "$proto" in
            ipv4) cmd="iptables" ;;
            ipv6) cmd="ip6tables" ;;
        esac
        
        for chain in $CHAINS; do
            $cmd -t filter -nL "$chain" >/dev/null 2>&1 || continue
            lines=$($cmd -t filter -nL "$chain" --line-numbers \
                    | grep "REJECT" \
                    | awk '{print $1}' \
                    | sort -rn)
            for line in $lines; do
                [ -n "$line" ] && [ "$line" -gt 0 ] || continue
                $cmd -t filter -D "$chain" "$line" 2>/dev/null
            done
        done
    done
}
delete_op_coloros16_fw_rules &