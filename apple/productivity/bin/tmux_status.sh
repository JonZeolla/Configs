#!/usr/bin/env zsh

num_docker_containers=0
if command -v docker &> /dev/null; then
  num_docker_containers=$(( $(docker ps | wc -l) - 1 ))
fi

num_nerdctl_containers=0
if command -v nerdctl &> /dev/null; then
  num_nerdctl_containers=$(( $(nerdctl ps | wc -l) - 1 ))
fi

total_running_containers=$(( ${num_docker_containers} + ${num_nerdctl_containers} ))

echo "${total_running_containers} containers running"
