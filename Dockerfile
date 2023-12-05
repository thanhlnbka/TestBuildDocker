FROM arm64v8/ubuntu:20.04
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    libgtk2.0-dev \
    pkg-config \
    libavcodec-dev \
    libavformat-dev \
    libswscale-dev \
    ninja-build \
    meson \
    flex \
    bison \
    wget \
    zlib1g-dev \
    unzip \
    openssl \
    libssl-dev \
    libcurl4-openssl-dev \
    libelf-dev libdwarf-dev \
    libdw-dev

RUN apt install -y software-properties-common lsb-release && apt clean all

RUN mkdir /install 

WORKDIR /install 
#cmake 
RUN wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | gpg --dearmor - | tee /etc/apt/trusted.gpg.d/kitware.gpg >/dev/null
RUN apt-add-repository "deb https://apt.kitware.com/ubuntu/ $(lsb_release -cs) main"
RUN apt update && apt install kitware-archive-keyring && rm /etc/apt/trusted.gpg.d/kitware.gpg
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 6AF7F09730B3F0A4
RUN apt update && apt install -y cmake

# Install gstreamer-1.14.4
## gstreamer1.0
RUN git clone https://gitlab.freedesktop.org/gstreamer/gstreamer.git
RUN cd gstreamer \
    && git checkout tags/1.14.4 \
    && meson --prefix=/usr --buildtype=release -Dgst_debug=false -Dpackage-origin=https://gitlab.freedesktop.org/gstreamer/gstreamer.git builddir \
    && ninja install -C builddir/
RUN rm -rf gstreamer

## gstreamer-base 
RUN git clone https://gitlab.freedesktop.org/gstreamer/gst-plugins-base.git
RUN cd gst-plugins-base \
    && git checkout tags/1.14.4 \
    && meson --prefix=/usr --buildtype=release -Dgst_debug=false -Dpackage-origin=https://gitlab.freedesktop.org/gstreamer/gst-plugins-base.git builddir \
    && ninja install -C builddir/
RUN rm -rf gst-plugins-base

## gstreamer-bad 
RUN git clone https://gitlab.freedesktop.org/gstreamer/gst-plugins-bad.git
RUN cd gst-plugins-bad \
    && git checkout tags/1.14.4 \
    && meson --prefix=/usr --buildtype=release -Dgst_debug=false -Dpackage-origin=https://gitlab.freedesktop.org/gstreamer/gst-plugins-bad.git builddir \
    && ninja install -C builddir/
RUN rm -rf gst-plugins-bad

## gstreamer-good 
RUN git clone https://gitlab.freedesktop.org/gstreamer/gst-plugins-good.git
RUN cd gst-plugins-good \
    && git checkout tags/1.14.4 \
    && meson --prefix=/usr --buildtype=release -Dgst_debug=false -Dpackage-origin=https://gitlab.freedesktop.org/gstreamer/gst-plugins-good.git builddir \
    && ninja install -C builddir/
RUN rm -rf gst-plugins-good

## gstreamer-ugly 
RUN git clone https://gitlab.freedesktop.org/gstreamer/gst-plugins-ugly.git
RUN cd gst-plugins-ugly \
    && git checkout tags/1.14.4 \
    && meson --prefix=/usr --buildtype=release -Dgst_debug=false -Dpackage-origin=https://gitlab.freedesktop.org/gstreamer/gst-plugins-ugly.git builddir \
    && ninja install -C builddir/
RUN rm -rf gst-plugins-ugly   

## gstreamer-rtsp-server
RUN git clone https://gitlab.freedesktop.org/gstreamer/gst-rtsp-server.git
RUN cd gst-rtsp-server \
    && git checkout tags/1.14.4 \
    && sed -i "s/option('tests', type : 'boolean', value : true,/option('tests', type : 'boolean', value : false,/" meson_options.txt \
    && meson --prefix=/usr --buildtype=release -Dgst_debug=false -Dpackage-origin=https://gitlab.freedesktop.org/gstreamer/gst-rtsp-server.git builddir \
    && ninja install -C builddir/
RUN rm -rf gst-rtsp-server

## opencv
ENV OPENCV_VER 4.6.0
RUN wget -O opencv.zip https://github.com/opencv/opencv/archive/${OPENCV_VER}.zip
RUN wget -O opencv_contrib.zip https://github.com/opencv/opencv_contrib/archive/${OPENCV_VER}.zip
RUN unzip opencv.zip && mv opencv-${OPENCV_VER} opencv
RUN unzip opencv_contrib.zip && mv opencv_contrib-${OPENCV_VER} opencv_contrib
RUN mkdir opencv_build \
    && cd opencv_build \
    && cmake -DCMAKE_BUILD_TYPE=Release -DWITH_GTK=ON -DWITH_FFMPEG=ON -DWITH_GSTREAMER=ON -DOPENCV_EXTRA_MODULES_PATH=../opencv_contrib/modules/ -DBUILD_JAVA=OFF -DBUILD_FAT_JAVA_LIB=OFF -DBUILD_opencv_python2=OFF -DBUILD_opencv_python3=ON -DOPENCV_PYTHON3_INSTALL_PATH=$(python3 -c 'import site; print([x for x in site.getsitepackages() if x.find("/usr/local/lib/") > -1][0])') -DBUILD_EXAMPLES=OFF -DPYTHON_EXECUTABLE=$(which python3) -DPYTHON_DEFAULT_EXECUTABLE=$(which python3) -DBUILD_PERF_TESTS=OFF -DBUILD_TESTS=OFF -DENABLE_PRECOMPILED_HEADERS=OFF -DBUILD_opencv_apps=OFF ../opencv \
    && make -j $(($(nproc)+4)) install
RUN rm -rf opencv*

##zmqcpp 
RUN git clone -b v4.3.4 https://github.com/zeromq/libzmq.git
RUN cd libzmq && mkdir build && cd build && cmake .. && make install -j $(($(nproc)+4))
RUN git clone -b v4.9.0  https://github.com/zeromq/cppzmq.git
RUN cd cppzmq && mkdir build && cd build && cmake .. && make install -j $(($(nproc)+4))

## zipper 
RUN git clone https://github.com/sebastiandev/zipper
RUN cd zipper && git submodule update --init --recursive \
    && mkdir build && cd build && cmake ../ && make install -j $(($(nproc)+4))

## hiredis ssl
RUN git clone https://github.com/redis/hiredis.git
RUN cd hiredis && git checkout v1.2.0  && make USE_SSL=1 install -j $(($(nproc)+4))

## redis plus plus 
RUN git clone https://github.com/sewenew/redis-plus-plus.git
RUN cd redis-plus-plus && git checkout 1.3.10 && mkdir build && cd build && cmake -DREDIS_PLUS_PLUS_USE_TLS=ON .. && make install -j $(($(nproc)+4))

## cpr 
RUN git clone -b 1.10.x https://github.com/whoshuu/cpr.git
RUN cd cpr && mkdir build && cd build && cmake .. -DCPR_USE_SYSTEM_CURL=ON \
    && cmake --build . --parallel && cmake --build . --parallel && cmake --install .

WORKDIR /workspace
# Clean cached
RUN rm -rf /install && rm -rf /var/lib/apt/lists/*
