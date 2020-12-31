#!/bin/bash

set -eo pipefail

echo "[+]set /proc/sys/kernel/yama/ptrace_scope to 0"
echo 0 | tee /proc/sys/kernel/yama/ptrace_scope