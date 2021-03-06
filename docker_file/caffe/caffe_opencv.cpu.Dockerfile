FROM ubuntu:14.04
MAINTAINER caffe-maint@googlegroups.com

RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        cmake \
        git \
        wget \
        vim \
        ssh \
        libatlas-base-dev \
        libboost-all-dev \
        libgflags-dev \
        libgoogle-glog-dev \
        libhdf5-serial-dev \
        libleveldb-dev \
        liblmdb-dev \
        libopencv-dev \
        libprotobuf-dev \
        libsnappy-dev \
        protobuf-compiler \
        python-dev \
        python-numpy \
        python-pip \
        python-scipy && \
    rm -rf /var/lib/apt/lists/* && \
    python -m pip install -U pip

# OpenCV
RUN apt-get purge -y libopencv*

RUN cd /opt && \
    git clone https://github.com/Itseez/opencv.git && \
    cd /opt/opencv/ && \
    git checkout -b 3.1.0
RUN cd /opt && \
    git clone https://github.com/Itseez/opencv_contrib.git && \
    cd /opt/opencv_contrib/ && \
    git checkout -b 3.1.0

RUN mkdir -p /opt/opencv/build && \
    cd /opt/opencv/build && \
    cmake -D CMAKE_BUILD_TYPE=RELEASE \
		-D CMAKE_INSTALL_PREFIX=/usr/local \
		-D INSTALL_C_EXAMPLES=ON \
		-D INSTALL_PYTHON_EXAMPLES=ON \
        -D WITH_CVSBA=OFF \
		-D OPENCV_EXTRA_MODULES_PATH=/opt/opencv_contrib/modules \
		-D BUILD_EXAMPLES=ON \
        .. && \
	make -j8 && \
    make install && \
    ldconfig


# Caffe latest
ENV CAFFE_ROOT=/opt/caffe
WORKDIR $CAFFE_ROOT

# FIXME: clone a specific git tag and use ARG instead of ENV once DockerHub supports this.
ENV CLONE_TAG=master

RUN git clone -b ${CLONE_TAG} --depth 1 https://github.com/BVLC/caffe.git . && \
    for req in $(cat python/requirements.txt) pydot; do pip install $req; done && \
    mkdir /opt/caffe/build && \
    cd /opt/caffe/build && \
    cmake -D CPU_ONLY=ON \
          -D USE_OPENCV=ON \
          -D CMAKE_BUILD_TYPE=RELEASE \
          -D CMAKE_INSTALL_PREFIX=/usr/local \
          -D INSTALL_C_EXAMPLES=ON \
          -D INSTALL_PYTHON_EXAMPLES=ON \
          -D BUILD_EXAMPLES=ON \
          ..
    make -j"$(nproc)" && \

ENV PYCAFFE_ROOT $CAFFE_ROOT/python
ENV PYTHONPATH $PYCAFFE_ROOT:$PYTHONPATH
ENV PATH $CAFFE_ROOT/build/tools:$PYCAFFE_ROOT:$PATH
RUN echo "$CAFFE_ROOT/build/lib" >> /etc/ld.so.conf.d/caffe.conf && ldconfig

# sed GPU to CPU
# RUN sed -i "" 's/solver_mode: GPU/solver_mode: CPU/' `grep -F 'solver_mode: GPU' -rl //opt/caffe/examples/*.prototxt`
# RUN sed -i "" 's/solver_mode: GPU/solver_mode: CPU/g' `grep -F 'solver_mode: GPU' -rl /opt/caffe/examples`

WORKDIR /workspace

