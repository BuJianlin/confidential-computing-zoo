#
# Copyright (c) 2022 Intel Corporation
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

ARG BASE_IMAGE=tdx-dev:dcap1.15-centos8-latest
FROM ${BASE_IMAGE}

# cmake tool chain
ARG CMAKE_VERSION=3.19.6
RUN mkdir -p ${INSTALL_PREFIX} \
    && wget -q -O cmake-linux.sh https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-Linux-x86_64.sh \
    && sh cmake-linux.sh -- --skip-license --prefix=${INSTALL_PREFIX} \
    && rm cmake-linux.sh

# bazel tool chain
ARG BAZEL_VERSION=3.7.1
ENV CC=gcc
ENV CXX=g++
RUN wget "https://github.com/bazelbuild/bazel/releases/download/${BAZEL_VERSION}/bazel-${BAZEL_VERSION}-installer-linux-x86_64.sh" \
    && sh bazel-${BAZEL_VERSION}-installer-linux-x86_64.sh

ENV GRPC_ROOT=/grpc
ENV GRPC_PATH=${GRPC_ROOT}/src
ENV SGX_RA_TLS_BACKEND=TDX
ENV SGX_RA_TLS_SDK=DEFAULT
ENV BUILD_TYPE=Release

ARG GRPC_VERSION=v1.38.1
ARG GRPC_VERSION_PATH=${GRPC_ROOT}/${GRPC_VERSION}
RUN git clone --recurse-submodules -b ${GRPC_VERSION} https://github.com/grpc/grpc ${GRPC_VERSION_PATH}

RUN ln -s ${GRPC_VERSION_PATH} ${GRPC_PATH}

# RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 1

RUN pip3 install --upgrade pip \
    && pip3 install -r ${GRPC_PATH}/requirements.txt \
    && pip3 install cython==0.29.36

RUN yum makecache \
    && yum install -y golang strace gdb ctags curl zip \
    && yum clean all

RUN rm -rf ~/.cache/* \
    && rm -rf /tmp/*

COPY grpc/common ${GRPC_VERSION_PATH}
COPY grpc/${GRPC_VERSION} ${GRPC_VERSION_PATH}

# Workspace
ENV WORK_SPACE_PATH=${GRPC_PATH}/examples/cpp/ratls
WORKDIR ${WORK_SPACE_PATH}

ENTRYPOINT ["/bin/bash", "-c", "sleep infinity"]
