echo "Building ROS nodes"

mkdir -p Examples_old/ROS/ORB_SLAM3/build
cd Examples_old/ROS/ORB_SLAM3/build && cmake -DPYTHON_EXECUTABLE=/usr/bin/python3 -DPYTHON_INCLUDE_DIR=/usr/include/python3.6m -DPYTHON_LIBRARY=/usr/lib/x86_64-linux-gnu/libpython3.6m.so .. -DROS_BUILD_TYPE=Release && make -j4
