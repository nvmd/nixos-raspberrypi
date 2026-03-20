# Network sysctl tuning for Raspberry Pi installer images.
#
# References:
#   https://www.kernel.org/doc/html/latest/networking/ip-sysctl.html
#   https://www.l4sgear.com/
{ config, pkgs, ... }:

{
  boot.kernel.sysctl = {
    # Detect dead connections more quickly
    # Default: 75s interval, 9 probes, 7200s keepalive = ~11 min detection
    # Tuned:  30s interval, 4 probes, 120s keepalive  = ~2 min detection
    "net.ipv4.tcp_keepalive_intvl" = 30;
    "net.ipv4.tcp_keepalive_probes" = 4;
    "net.ipv4.tcp_keepalive_time" = 120;

    # Larger TCP buffer sizes (default: 4096 131072 6291456)
    "net.ipv4.tcp_rmem" = "4096    1000000    16000000";
    "net.ipv4.tcp_wmem" = "4096    1000000    16000000";
    "net.ipv6.tcp_rmem" = "4096    1000000    16000000";
    "net.ipv6.tcp_wmem" = "4096    1000000    16000000";

    # https://lwn.net/Articles/560082/
    "net.ipv4.tcp_notsent_lowat" = "131072";

    # Enable reuse of TIME-WAIT sockets globally
    "net.ipv4.tcp_tw_reuse" = 1;
    "net.ipv4.tcp_timestamps" = 1;
    "net.ipv4.tcp_ecn" = 1;
    "net.core.default_qdisc" = "cake";
    "net.ipv4.tcp_congestion_control" = "cubic";

    # Larger socket buffer defaults (default: 212992)
    "net.core.rmem_default" = 26214400;
    "net.core.rmem_max" = 26214400;
    "net.core.wmem_default" = 26214400;
    "net.core.wmem_max" = 26214400;

    # Wider ephemeral port range (default: 32768-60999)
    "net.ipv4.ip_local_port_range" = "1026 65535";

    # Save slow start threshold in route cache
    "net.ipv4.tcp_no_ssthresh_metrics_save" = 0;
    "net.ipv4.tcp_reflect_tos" = 1;
    #"net.ipv4.tcp_rto_min_us" = 50000; # 50ms (default: 200ms)

    # TCP performance optimizations
    "net.ipv4.tcp_slow_start_after_idle" = 1;
    "net.ipv4.tcp_fastopen" = 3;
    "net.ipv4.tcp_window_scaling" = 1;
    "net.ipv4.tcp_sack" = 1;
    "net.ipv4.tcp_fack" = 1;
    "net.ipv4.tcp_fin_timeout" = 30;
  };
}
