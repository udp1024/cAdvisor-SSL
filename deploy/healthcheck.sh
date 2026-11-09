#!/bin/sh

# Copyright 2025 Google Inc. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Default port and protocol
PORT=8080
SCHEME="http"
WGET_OPTS="--quiet --tries=1 --spider"

# Find cadvisor process cmdline (handle container PID 1 or --pid=host)
TARGET_PID=1
if [ -f /proc/1/cmdline ]; then
    INIT_CMD=$(tr '\0' ' ' < /proc/1/cmdline)
    case "$INIT_CMD" in
        *cadvisor*) ;;
        *)
            # If running with --pid=host, PID 1 is host init. Find cadvisor pid
            CPID=$(pidof cadvisor 2>/dev/null | awk '{print $1}')
            if [ -n "$CPID" ] && [ -f "/proc/$CPID/cmdline" ]; then
                TARGET_PID="$CPID"
            fi
            ;;
    esac

    CMDLINE=$(tr '\0' ' ' < "/proc/$TARGET_PID/cmdline")

    # Look for arguments
    for arg in $CMDLINE; do
        case "$arg" in
            -port=*)
                PORT="${arg#-port=}"
                ;;
            --port=*)
                PORT="${arg#--port=}"
                ;;
            -tls_cert_file=*|--tls_cert_file=*)
                SCHEME="https"
                WGET_OPTS="$WGET_OPTS --no-check-certificate"
                ;;
        esac
    done
fi

wget $WGET_OPTS "${SCHEME}://localhost:${PORT}/healthz" || exit 1
