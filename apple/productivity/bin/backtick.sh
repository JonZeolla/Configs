#!/usr/bin/env zsh
num_docker_containers=$(( $(docker ps | wc -l) - 1  ))
num_nerdctl_containers=$(( $(nerdctl ps | wc -l) - 1  ))
total_running_containers=$(( ${num_docker_containers} + ${num_nerdctl_containers}  ))
echo "${total_running_containers} containers running"
