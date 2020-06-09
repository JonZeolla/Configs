#!/usr/bin/env zsh
num_docker_containers=$(( $(docker ps | wc -l) - 1  ))
num_vmware_vms=$(vmrun list | head -1 | awk "{print \$NF}")
num_virtualbox_vms=$(VBoxManage list runningvms | wc -l | awk "{print \$NF}")
num_total_vms=$(( num_vmware_vms + num_virtualbox_vms ))
echo "${num_docker_containers} containers, ${num_total_vms} VMs up"
