#!/system/vendor/bin/sh
# Copyright (c) 2012-2015, The Linux Foundation. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * Neither the name of The Linux Foundation nor
#       the names of its contributors may be used to endorse or promote
#       products derived from this software without specific prior written
#       permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NON-INFRINGEMENT ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
# OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
# OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

#
# QCOM post-boot power configuration script
#

# HMP scheduler settings for 8929, 8939, 8939v3
echo 3 > /proc/sys/kernel/sched_window_stats_policy
echo 20 > /proc/sys/kernel/sched_small_task
echo 1 > /proc/sys/kernel/sched_migration_fixup
echo 9 > /proc/sys/kernel/sched_upmigrate_min_nice
echo 30 > /proc/sys/kernel/sched_mostly_idle_load
echo 3 > /proc/sys/kernel/sched_mostly_idle_nr_run

# cpu idle load threshold
echo 30 > /sys/devices/system/cpu/cpu0/sched_mostly_idle_load
echo 30 > /sys/devices/system/cpu/cpu1/sched_mostly_idle_load
echo 30 > /sys/devices/system/cpu/cpu2/sched_mostly_idle_load
echo 30 > /sys/devices/system/cpu/cpu3/sched_mostly_idle_load
echo 30 > /sys/devices/system/cpu/cpu4/sched_mostly_idle_load
echo 30 > /sys/devices/system/cpu/cpu5/sched_mostly_idle_load
echo 30 > /sys/devices/system/cpu/cpu6/sched_mostly_idle_load
echo 30 > /sys/devices/system/cpu/cpu7/sched_mostly_idle_load

# cpu idle nr run threshold
echo 3 > /sys/devices/system/cpu/cpu0/sched_mostly_idle_nr_run
echo 3 > /sys/devices/system/cpu/cpu1/sched_mostly_idle_nr_run
echo 3 > /sys/devices/system/cpu/cpu2/sched_mostly_idle_nr_run
echo 3 > /sys/devices/system/cpu/cpu3/sched_mostly_idle_nr_run
echo 3 > /sys/devices/system/cpu/cpu4/sched_mostly_idle_nr_run
echo 3 > /sys/devices/system/cpu/cpu5/sched_mostly_idle_nr_run
echo 3 > /sys/devices/system/cpu/cpu6/sched_mostly_idle_nr_run
echo 3 > /sys/devices/system/cpu/cpu7/sched_mostly_idle_nr_run

# enable low power modes
echo 0 > /sys/module/lpm_levels/parameters/sleep_disabled

# RPS mask
echo 10 > /sys/class/net/rmnet0/queues/rx-0/rps_cpus

# disable sched_boost
echo 0 > /proc/sys/kernel/sched_boost

# change initial GPU power level from 400 MHz to 200 Mhz
echo 3 > /sys/class/kgsl/kgsl-3d0/default_pwrlevel

# configure devfreq gov
echo "bw_hwmon" > /sys/class/devfreq/cpubw/governor
echo 20 > /sys/class/devfreq/cpubw/bw_hwmon/io_percent
echo 40 > /sys/class/devfreq/gpubw/bw_hwmon/io_percent
echo "cpufreq" /sys/class/devfreq/mincpubw/governor

# disable thermal core_control to update interactive gov settings
echo 0 > /sys/module/msm_thermal/core_control/enabled

if [ `cat /sys/devices/soc0/revision` != "3.0" ]; then
    # Apply MSM8929 and MSM8939 specific Sched & Governor settings

    # HMP scheduler settings
    echo 5 > /proc/sys/kernel/sched_ravg_hist_size
    echo 75 > /proc/sys/kernel/sched_upmigrate
    echo 60 > /proc/sys/kernel/sched_downmigrate

    # enable governor for perf cluster
    echo 1 > /sys/devices/system/cpu/cpu0/online
    echo "interactive" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
    echo "20000 400000:27000 800000:40000 960000:50000 1113600:65000" > /sys/devices/system/cpu/cpu0/cpufreq/interactive/above_hispeed_delay
    echo 97 > /sys/devices/system/cpu/cpu0/cpufreq/interactive/go_hispeed_load
    echo 20000 > /sys/devices/system/cpu/cpu0/cpufreq/interactive/timer_rate
    echo 998400 > /sys/devices/system/cpu/cpu0/cpufreq/interactive/hispeed_freq
    echo 0 > /sys/devices/system/cpu/cpu0/cpufreq/interactive/io_is_busy
    echo "49 400000:50 800000:65 960000:85 1113600:95" > /sys/devices/system/cpu/cpu0/cpufreq/interactive/target_loads
    echo 50000 > /sys/devices/system/cpu/cpu0/cpufreq/interactive/min_sample_time
    echo 50000 > /sys/devices/system/cpu/cpu0/cpufreq/interactive/sampling_down_factor
    echo 200000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq
    echo 1113600 > /sys/devices/system/cpu/cpu4/cpufreq/scaling_max_freq
    echo 1 > /sys/devices/system/cpu/cpu0/cpufreq/interactive/powersave_bias

    # enable governor for power cluster
    echo 1 > /sys/devices/system/cpu/cpu4/online
    echo "interactive" > /sys/devices/system/cpu/cpu4/cpufreq/scaling_governor
    echo "25000 800000:50000" > /sys/devices/system/cpu/cpu4/cpufreq/interactive/above_hispeed_delay
    echo 90 > /sys/devices/system/cpu/cpu4/cpufreq/interactive/go_hispeed_load
    echo 40000 > /sys/devices/system/cpu/cpu4/cpufreq/interactive/timer_rate
    echo 800000 > /sys/devices/system/cpu/cpu4/cpufreq/interactive/hispeed_freq
    echo 0 > /sys/devices/system/cpu/cpu4/cpufreq/interactive/io_is_busy
    echo "39 499200:50 533330:70 800000:90" > /sys/devices/system/cpu/cpu4/cpufreq/interactive/target_loads
    echo 40000 > /sys/devices/system/cpu/cpu4/cpufreq/interactive/min_sample_time
    echo 40000 > /sys/devices/system/cpu/cpu4/cpufreq/interactive/sampling_down_factor
    echo 200000 > /sys/devices/system/cpu/cpu4/cpufreq/scaling_min_freq
    echo 800000 > /sys/devices/system/cpu/cpu4/cpufreq/scaling_max_freq
    echo 1 > /sys/devices/system/cpu/cpu4/cpufreq/interactive/powersave_bias
else
    # Apply 3.0 specific Sched & Governor settings
    # HMP scheduler settings for 8939 V3.0
    echo 3 > /proc/sys/kernel/sched_ravg_hist_size
    echo 20000000 > /proc/sys/kernel/sched_ravg_window
    echo 93 > /proc/sys/kernel/sched_upmigrate
    echo 83 > /proc/sys/kernel/sched_downmigrate
    echo 20 > /proc/sys/kernel/sched_small_task
    echo 0 > /proc/sys/kernel/sched_prefer_idle

    # enable governor for perf cluster
    echo 1 > /sys/devices/system/cpu/cpu0/online
    echo "interactive" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
    echo "19000 400000:25000 800000:39000 960000:50000 1113600:60000" > /sys/devices/system/cpu/cpu0/cpufreq/interactive/above_hispeed_delay
    echo 97 > /sys/devices/system/cpu/cpu0/cpufreq/interactive/go_hispeed_load
    echo 20000 > /sys/devices/system/cpu/cpu0/cpufreq/interactive/timer_rate
    echo 998400 > /sys/devices/system/cpu/cpu0/cpufreq/interactive/hispeed_freq
    echo 0 > /sys/devices/system/cpu/cpu0/cpufreq/interactive/io_is_busy
    echo "39 400000:40 800000:60 960000:85 1113600:90 1344000:95" > /sys/devices/system/cpu/cpu0/cpufreq/interactive/target_loads
    echo 40000 > /sys/devices/system/cpu/cpu0/cpufreq/interactive/min_sample_time
    echo 40000 > /sys/devices/system/cpu/cpu0/cpufreq/interactive/sampling_down_factor
    echo 200000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq
    echo 1344000 > /sys/devices/system/cpu/cpu4/cpufreq/scaling_max_freq
    echo 1 > /sys/devices/system/cpu/cpu0/cpufreq/interactive/powersave_bias

    # enable governor for power cluster
    echo 1 > /sys/devices/system/cpu/cpu4/online
    echo "interactive" > /sys/devices/system/cpu/cpu4/cpufreq/scaling_governor
    echo 39000 > /sys/devices/system/cpu/cpu4/cpufreq/interactive/above_hispeed_delay
    echo 90 > /sys/devices/system/cpu/cpu4/cpufreq/interactive/go_hispeed_load
    echo 20000 > /sys/devices/system/cpu/cpu4/cpufreq/interactive/timer_rate
    echo 800000 > /sys/devices/system/cpu/cpu4/cpufreq/interactive/hispeed_freq
    echo 0 > /sys/devices/system/cpu/cpu4/cpufreq/interactive/io_is_busy
    echo "34 499200:35 533330:60 800000:85 998400:90" > /sys/devices/system/cpu/cpu4/cpufreq/interactive/target_loads
    echo 40000 > /sys/devices/system/cpu/cpu4/cpufreq/interactive/min_sample_time
    echo 40000 > /sys/devices/system/cpu/cpu4/cpufreq/interactive/sampling_down_factor
    echo 200000 > /sys/devices/system/cpu/cpu4/cpufreq/scaling_min_freq
    echo 998400 > /sys/devices/system/cpu/cpu4/cpufreq/scaling_max_freq
    echo 1 > /sys/devices/system/cpu/cpu4/cpufreq/interactive/powersave_bias

    # enable sched guided freq control
    echo 1 > /sys/devices/system/cpu/cpu0/cpufreq/interactive/use_sched_load
    echo 1 > /sys/devices/system/cpu/cpu0/cpufreq/interactive/use_migration_notif
    echo 1 > /sys/devices/system/cpu/cpu4/cpufreq/interactive/use_sched_load
    echo 1 > /sys/devices/system/cpu/cpu4/cpufreq/interactive/use_migration_notif
    echo 50000 > /proc/sys/kernel/sched_freq_inc_notify
    echo 50000 > /proc/sys/kernel/sched_freq_dec_notify

    # enable dynamic clock gating
    echo 1 > /sys/module/lpm_levels/lpm_workarounds/dynamic_clock_gating
fi

# enable thermal core_control now
echo 1 > /sys/module/msm_thermal/core_control/enabled

# bring up all cores online
echo 1 > /sys/devices/system/cpu/cpu1/online
echo 1 > /sys/devices/system/cpu/cpu2/online
echo 1 > /sys/devices/system/cpu/cpu3/online
echo 1 > /sys/devices/system/cpu/cpu4/online
echo 1 > /sys/devices/system/cpu/cpu5/online
echo 1 > /sys/devices/system/cpu/cpu6/online
echo 1 > /sys/devices/system/cpu/cpu7/online

# enable core control
echo 0 > /sys/devices/system/cpu/cpu0/core_ctl/min_cpus
echo 4 > /sys/devices/system/cpu/cpu0/core_ctl/max_cpus
echo 68 > /sys/devices/system/cpu/cpu0/core_ctl/busy_up_thres
echo 40 > /sys/devices/system/cpu/cpu0/core_ctl/busy_down_thres
echo 100 > /sys/devices/system/cpu/cpu0/core_ctl/offline_delay_ms
echo 4 > /sys/devices/system/cpu/cpu0/core_ctl/task_thres
echo 1 > /sys/devices/system/cpu/cpu0/core_ctl/is_big_cluster
echo 0 > /sys/devices/system/cpu/cpu4/core_ctl/min_cpus
echo 20 > /sys/devices/system/cpu/cpu4/core_ctl/busy_up_thres
echo 5 > /sys/devices/system/cpu/cpu4/core_ctl/busy_down_thres
echo 5000 > /sys/devices/system/cpu/cpu4/core_ctl/offline_delay_ms
echo 1 > /sys/devices/system/cpu/cpu4/core_ctl/not_preferred

