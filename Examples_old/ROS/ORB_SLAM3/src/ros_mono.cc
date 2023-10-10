/**
* This file is part of ORB-SLAM3
*
* Copyright (C) 2017-2021 Carlos Campos, Richard Elvira, Juan J. Gómez Rodríguez, José M.M. Montiel and Juan D. Tardós, University of Zaragoza.
* Copyright (C) 2014-2016 Raúl Mur-Artal, José M.M. Montiel and Juan D. Tardós, University of Zaragoza.
*
* ORB-SLAM3 is free software: you can redistribute it and/or modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* ORB-SLAM3 is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
* the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License along with ORB-SLAM3.
* If not, see <http://www.gnu.org/licenses/>.
*/


#include<iostream>
#include<algorithm>
#include<fstream>
#include<chrono>

#include<ros/ros.h>
#include <cv_bridge/cv_bridge.h>

#include<opencv2/core/core.hpp>
#include "opencv2/imgcodecs/legacy/constants_c.h"

#include <tf2_ros/transform_broadcaster.h>
#include <geometry_msgs/TransformStamped.h>

#include"../../../include/System.h"
#include <std_msgs/Int32.h>

using namespace std;

class ImageGrabber
{
public:
    tf2_ros::TransformBroadcaster broadcaster;
    geometry_msgs::TransformStamped transformStamped;
    ros::Rate rate = ros::Rate(10.0);

    ImageGrabber(ORB_SLAM3::System* pSLAM, const bool isLocalisation):mpSLAM(pSLAM){
        if(isLocalisation){
            transformStamped.header.frame_id = "parent_frame";  // parent_frame
            transformStamped.child_frame_id  = "child_frame";   // child_frame
        }
        else{
            transformStamped.header.frame_id = "orb_static_frame";  // parent_frame
            transformStamped.child_frame_id  = "orb_dynamic_frame";   // child_frame
        }
    }

    void GrabImage(const sensor_msgs::ImageConstPtr& msg);

    ORB_SLAM3::System* mpSLAM;
};

ros::Publisher statePublisher_;

int main(int argc, char **argv)
{
    ros::init(argc, argv, "Mono");
    ros::start();

    if(argc != 5)
    {
        cerr << endl << "Usage: rosrun ORB_SLAM3 Mono path_to_vocabulary path_to_settings show_gui[true/false] islocalisation[true/false]" << endl;        
        ros::shutdown();
        return 1;
    }   

    std::string suseGui(argv[3]);
    std::string sisLocalization(argv[4]); 

    bool useGui = true;
    bool isLocalization = false;

    if(suseGui == "false"){
      useGui = false;
      std::cout<<"Gui disabled"<<std::endl;
    }
    else
        std::cout<<"Gui enabled"<<std::endl;

    if(sisLocalization == "true"){
        isLocalization = true;
        std::cout<<"Localisation mode"<<std::endl;
    }
    else
        std::cout<<"Mapping mode"<<std::endl;

    string filename;

    // Create SLAM system. It initializes all system threads and gets ready to process frames.
    ORB_SLAM3::System SLAM(argv[1],argv[2],ORB_SLAM3::System::MONOCULAR, useGui, 0, filename, isLocalization);

    ImageGrabber igb(&SLAM, isLocalization);

    ros::NodeHandle nodeHandler;
    ros::Subscriber sub = nodeHandler.subscribe("/camera/infra1/image_rect_raw", 10, &ImageGrabber::GrabImage,&igb);
    statePublisher_ = nodeHandler.advertise<std_msgs::Int32>("/nav_state", 1);


    ros::spin();

    // Stop all threads
    SLAM.Shutdown();

    // Save camera trajectory
    SLAM.SaveKeyFrameTrajectoryTUM("KeyFrameTrajectory.txt");

    ros::shutdown();

    return 0;
}

void ImageGrabber::GrabImage(const sensor_msgs::ImageConstPtr& msg)
{
    // Copy the ros image message to cv::Mat.
    cv_bridge::CvImageConstPtr cv_ptr;
    try
    {
        cv_ptr = cv_bridge::toCvShare(msg);
    }
    catch (cv_bridge::Exception& e)
    {
        ROS_ERROR("cv_bridge exception: %s", e.what());
        return;
    }

    Sophus::SE3f last_tf = mpSLAM->TrackMonocular(cv_ptr->image,cv_ptr->header.stamp.toSec());
    last_tf = last_tf.inverse();

    Eigen::Quaterniond quaternion(last_tf.rotationMatrix().cast<double>());
    Eigen::Vector3f translation = last_tf.translation();
    // last_tf = convertion_tf*last_tf;

    // //rotate by x
    // Eigen::Quaterniond rotation(
    //   std::sqrt(0.5), std::sqrt(0.5), 0.0, 0.0
    // );

    transformStamped.header.stamp = ros::Time::now();

    transformStamped.transform.translation.x = translation.x();
    transformStamped.transform.translation.y = translation.y();
    transformStamped.transform.translation.z = translation.z();

    //std::cout << translation.x() << std::endl;

    transformStamped.transform.rotation.x = quaternion.x();
    transformStamped.transform.rotation.y = quaternion.y();
    transformStamped.transform.rotation.z = quaternion.z();
    transformStamped.transform.rotation.w = quaternion.w();

    broadcaster.sendTransform(transformStamped);
    
    std_msgs::Int32 state_msg;
    state_msg.data = static_cast<int>(mpSLAM->GetTrackingState());
    statePublisher_.publish(state_msg);

    rate.sleep();
}


