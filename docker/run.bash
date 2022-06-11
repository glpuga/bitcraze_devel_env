#!/usr/bin/env bash

#
# Copyright (C) 2018 Open Source Robotics Foundation
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
#
#

IMAGE_NAME="bitcraze_devel_env"

RUNTIME="runc"

# Make sure processes in the container can connect to the x server
# Necessary so gazebo can create a context for OpenGL rendering (even headless)
XAUTH=/tmp/.docker.xauth
if [ ! -f $XAUTH ]
then
    xauth_list=$(xauth nlist $DISPLAY | sed -e 's/^..../ffff/')
    if [ ! -z "$xauth_list" ]
    then
        echo $xauth_list | xauth -f $XAUTH nmerge -
    else
        touch $XAUTH
    fi
    chmod a+r $XAUTH
fi
LOCAL_REPO_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )/../" >/dev/null 2>&1 && pwd )"

USERID=$(id -u)
GROUPID=$(id -g)

CONTAINER_NAME="${IMAGE_NAME}_instance"

mkdir -p $HOME/.docker_ccache

docker run -it \
  --name ${CONTAINER_NAME} \
  -e DISPLAY \
  -e QT_X11_NO_MITSHM=1 \
  -e XAUTHORITY=$XAUTH \
  -v "$XAUTH:$XAUTH" \
  -v "/tmp/.X11-unix:/tmp/.X11-unix" \
  -v "/etc/localtime:/etc/localtime:ro" \
  -v "/dev/input:/dev/input" \
  --mount type=bind,source=$HOME/.docker_ccache,target=/home/developer/.ccache \
  --mount type=bind,source=${LOCAL_REPO_PATH}/workspace,target=/home/developer/workspace \
  --network host \
  --privileged \
  --rm \
  --runtime=$RUNTIME \
  --security-opt seccomp=unconfined \
  -u $USERID:$GROUPID \
  $IMAGE_NAME
