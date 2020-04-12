/*
   Copyright (c) 2014, The Linux Foundation. All rights reserved.

   Redistribution and use in source and binary forms, with or without
   modification, are permitted provided that the following conditions are
   met:
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above
      copyright notice, this list of conditions and the following
      disclaimer in the documentation and/or other materials provided
      with the distribution.
    * Neither the name of The Linux Foundation nor the names of its
      contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.

   THIS SOFTWARE IS PROVIDED "AS IS" AND ANY EXPRESS OR IMPLIED
   WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
   MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT
   ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS
   BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
   CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
   SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
   BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
   WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
   OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
   IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#define _REALLY_INCLUDE_SYS__SYSTEM_PROPERTIES_H_
#include <sys/_system_properties.h>
#include <stdio.h>
#include <stdlib.h>

#include <android-base/properties.h>
#include <android-base/file.h>
#include <android-base/strings.h>

#include "property_service.h"
#include "vendor_init.h"

using android::init::property_set;
using android::base::ReadFileToString;
using android::base::Trim;
using android::base::GetProperty;

#define ISMATCH(a,b) (!strncmp(a,b,PROP_VALUE_MAX))
#define CMDLINE_SIZE 1024

static void init_alarm_boot_properties()
{
    char const *boot_reason_file = "/proc/sys/kernel/boot_reason";
    std::string boot_reason;
    std::string alarm_boot = GetProperty("ro.boot.alarmboot","");

    if (ReadFileToString(boot_reason_file, &boot_reason)) {
        /*
         * Setup ro.alarm_boot value to true when it is RTC triggered boot up
         * For existing PMIC chips, the following mapping applies
         * for the value of boot_reason:
         *
         * 0 -> unknown
         * 1 -> hard reset
         * 2 -> sudden momentary power loss (SMPL)
         * 3 -> real time clock (RTC)
         * 4 -> DC charger inserted
         * 5 -> USB charger insertd
         * 6 -> PON1 pin toggled (for secondary PMICs)
         * 7 -> CBLPWR_N pin toggled (for external power supply)
         * 8 -> KPDPWR_N pin toggled (power key pressed)
         */
        if (Trim(boot_reason) == "3" || alarm_boot == "true")
            property_set("ro.vendor.alarm_boot", "true");
        else
            property_set("ro.vendor.alarm_boot", "false");
    }
}

void property_override(std::string prop, std::string value)
{
    auto pi = (prop_info*) __system_property_find(prop.c_str());

    if (pi != nullptr)
        __system_property_update(pi, value.c_str(), value.size());
    else
        __system_property_add(prop.c_str(), prop.size(), value.c_str(), value.size());
}

void configure_variant(bool fhd, bool dualsim = true, bool is3gb = false){
    if (fhd) {
        // 1080p screen density
        property_set("ro.sf.lcd_density", "450");

        if (is3gb) {
            /* Dalvik properties for 1080p/3GB
             *
             * https://github.com/CyanogenMod/android_frameworks_native/blob/cm-14.1/build/phone-xxhdpi-3072-dalvik-heap.mk
             */
            property_set("dalvik.vm.heapstartsize", "8m");
            property_set("dalvik.vm.heapgrowthlimit", "288m");
            property_set("dalvik.vm.heapsize", "768m");
            property_set("dalvik.vm.heaptargetutilization", "0.75");
            property_set("dalvik.vm.heapminfree", "512k");
            property_set("dalvik.vm.heapmaxfree", "8m");

            // Cached apps limit
            property_set("ro.vendor.qti.sys.fw.bg_apps_limit", "38");

            // Trim memory
            property_set("ro.vendor.qti.sys.fw.trim_enable_memory", "2147483648");
        } else {
            /* Dalvik properties for 1080p/2GB
             *
             * https://github.com/CyanogenMod/android_frameworks_native/blob/cm-14.1/build/phone-xxhdpi-2048-dalvik-heap.mk
             */
            property_set("dalvik.vm.heapstartsize", "16m");
            property_set("dalvik.vm.heapgrowthlimit", "192m");
            property_set("dalvik.vm.heapsize", "512m");
            property_set("dalvik.vm.heaptargetutilization", "0.75");
            property_set("dalvik.vm.heapminfree", "2m");
            property_set("dalvik.vm.heapmaxfree", "8m");

            // Cached apps limit
            property_set("ro.vendor.qti.sys.fw.bg_apps_limit", "24");

            // Reduce memory footprint
            property_set("ro.config.avoid_gfx_accel", "true");
        }
    } else {
        // 720p screen density
        property_set("ro.sf.lcd_density", "300");

        /* Dalvik properties for 720p/2GB
         *
         * https://github.com/CyanogenMod/android_frameworks_native/blob/cm-14.1/build/phone-xhdpi-2048-dalvik-heap.mk
         */
        property_set("dalvik.vm.heapstartsize", "8m");
        property_set("dalvik.vm.heapgrowthlimit", "192m");
        property_set("dalvik.vm.heapsize", "512m");
        property_set("dalvik.vm.heaptargetutilization", "0.75");
        property_set("dalvik.vm.heapminfree", "512k");
        property_set("dalvik.vm.heapmaxfree", "8m");

        // Cached apps limit
        property_set("ro.vendor.qti.sys.fw.bg_apps_limit", "26");

        // Reduce memory footprint
        property_set("ro.config.avoid_gfx_accel", "true");
    }

    if (dualsim) {
        property_set("persist.radio.multisim.config", "dsds");
        property_set("ro.telephony.default_network", "9,9");
    } else {
        property_set("ro.telephony.default_network", "9");
    }
}

void vendor_load_properties()
{
    // Parse /proc/cmdline to obtain board and panel version
    char cmdline_buff[CMDLINE_SIZE];
    char board_id[32];
    char panel_id[32];

    FILE *cmdline = fopen("/proc/cmdline", "r");
    fgets(cmdline_buff, CMDLINE_SIZE, cmdline);
    fclose(cmdline);

    char *boardindex = strstr(cmdline_buff, "board_id=");
    char *panelindex = strstr(cmdline_buff, "panel=");
    strncpy(board_id, strtok(boardindex + 9, ":"), 32);
    strncpy(panel_id, strtok(panelindex + 28, ":"), 32);

    // Use A6020a40 as default - SD415/2GB/720p - board_id = "S82918D1"
    std::string device = "A6020a40";
    std::string fingerprint = "Lenovo/A6020a40/A6020a40:5.1.1/LMY47V/A6020a40_S102_161123_ROW:user/release-keys";

    // Determine variant and fingerprint
    if (ISMATCH(board_id, "S82918B1")) {
        if (ISMATCH(panel_id, "ili9881c_720p_video") || ISMATCH(panel_id, "hx8394f_boe_720p_video")) {
            // HW39 variant - SD616/2GB/720p
            device = "A6020a40";
            fingerprint = "Lenovo/A6020a40/A6020a40:5.1.1/LMY47V/A6020a40_S105_161128_ROW:user/release-keys";
            configure_variant(false); // 720p
        } else {
            // SD616/2GB/1080p, panel_id = "otm1901a_tm_1080p_video"
            device = "A6020a46";
            fingerprint = "Lenovo/A6020a46/A6020a46:5.1.1/LMY47V/A6020a46_S042_160516_ROW:user/release-keys";
            configure_variant(true); // 1080p
        }
    } else if (ISMATCH(board_id, "S82918E1")) {
        // SD415/2GB/720p, single SIM
        device = "A6020a41";
        fingerprint = "Lenovo/A6020a41/A6020a41:5.1.1/LMY47V/A6020a41_S_S028_160922_ROW:user/release-keys";
        configure_variant(false, false);
    } else if (ISMATCH(board_id, "S82918F1")) {
        // SD616/2GB/1080p, Latin America
        device = "A6020l36";
        fingerprint = "Lenovo/A6020l36/A6020l36:5.1.1/LMY47V/A6020l36_S042_161209_LAS:user/release-keys";
        configure_variant(true);
    } else if (ISMATCH(board_id, "S82918G1")) {
        // SD616/2GB/1080p, single SIM, Latin America
        device = "A6020l37";
        fingerprint = "Lenovo/A6020l37/A6020l37:5.1.1/LMY47V/A6020l37_S029_170321_LAS:user/release-keys";
        configure_variant(true, false);
    } else if (ISMATCH(board_id, "S82918H1")) {
        // SD616/3GB/1080p
        device = "A6020a46";
        fingerprint = "Lenovo/A6020a46/A6020a46:5.1.1/LMY47V/A6020a46_S105_161124_ROW:user/release-keys";
        configure_variant(true, true, true);
    } else {
        // Default to A6020a40 - SD415/2GB/720p - board_id = "S82918D1"
        configure_variant(false);
    }

    // Override 'em all props
    std::string model = "Lenovo " + device;
    std::string prop_partitions[] = { "", "system.", "vendor." };

    for(const std::string &prop : prop_partitions) {
        property_override(std::string("ro.product.") + prop + std::string("name"), device);
        property_override(std::string("ro.product.") + prop + std::string("device"), device);
        property_override(std::string("ro.product.") + prop + std::string("model"), model);
        property_override(std::string("ro.") + prop + std::string("build.product"), device);
        property_override(std::string("ro.") + prop + std::string("build.fingerprint"), fingerprint);
    }

    // Init a dummy BT MAC address, will be overwritten later
    property_set("ro.boot.btmacaddr", "00:00:00:00:00:00");

    // Configure alarm boot
    init_alarm_boot_properties();
}
