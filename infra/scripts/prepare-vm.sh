#!/usr/bin/env bash
# Réglages noyau exigés par SonarQube (Elasticsearch). À lancer une fois dans la VM.
set -e
sudo sysctl -w vm.max_map_count=524288
sudo sysctl -w fs.file-max=131072
grep -q '^vm.max_map_count' /etc/sysctl.conf || echo 'vm.max_map_count=524288' | sudo tee -a /etc/sysctl.conf
grep -q '^fs.file-max' /etc/sysctl.conf || echo 'fs.file-max=131072' | sudo tee -a /etc/sysctl.conf
sysctl vm.max_map_count
