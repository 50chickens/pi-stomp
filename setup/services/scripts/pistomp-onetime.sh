set_scaling_governor () {

scaling_governor_file="/sys/devices/system/cpu/cpu*/cpufreq/scaling_governor"
if [ ! -f $scaling_governor_file ]; then
    echo "$scaling_governor_file not found. Ignoring."
    exit 0
fi
scaling_governor=$(cat $scaling_governor_file | head -1)
bash -c "echo performance | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor"
}

restore_alsa_configuration() {
    if [ ! -f /var/lib/alsa/asound.state ]; then
        echo "/var/lib/alsa/asound.state not found. Ignoring."
        exit 0
    fi
    echo "Restoring ALSA configuration from /var/lib/alsa/asound.state"
    alsactl restore -f /var/lib/alsa/asound.state
}
set_scaling_governor
restore_alsa_configuration