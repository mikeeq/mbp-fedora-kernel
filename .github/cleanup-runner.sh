#!/usr/bin/env bash

function info () {
    echo >&2 "===]> Info: $* ";
}

info "Remove unneeded stuff from GitHub Actions Runner..."


# 11,2 GiB [###################################] /android
info "Removing Android SDK from /usr/local/lib/android..."
rm -rf /usr/local/lib/android

#  6,1 GiB [###################################] /hostedtoolcache

#   2,7 GiB [###################################] /CodeQL
#   1,3 GiB [#################                  ] /go
#   1,2 GiB [###############                    ] /Python
# 499,0 MiB [######                             ] /PyPy
# 372,6 MiB [####                               ] /node
#  60,9 MiB [                                   ] /Ruby
#  16,0 KiB [                                   ] /Java_Temurin-Hotspot_jdk

info "Removing CodeQL..."
rm -rf /opt/hostedtoolcache/CodeQL
info "Removing go..."
rm -rf /opt/hostedtoolcache/go

# 1,3 GiB [###################################] /jvm

info "Removing jvm..."
rm -rf /usr/lib/jvm

# 1,1 GiB [###################################] /powershell

# rm -rf /usr/local/share/powershell

#  2,7 GiB [###################################] /dotnet

info "Removing dotnet core..."
rm -rf /usr/share/dotnet

# 1,6 GiB [###################################] /swift

info "Removing swift..."
rm -rf /usr/share/swift

info "Removing all docker images..."
# shellcheck disable=SC2046
docker rmi $(docker images | awk '{print $3}')

info "Cleaning up docker storage..."
docker system prune -f --volumes
