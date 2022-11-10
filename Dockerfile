FROM docker.io/rocm/pytorch:rocm5.3_ubuntu20.04_py3.7_pytorch_staging

# Set env var for gfx803 
ENV ROC_ENABLE_PRE_VEGA=1
# Set env for required libraries
ENV LD_LIBRARY_PATH=/opt/rocm/lib

# Download patched deps from https://github.com/xuhuisheng/rocm-gfx803
RUN mkdir /packages && cd /packages && \
    wget https://github.com/xuhuisheng/rocm-gfx803/releases/download/rocm530/rocblas_2.45.0.50300-63.20.04_amd64.deb && \
    wget https://github.com/xuhuisheng/rocm-gfx803/releases/download/rocm500/torch-1.11.0a0+git503a092-cp38-cp38-linux_x86_64.whl && \
    wget https://github.com/xuhuisheng/rocm-gfx803/releases/download/rocm500/torchvision-0.12.0a0+2662797-cp38-cp38-linux_x86_64.whl && \
    wget https://github.com/xuhuisheng/rocm-gfx803/releases/download/rocm500/tensorflow_rocm-2.8.0-cp38-cp38-linux_x86_64.whl

# Install deps
RUN cd /packages && dpkg -i rocblas_2.45.0.50300-63.20.04_amd64.deb && \
    python3.8 -m pip install torch-1.11.0a0+git503a092-cp38-cp38-linux_x86_64.whl && \
    python3.8 -m pip install torchvision-0.12.0a0+2662797-cp38-cp38-linux_x86_64.whl && \
    python3.8 -m pip install tensorflow_rocm-2.8.0-cp38-cp38-linux_x86_64.whl && \
    apt install -y liblmdb-dev libopencv-highgui-dev libopencv-contrib-dev libopenblas-dev python3.8-venv && \
    rm -rf rocblas_2.45.0.50300-63.20.04_amd64.deb && \
    rm -rf /var/lib/apt/lists && \
\
    chmod -R 777 /packages


# Build roctracer required for pytorch
RUN python -m pip install CppHeaderParser argparse && \
    git clone -b rocm-5.3.0 https://github.com/ROCm-Developer-Tools/roctracer --depth 1 && \
    mkdir roctracer/build && \
    cd roctracer/build && cmake -DCMAKE_INSTALL_PREFIX=/opt/rocm .. && make -j8 && make install && \
    cd ../../ && rm -rf ./environ && rm -rf roctracer

# Setup user
RUN useradd -ms /bin/bash sduser && \
    adduser sduser sudo && \
    echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

WORKDIR /home/sduser

USER sduser
RUN /bin/bash -c "python3.8 -m venv ./environ && \
    echo 'source /home/sduser/environ/bin/activate' > ./.bash_profile && \
    source /home/sduser/environ/bin/activate && \
    python -m pip install /packages/torch-1.11.0a0+git503a092-cp38-cp38-linux_x86_64.whl && \
    python -m pip install /packages/torchvision-0.12.0a0+2662797-cp38-cp38-linux_x86_64.whl && \
    python -m pip install /packages/tensorflow_rocm-2.8.0-cp38-cp38-linux_x86_64.whl"
    
# roctracer ships .4 versions of its .so files, but pytorch needs .1 versions.
# They seem to be compatible enough to substitute them.
RUN sudo ln -s /opt/rocm-5.3.0/lib/libroctx64.so /opt/rocm-5.3.0/lib/libroctx64.so.1 && \
    sudo ln -s /opt/rocm-5.3.0/lib/libroctracer64.so /opt/rocm-5.3.0/lib/libroctracer64.so.1

CMD ["bash", "-l"]

# Make sure torch actually imports cleanly, or fail the build
RUN /home/sduser/environ/bin/python -c "import torch"
