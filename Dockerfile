# FROM nvidia/cuda:11.1-devel-ubuntu20.04 as cuda_toolkit_build

FROM ghcr.io/linuxserver/baseimage-rdesktop-web:focal

# COPY  --from=cuda_toolkit_build /usr/local/cuda-11.1 /usr/local/cuda-11.1
# set version label
ARG BUILD_DATE
ARG VERSION
ARG BLENDER_VERSION
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="thelamer"

# app title
ENV TITLE=Blender


RUN apt-get update && \
    apt-get install --no-install-recommends -y \
    ocl-icd-libopencl1 \
    xz-utils \
    git \
	  vim \
	  wget \
	  software-properties-common \
	  curl \
	  libglu1-mesa-dev freeglut3-dev mesa-common-dev libosmesa6-dev

# # install newest cmake version
# RUN apt-get purge cmake && cd ~ && wget https://github.com/Kitware/CMake/releases/download/v3.14.5/cmake-3.14.5.tar.gz && tar -xvf cmake-3.14.5.tar.gz
# RUN cd ~/cmake-3.14.5 && ./bootstrap && make -j6 && make install

RUN chsh -s /bin/bash
RUN apt-get install -y libgl1-mesa-glx \
    libegl1-mesa \
    libxrandr2 \
    libxrandr2 \
    libxss1 \
    libxcursor1 \
    libxcomposite1 \
    libasound2 \
    libxi6 \
    libxtst6 \
    libxmu6 \
    libnvidia-gl-440 \
    python3-rtree \
    zip

#Install Anaconda
ENV CONDA_DIR /opt/conda
 
RUN wget https://repo.anaconda.com/archive/Anaconda3-2020.02-Linux-x86_64.sh
RUN bash Anaconda3-2020.02-Linux-x86_64.sh -b -p /opt/conda
ENV PATH=/opt/conda/bin:${PATH} 

SHELL ["/bin/bash", "-c"]
RUN source /root/.bashrc

RUN conda update -y conda
RUN conda list

SHELL ["/bin/bash", "-c", "-i","-l"]
RUN conda init bash && source /root/.bashrc && conda create --name brignet python=3.7 && conda activate brignet
RUN echo "conda activate brignet" >> ~/.bashrc

RUN conda activate brignet && conda install -y pytorch=1.8.1 cudatoolkit=11.1 -c pytorch-lts -c nvidia

RUN conda activate brignet && pip install open3d==0.9.0 "rtree>=0.8,<0.9" trimesh[all] numpy scipy matplotlib tensorboard opencv-python

RUN conda activate brignet && pip install --no-index torch-scatter -f https://pytorch-geometric.com/whl/torch-1.8.1+cu111.html
RUN conda activate brignet && pip install --no-index torch-sparse -f https://pytorch-geometric.com/whl/torch-1.8.1+cu111.html
RUN conda activate brignet && pip install --no-index torch-cluster -f https://pytorch-geometric.com/whl/torch-1.8.1+cu111.html

# RUN conda activate brignet && pip install --no-index torch-scatter torch-sparse torch-cluster -f https://pytorch-geometric.com/whl/torch-1.8.1+cu111.html

RUN conda activate brignet && pip install torch-spline-conv -f https://pytorch-geometric.com/whl/torch-1.8.1+cu111.html
RUN conda activate brignet && pip install torch-geometric


RUN conda activate brignet && python 
    
# RUN conda activate rignet_cuda11 && conda install -y -c pytorch pytorch==1.7.1 torchvision==0.8.2 cudatoolkit=11.1
# RUN conda activate rignet_cuda11 && pip install --no-index torch-scatter torch-sparse torch-cluster -f https://pytorch-geometric.com/whl/torch-1.8.2+cu111.html
# RUN conda activate rignet_cuda11 && pip install torch-geometric==1.7.2

# Donwload the Plugin
RUN git clone --recursive https://github.com/pKrime/brignet.git

RUN zip -r main.zip brignet

RUN conda activate brignet && ln -s libOpenCL.so.1 /usr/lib/x86_64-linux-gnu/libOpenCL.so && \
  echo "**** install blender ****" && \
  mkdir /blender && \
  if [ -z ${BLENDER_VERSION+x} ]; then \
    BLENDER_VERSION=$(curl -sL https://mirror.clarkson.edu/blender/source/ \
      | awk -F'"|/"' '/blender-[0-9]*\.[0-9]*\.[0-9]*\.tar\.xz/ && !/md5sum/ {print $2}' \
      | tail -1 \
      | sed 's|blender-||' \
      | sed 's|\.tar\.xz||'); \
  fi && \
  BLENDER_FOLDER=$(echo "Blender${BLENDER_VERSION}" | sed -r 's|(Blender[0-9]*\.[0-9]*)\.[0-9]*|\1|') && \
  curl -o \
    /tmp/blender.tar.xz -L \
    "https://mirror.clarkson.edu/blender/release/${BLENDER_FOLDER}/blender-${BLENDER_VERSION}-linux-x64.tar.xz" && \
  tar xf \
    /tmp/blender.tar.xz -C \
    /blender/ --strip-components=1 && \
  ln -s \
    /blender/blender \
    /usr/bin/blender && \
  echo "**** cleanup ****" && \
  rm -rf \
    /tmp/* \
    /var/lib/apt/lists/* \
    /var/tmp/*

# add local files
COPY /root /

# ports and volumes
EXPOSE 3000
VOLUME /config










# Install CudaToolkit


# RUN mkdir cuda_install
# WORKDIR /cuda_install






# RUN mv cuda-ubuntu2004.pin /etc/apt/preferences.d/cuda-repository-pin-600
# RUN wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/cuda-11-1_11.1.0-1_amd64.deb
# RUN dpkg -i cuda-11-1_11.1.0-1_amd64.deb



# RUN apt remove --autoremove nvidia-cuda-toolkit && \
#  apt-get autoremove && \
#  apt-get autoclean


# RUN wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/cuda-keyring_1.0-1_all.deb \
#     && dpkg -i cuda-keyring_1.0-1_all.deb

# RUN apt-get update \
#  && apt-get install -y cuda-11-1 cuda-runtime-11-1 cuda-demo-suite-11-1 cuda-drivers-515 libnvidia-gl-515 nvidia-driver-515\
#  && apt-get install -y nvidia-gds
# WORKDIR /