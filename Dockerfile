FROM registry.gitlab.com/beerlab/cpc/utils/cps_ros_base_docker:latest

SHELL ["/bin/bash", "-c"]

# Timezone Configuration
ENV TZ=Europe/Moscow
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

ENV DEBIAN_FRONTEND=noninteractive



RUN apt-get update || true && apt-get upgrade -y &&\
    # Install build tools, build dependencies and python
    apt-get install --no-install-recommends -y \
	build-essential gcc g++ \
	cmake git libgtk2.0-dev pkg-config libavcodec-dev libavformat-dev libswscale-dev \
	libtbb2 libtbb-dev libjpeg-dev libpng-dev libtiff-dev \
    yasm libatlas-base-dev gfortran libpq-dev \
    libxine2-dev libglew-dev libtiff5-dev zlib1g-dev libavutil-dev libpostproc-dev \ 
    libeigen3-dev python3-dev python3-pip python3-numpy libx11-dev tzdata \
&& rm -rf /var/lib/apt/lists/*

# Set Working directory
WORKDIR /opt


# Install OpenCV from Source
RUN git clone  https://github.com/AndreyUnderoak/opencv.git && \
	cd opencv && \
    git switch raspberry_440 && \
    mkdir build && \
    cd build && \
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
   make -j4 && \
   make install


RUN cd && \
	git clone https://github.com/stevenlovegrove/Pangolin.git && \
	cd Pangolin && \
	mkdir build && \
	cd build && \
	cmake .. -D CMAKE_BUILD_TYPE=Release && \ 
	make -j 3 && \ 
	make install

RUN apt-get update || true && apt-get upgrade -y &&\
	apt-get install -y libglew-dev libboost-all-dev libssl-dev

RUN apt-get install ros-noetic-octomap ros-noetic-octomap-msgs ros-noetic-octomap-ros

RUN apt-get install libpcl-dev libogre-1.9-dev

RUN apt-get update || true && apt-get upgrade -y &&\
	apt-get install -y git libssl-dev libusb-1.0-0-dev libudev-dev pkg-config libgtk-3-dev

RUN apt-get update || true && apt-get upgrade -y &&\
	apt-get install -y linux-headers-5.15.0-69-generic kmod

RUN cd && \
	git clone https://github.com/IntelRealSense/librealsense.git &&\
	cd librealsense && \
	mkdir build && \
	cd build && \
	cmake ../ &&\
	make && make install

RUN cd && \
	git clone https://github.com/OctoMap/octomap.git &&\
	cd octomap && \
	mkdir build && \
	cd build && \
	cmake .. &&\
	make && make install

COPY . /workspace/ros_ws/src/ORB_SLAM3
WORKDIR /workspace/ros_ws
RUN /bin/bash -ci "catkin build"

RUN echo "export ROS_PACKAGE_PATH=:/workspace/ros_ws/src/ORB_SLAM3/Examples_old/ROS/ORB_SLAM3:$ROS_PACKAGE_PATH" >> ~/.bashrc

RUN cd src/ORB_SLAM3 && \
 	./build.sh



# RUN mkdir -p src && cd src && \
#     git clone https://github.com/AndreyUnderoak/ORB_SLAM3.git &&\
#     cd .. && /bin/bash -c "catkin build" && cd src &&\
# 	cd ORB_SLAM3 && \
# 	sed -i 's/++11/++14/g' CMakeLists.txt && \
# 	chmod +x build.sh 
# 	# ./build.sh

# RUN /bin/bash -c "source /opt/ros/noetic/setup.bash" && \
#     catkin build




# ALternatively, Install from Ubuntu Repository
###
#RUN apt-get update -y || true && \
#	DEBIAN_FRONTEND=noninteractive apt-get install -y   && \
#	apt-get install -y --no-install-recommends libopencv-dev && \ 
#   rm -rf /var/lib/apt/lists/* && apt autoremove && apt clean
###

# WORKDIR /

# ENTRYPOINT [ "/bin/bash", "-l", "-c" ]

# CMD ["bash"]
