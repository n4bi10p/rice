#!/bin/bash

# Fetch hardware stats
cpu_model=$(lscpu | grep "Model name" | cut -d':' -f2 | sed 's/^[ \t]*//')
gpu_model=$(lspci | grep -i vga | cut -d':' -f3 | sed 's/^[ \t]*//')
mem_total=$(free -h | awk '/^Mem:/ {print $2}')

# Return as JSON
printf '{"cpu": "%s", "gpu": "%s", "mem": "%s"}\n' "$cpu_model" "$gpu_model" "$mem_total"