#!/usr/bin/env zsh
num_running_containers=$(( $(nerdctl ps | wc -l) - 1  ))
echo "${num_running_containers} containers running"
