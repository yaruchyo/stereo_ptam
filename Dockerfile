FROM ubuntu:20.04

# Install base utilities
RUN apt-get update && \
    apt-get install build-essential -y && \
    apt-get install -y wget && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install miniconda
ENV CONDA_DIR /opt/conda
RUN wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda.sh && \
     /bin/bash ~/miniconda.sh -b -p /opt/conda

# Put conda in path so we can use conda activate
ENV PATH=$CONDA_DIR/bin:$PATH

RUN conda create -n slam python=3.6 -y
ARG DEBIAN_FRONTEND=noninteractive
RUN echo "source /opt/conda/bin/activate" >> /root/.bashrc
RUN /bin/bash -c "source /opt/conda/bin/activate && conda activate slam && pip install numpy"


ENV HOME /root
WORKDIR "$HOME"

#--------------#
# Localization #
#--------------#

RUN apt-get update && apt-get upgrade -y
RUN DEBIAN_FRONTEND="noninteractive" apt-get install -y tzdata
ENV TZ=Asia/Tokyo

#-----------#
# Dev Tools #
#-----------#

# Install CMake 3.21.6 for g2o
# CLion supports CMake 2.8.11~3.21.x
RUN apt-get install -y git build-essential libssl-dev
RUN git clone https://gitlab.kitware.com/cmake/cmake.git -b v3.21.6
RUN mkdir "$HOME/cmake/build"
WORKDIR "$HOME/cmake/build"
RUN ../bootstrap && make -j"$(nproc)" && make install
WORKDIR "$HOME"

RUN apt-get install -y \
      wget curl \
      gcc g++ gdb clang make \
      ninja-build autoconf automake \
      locales-all dos2unix rsync \
      tar python

#-------------#
# Python libs #
#-------------#

# Pangolin
RUN apt-get install -y libglew-dev libpython2.7-dev libeigen3-dev
# Bug fixed PR version
RUN git clone https://github.com/bravech/pangolin "$HOME/pangolin"
RUN mkdir "$HOME/pangolin/build"
WORKDIR "$HOME/pangolin/build"
RUN cmake .. && make -j"$(nproc)"
RUN sed -i "s/install_dirs/install_dir/g" "$HOME/pangolin/setup.py"
WORKDIR "$HOME/pangolin"
RUN python setup.py install
WORKDIR "$HOME"

# g2opy
RUN apt-get install -y libsuitesparse-dev qtdeclarative5-dev qt5-qmake libqglviewer-dev-qt5
# Bug fixed PR version
RUN git clone https://github.com/codegrafix/g2opy.git "$HOME/g2opy"
RUN mkdir "$HOME/g2opy/build"
WORKDIR "$HOME/g2opy/build"
RUN cmake .. && make -j"$(nproc)"
WORKDIR "$HOME/g2opy"
COPY docker_components/setup.py "$HOME"/g2opy
RUN python setup.py install
WORKDIR "$HOME"

RUN pip install --upgrade pip
COPY slam/requirements.txt "$HOME"
RUN pip install -r requirements.txt

RUN apt install gedit -y

RUN curl -L https://download.jetbrains.com/python/pycharm-community-2022.1.1.tar.gz  | tar -xvz

RUN echo "alias pycharm='pycharm-community-2022.1.1/bin/pycharm.sh'" >> /root/.bashrc

CMD ["/bin/bash"]
