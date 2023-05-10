FROM balenalib/jetson-xavier-ubuntu:jammy

ENV DEBIAN_FRONTEND noninteractive

COPY nv_boot_control.conf /etc/nv_boot_control.conf
COPY jetson_multimedia_api /usr/src/

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN mkdir /home/jetson
RUN mkdir /home/jetson/lotus_ros2_ws
RUN mkdir /home/jetson/lotus_ros2_ws/src
RUN mkdir /home/jetson/lotus_ros2_ws/build
RUN mkdir /home/jetson/lotus_ros2_ws/install

WORKDIR /home/jetson/lotus_ros2_ws

RUN apt update
RUN apt install -y --no-install-recommends curl wget ca-certificates

RUN curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg
RUN wget http://ports.ubuntu.com/ubuntu-ports/pool/main/libf/libffi/libffi6_3.2.1-8_arm64.deb
RUN dpkg -i libffi6*.deb
RUN rm libffi6*.deb

ADD --chown=root:root https://repo.download.nvidia.com/jetson/jetson-ota-public.asc /etc/apt/trusted.gpg.d/jetson-ota-public.asc
RUN chmod 644 /etc/apt/trusted.gpg.d/jetson-ota-public.asc 
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo $UBUNTU_CODENAME) main" | tee /etc/apt/sources.list.d/ros2.list > /dev/null

RUN apt update 
RUN apt install -y lsb-release gtk3-nocsd libcanberra-gtk-module git cmake python3-dev locales apt-utils gnupg dpkg-dev wget tar libi2c-dev ros-humble-desktop python3-colcon-common-extensions ros-humble-ros2-control ros-humble-robot-localization ros-humble-nav2* ros-humble-robot-state-publisher ros-humble-image-transport-plugins python3-rosdep python3-vcstool python3-pip libopencv-dev python3-opencv

RUN apt -o Dpkg::Options::="--force-overwrite" install -y nvidia-l4t-3d-core nvidia-l4t-wayland nvidia-l4t-core nvidia-l4t-cuda cuda-toolkit-10-2 libcudnn8-dev libnvinfer-dev
RUN apt full-upgrade -y	

RUN locale-gen en_US.UTF-8

ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/lib/aarch64-linux-gnu/tegra
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
ENV LANG=en_US.UTF-8

RUN git clone https://github.com/jmogainz/base_station_receiver.git src/base_station_receiver
RUN git clone https://github.com/jmogainz/transport_drivers.git src/transport_drivers
RUN git clone https://github.com/jmogainz/lotus_nav.git src/lotus_nav
RUN git clone -b ros2 https://github.com/jmogainz/ublox.git src/ublox
RUN git clone -b ros2 https://github.com/jmogainz/vesc.git src/vesc
RUN git clone --recurse-submodules https://github.com/jmogainz/ros2_bno055_sensor.git src/ros2_bno55_sensor

WORKDIR /home/jetson/lotus_ros2_ws/src/ros2_bno55_sensor/thirdparty/BNO055_driver/
RUN git apply ../../bno055.h.patch

WORKDIR /home/jetson/lotus_ros2_ws/

RUN /bin/bash -c "source /opt/ros/humble/setup.bash; rosdep init"
RUN /bin/bash -c "source /opt/ros/humble/setup.bash; rosdep update"
RUN /bin/bash -c "source /opt/ros/humble/setup.bash; rosdep install -y -r -q --from-paths src --ignore-src --rosdistro humble"

RUN /bin/bash -c "source /opt/ros/humble/setup.bash; colcon build"

ENTRYPOINT /bin/bash -c "source /opt/ros/humble/setup.bash; source install/setup.bash; ros2 launch lotus_nav lotus_control_service.launch.py"
