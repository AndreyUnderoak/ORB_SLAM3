ARG BASE_IMG=registry.gitlab.com/beerlab/cpc/utils/cps_ros_base_docker:latest

FROM ${BASE_IMG}

SHELL ["/bin/bash", "-ci"]

# Timezone Configuration
ENV TZ=Europe/Moscow
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

ENV DEBIAN_FRONTEND=noninteractive

RUN apt update && apt upgrade -y && \
    # Install build tools, build dependencies and python
    apt install --no-install-recommends -y \
	build-essential gcc g++ \
	cmake git libgtk2.0-dev pkg-config libavcodec-dev libavformat-dev libswscale-dev \
	libtbb2 libtbb-dev libjpeg-dev libpng-dev libtiff-dev \
    yasm libatlas-base-dev gfortran libpq-dev \
    libxine2-dev libglew-dev libtiff5-dev zlib1g-dev libavutil-dev libpostproc-dev \ 
    libeigen3-dev python3-dev python3-pip python3-numpy libx11-dev tzdata \
	&& rm -rf /var/lib/apt/lists/*

RUN apt update && apt install -y \
	libglew-dev libboost-all-dev libssl-dev \
	libpcl-dev libogre-1.9-dev \
	libssl-dev libusb-1.0-0-dev libudev-dev pkg-config libgtk-3-dev \
	kmod \
	# linux-headers-5.15.0-69-generic \
	ros-noetic-octomap ros-noetic-octomap-msgs ros-noetic-octomap-ros

# Set Working directory
WORKDIR /opt

# Install OpenCV from Source
RUN git clone --branch raspberry_440 https://github.com/AndreyUnderoak/opencv.git && \
	cd opencv && mkdir build && cd build && \
    cmake \
	-D CMAKE_BUILD_TYPE=RELEASE \
	-D CMAKE_INSTALL_PREFIX=/usr/ \
	-D PYTHON3_PACKAGES_PATH=/usr/lib/python3/dist-packages \
	-D WITH_V4L=ON \
	-D WITH_QT=OFF \
	-D WITH_OPENGL=ON \
	-D WITH_GSTREAMER=ON \
	-D OPENCV_GENERATE_PKGCONFIG=ON \
	-D OPENCV_ENABLE_NONFREE=ON \
	-D INSTALL_PYTHON_EXAMPLES=OFF \
	-D INSTALL_C_EXAMPLES=OFF \
	-D BUILD_EXAMPLES=OFF .. && \
   make -j$(nproc) && \
   make install

RUN git clone https://github.com/stevenlovegrove/Pangolin.git && \
	cd Pangolin && mkdir build && cd build && \
	cmake .. -D CMAKE_BUILD_TYPE=Release && \ 
	make -j$(nproc) && \ 
	make install

RUN git clone https://github.com/IntelRealSense/librealsense.git &&\
	cd librealsense && mkdir build && cd build && \
	cmake .. && \
	make && make install

# Realsense dependency
# RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-key F6E65AC044F831AC80A06380C8B3A55A6F3EFCDE || \
#     sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-key F6E65AC044F831AC80A06380C8B3A55A6F3EFCDE && \
#     add-apt-repository "deb https://librealsense.intel.com/Debian/apt-repo $(lsb_release -cs) main" -u && \ 
#     apt update && apt install -y librealsense2-dkms librealsense2-utils librealsense2-dev librealsense2-dbg && \
#     rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/OctoMap/octomap.git &&\
	cd octomap && mkdir build && cd build && \
	cmake .. && \
	make && make install

WORKDIR /workspace/ros_ws
COPY . /workspace/ros_ws/src/ORB_SLAM3
RUN catkin build

RUN echo "export ROS_PACKAGE_PATH=:/workspace/ros_ws/src/ORB_SLAM3/Examples_old/ROS/ORB_SLAM3:\$ROS_PACKAGE_PATH" >> ~/.bashrc

RUN cd src/ORB_SLAM3 && \
 	./build.sh && \
	./build_ros.sh

CMD ["/bin/bash", "-ci", "cd /workspace/ros_ws/src/ORB_SLAM3 && rosrun ORB_SLAM3 Stereo_Inertial Vocabulary/ORBvoc.txt Examples/Stereo-Inertial/RealSense_D435i_save.yaml false 0"]