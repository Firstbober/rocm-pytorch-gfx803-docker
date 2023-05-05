FROM docker.io/rocm/pytorch:rocm5.4.1_ubuntu20.04_py3.7_pytorch_1.12.1

#rootless
# Set env var for gfx803 
ENV ROC_ENABLE_PRE_VEGA=1 \
# set library path
    LD_LIBRARY_PATH=/opt/rocm/lib \
# rootless docker make sure pip knows it
    PIP_ROOT_USER_ACTION=ignore

# Download patched deps from https://github.com/xuhuisheng/rocm-gfx803
RUN mkdir /packages && cd /packages && \
    wget https://github.com/xuhuisheng/rocm-gfx803/releases/download/rocm541/rocblas_2.46.0.50401-84.20.04_amd64.deb && \
    wget https://github.com/xuhuisheng/rocm-gfx803/releases/download/rocm500/torch-1.11.0a0+git503a092-cp38-cp38-linux_x86_64.whl && \
    wget https://github.com/xuhuisheng/rocm-gfx803/releases/download/rocm500/torchvision-0.12.0a0+2662797-cp38-cp38-linux_x86_64.whl && \
    wget https://github.com/xuhuisheng/rocm-gfx803/releases/download/rocm500/tensorflow_rocm-2.8.0-cp38-cp38-linux_x86_64.whl

# Install deps
RUN apt update -y && cd /packages && dpkg -i rocblas_2.46.0.50401-84.20.04_amd64.deb && \
    python3.8 -m pip install torch-1.11.0a0+git503a092-cp38-cp38-linux_x86_64.whl && \
    python3.8 -m pip install torchvision-0.12.0a0+2662797-cp38-cp38-linux_x86_64.whl && \
    python3.8 -m pip install tensorflow_rocm-2.8.0-cp38-cp38-linux_x86_64.whl && \
    apt install -y liblmdb-dev libopencv-highgui-dev libopencv-contrib-dev libopenblas-dev python3.8-venv && \
    rm -rf rocblas_2.46.0.50401-84.20.04_amd64.deb && \
    rm -rf /var/lib/apt/lists


# Build roctracer required for pytorch
RUN python -m pip install CppHeaderParser argparse && \
    git clone -b rocm-5.4.0 https://github.com/ROCm-Developer-Tools/roctracer --depth 1 && \
    mkdir roctracer/build && \
    cd roctracer/build && cmake -DCMAKE_INSTALL_PREFIX=/opt/rocm .. && make -j8 && make install && \
    cd ../../ && rm -rf ./environ && rm -rf roctracer

# Setup user
#RUN useradd -ms /bin/bash sduser && \
#    adduser sduser sudo && \
#    echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
#
#WORKDIR /home/sduser
#
#USER sduser

#ROOTLESS docker

USER root
WORKDIR /root

RUN /bin/bash -c "python3.8 -m venv ./environ && \
    echo 'source /root/environ/bin/activate' > ./.bash_profile && \
    source /root/environ/bin/activate && \
    python -m pip install /packages/torch-1.11.0a0+git503a092-cp38-cp38-linux_x86_64.whl && \
    python -m pip install /packages/torchvision-0.12.0a0+2662797-cp38-cp38-linux_x86_64.whl && \
    python -m pip install /packages/tensorflow_rocm-2.8.0-cp38-cp38-linux_x86_64.whl"
    
# roctracer ships .4 versions of its .so files, but pytorch needs .1 versions.
# They seem to be compatible enough to substitute them.
RUN sudo ln -s /opt/rocm-5.4.1/lib/libroctx64.so /opt/rocm-5.4.1/lib/libroctx64.so.1 && \
    sudo ln -s /opt/rocm-5.4.1/lib/libroctracer64.so /opt/rocm-5.4.1/lib/libroctracer64.so.1

CMD ["bash", "-l"]

# Make sure torch actually imports cleanly, or fail the build
RUN /root/environ/bin/python -c "import torch"
