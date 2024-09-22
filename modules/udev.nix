{ config, lib, pkgs, ... }:

{
  services.udev.extraRules = let
    sh = "${pkgs.bash}/bin/sh";  # /bin/sh
    grep = "${lib.getExe pkgs.gnugrep}"; # /bin/grep
    chgrp = "chgrp";  # /bin/chgrp
    chmod = "chmod";  # /bin/chmod
    test = "${pkgs.coreutils}/bin/test";  # /usr/bin/test
  in ''
    # https://github.com/RPi-Distro/raspberrypi-sys-mods/blob/bookworm/lib/udev/rules.d/10-vc.rules
    KERNEL=="vcio", GROUP="video", MODE="0660"
    KERNEL=="vchiq", GROUP="video", MODE="0660"
    SUBSYSTEM=="vc-sm", GROUP="video", MODE="0660"
    KERNEL=="vcsm-cma", GROUP="video", MODE="0660"


    # https://github.com/RPi-Distro/raspberrypi-sys-mods/blob/bookworm/lib/udev/rules.d/15-i2c-modprobe.rules
    # https://github.com/RPi-Distro/raspberrypi-sys-mods/commit/5582ff9ed61c429cf700a0beca2a2af3afcbab04
    # SUBSYSTEM=="i2c|spi", ENV{MODALIAS}=="?*", ENV{OF_NAME}=="?*", ENV{OF_COMPATIBLE_0}=="?*", RUN+="/usr/lib/raspberrypi-sys-mods/i2cprobe"


    # https://github.com/RPi-Distro/raspberrypi-sys-mods/blob/bookworm/lib/udev/rules.d/60-backlight.rules
    # SUBSYSTEM=="backlight", ACTION=="add", RUN+="${chgrp} video $sys$devpath/brightness", RUN+="${chmod} g+w $sys$devpath/brightness"


    # https://github.com/RPi-Distro/raspberrypi-sys-mods/blob/bookworm/lib/udev/rules.d/60-dma-heap.rules
    SUBSYSTEM=="dma_heap", GROUP="video", MODE="0660"
    SUBSYSTEM=="dma_heap", KERNEL=="system", PROGRAM="${grep} -q \"^Revision\s*:\s*[ 123][0-9a-fA-F][0-9a-fA-F]4[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]$$\" /proc/cpuinfo", SYMLINK+="dma_heap/vidbuf_cached"
    SUBSYSTEM=="dma_heap", KERNEL=="linux,cma", SYMLINK+="dma_heap/vidbuf_cached", OPTIONS+="link_priority=-50"


    # https://github.com/RPi-Distro/raspberrypi-sys-mods/blob/bookworm/lib/udev/rules.d/60-gpiochip4.rules
    SUBSYSTEM=="gpio", KERNEL=="gpiochip0", PROGRAM="${test} ! -c /dev/gpiochip4", SYMLINK+="gpiochip4"


    # https://github.com/RPi-Distro/raspberrypi-sys-mods/blob/bookworm/lib/udev/rules.d/60-pico.rules
    ATTRS{manufacturer}=="Raspberry Pi", MODE="660", GROUP="plugdev", TAG+="uaccess"


    # https://github.com/RPi-Distro/raspberrypi-sys-mods/blob/bookworm/lib/udev/rules.d/70-microbit.rules
    SUBSYSTEM=="usb", ATTR{idVendor}=="0d28", TAG+="uaccess"


    # https://github.com/RPi-Distro/raspberrypi-sys-mods/blob/bookworm/etc.armhf/udev/rules.d/99-com.rules
    SUBSYSTEM=="input", GROUP="input", MODE="0660"
    SUBSYSTEM=="i2c-dev", GROUP="i2c", MODE="0660"
    SUBSYSTEM=="spidev", GROUP="spi", MODE="0660"
    SUBSYSTEM=="*gpiomem*", GROUP="gpio", MODE="0660"
    SUBSYSTEM=="rpivid-*", GROUP="video", MODE="0660"

    SUBSYSTEM=="gpio", GROUP="gpio", MODE="0660"
    SUBSYSTEM=="gpio", KERNEL=="gpiochip*", ACTION=="add", PROGRAM="${sh} -c 'chgrp -R gpio /sys/class/gpio && chmod -R g=u /sys/class/gpio'"
    SUBSYSTEM=="gpio", ACTION=="add", PROGRAM="${sh} -c 'chgrp -R gpio /sys%p && chmod -R g=u /sys%p'"

    # PWM export results in a "change" action on the pwmchip device (not "add" of a new device), so match actions other than "remove".
    SUBSYSTEM=="pwm", ACTION!="remove", PROGRAM="${sh} -c 'chgrp -R gpio /sys%p && chmod -R g=u /sys%p'"

    KERNEL=="ttyAMA[0-9]*|ttyS[0-9]*", PROGRAM="${sh} -c '\
            ALIASES=/proc/device-tree/aliases; \
            TTYNODE=$$(readlink /sys/class/tty/%k/device/of_node | sed 's/base/:/' | cut -d: -f2); \
            if [ -e $$ALIASES/bluetooth ] && [ $$TTYNODE/bluetooth = $$(strings $$ALIASES/bluetooth) ]; then \
                echo 1; \
            elif [ -e $$ALIASES/console ]; then \
                if [ $$TTYNODE = $$(strings $$ALIASES/console) ]; then \
                    echo 0;\
                else \
                    exit 1; \
                fi \
            elif [ $$TTYNODE = $$(strings $$ALIASES/serial0) ]; then \
                echo 0; \
            elif [ $$TTYNODE = $$(strings $$ALIASES/serial1) ]; then \
                echo 1; \
            else \
                exit 1; \
            fi \
    '", SYMLINK+="serial%c"

    ACTION=="add", SUBSYSTEM=="vtconsole", KERNEL=="vtcon1", RUN+="${sh} -c '\
      if echo RPi-Sense FB | cmp -s /sys/class/graphics/fb0/name; then \
        echo 0 > /sys$devpath/bind; \
      fi; \
    '"

  '';
}