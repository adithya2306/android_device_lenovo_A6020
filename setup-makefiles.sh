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

# Initialize the helper
setup_vendor "$DEVICE" "$VENDOR" "$AOSPA_ROOT"

# Copyright headers and guards
write_headers

write_makefiles "$MY_DIR/proprietary-files.txt" true

# Finish
write_footers
