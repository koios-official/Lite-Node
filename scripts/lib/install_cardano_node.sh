#!/bin/bash

# cd /opt/cardano/cnode/sockets/

# if [ -e "node0.socket" ] && [ ! -e "node.socket" ]; then
#     ln -s node0.socket node.socket
#     echo "Symbolic link 'node.socket' created."
# elif [ -e "node.socket" ]; then
#     echo "Symbolic link 'node.socket' already exists."
# else
#     echo "node0.socket does not exist, cannot create symbolic link."
# fi