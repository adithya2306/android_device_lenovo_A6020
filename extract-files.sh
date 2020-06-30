#!/bin/bash
#
# Copyright (C) 2018-2019 The LineageOS Project
# Copyright (C) 2020 Paranoid Android
#
# SPDX-License-Identifier: Apache-2.0
#

set -e

DEVICE=A6020
VENDOR=lenovo

# Load extract_utils and do some sanity checks
MY_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$MY_DIR" ]]; then MY_DIR="$PWD"; fi

AOSPA_ROOT="$MY_DIR/../../.."

HELPER="$AOSPA_ROOT/vendor/pa/build/tools/extract_utils.sh"
if [ ! -f "$HELPER" ]; then
    echo "Unable to find helper script at $HELPER"
    exit 1
fi
source "$HELPER"

# Default to sanitizing the vendor folder before extraction
CLEAN_VENDOR=true

SECTION=
KANG=

while [ "$#" -gt 0 ]; do
    case "$1" in
        -n | --no-cleanup )
                CLEAN_VENDOR=false
                ;;
        -k | --kang )
                KANG="--kang"
                ;;
        -s | --section )
                SECTION="$2"; shift
                CLEAN_VENDOR=false
                ;;
        * )
                SRC="$1"
                ;;
    esac
    shift
done

if [ -z "$SRC" ]; then
    SRC="adb"
fi

function blob_fixup() {
    case "$1" in
    vendor/etc/permissions/*)
        sed -i 's/system/vendor/g' "$2"
        ;;
    vendor/lib*/libRSDriver_adreno.so | vendor/lib*/libbccQTI.so)
        patchelf --replace-needed libLLVM.so libLLVM_android.so "$2"
        ;;
    vendor/lib*/egl/eglsubAndroid.so | vendor/lib*/egl/libESXGLESv2_adreno.so | vendor/lib*/egl/libRBEGL_adreno.so)
        sed -i 's/EGL_KHR_gl_colorspace/DIS_ABL_ED_colorspace/g' "$2"
        ;;
    vendor/bin/qmuxd | vendor/bin/netmgrd | vendor/lib*/libdsi_netctrl.so)
        sed -i 's|/system/etc/data|/vendor/etc/data|g' "$2"
        ;;
    vendor/lib*/libsettings.so)
        patchelf --replace-needed libprotobuf-cpp-full.so libprotobuf-cpp-hax.so "$2"
        ;;
    vendor/lib*/libprotobuf-cpp-hax.so)
        patchelf --set-soname libprotobuf-cpp-hax.so "$2"
        ;;
    vendor/bin/time_daemon)
        sed -i 's|/mnt/vendor/persist/time|/persist/time\x0\x0\x0\x0\x0\x0\x0\x0\x0\x0\x0|g' "$2"
        ;;
    esac
}

# Initialize the helper
setup_vendor "$DEVICE" "$VENDOR" "$AOSPA_ROOT" true "$CLEAN_VENDOR"

extract "$MY_DIR/proprietary-files.txt" "$SRC" "$KANG" --section "$SECTION"

"${MY_DIR}/setup-makefiles.sh"
