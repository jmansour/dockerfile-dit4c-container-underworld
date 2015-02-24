# DOCKER-VERSION 1.0
FROM dit4c/dit4c-container-ipython
MAINTAINER t.dettrick@uq.edu.au

ENV PETSC_VERSION 3.1-p8
ENV HDF5_VERSION 1.8.14
ENV UNDERWORLD_VERSION 1.7.0

RUN yum install -y libxml2-devel openmpi-devel libpng-devel hostname

#RUN ln -s /usr/lib64/openmpi/bin/mpicc /usr/local/bin

# Install HDF5
RUN cd /tmp && \
    wget -nv "ftp://ftp.hdfgroup.org/HDF5/current/src/hdf5-$HDF5_VERSION.tar.gz" && \
    tar xzf hdf5-$HDF5_VERSION.tar.gz && \
    cd hdf5-$HDF5_VERSION && \
    ./configure --help && \
    export LD_LIBRARY_PATH=/usr/lib64/openmpi/lib:$LD_LIBRARY_PATH && \
    CC=/usr/lib64/openmpi/bin/mpicc CFLAGS=-fPIC ./configure --prefix=/usr/local/hdf5 && \
    make && \
    make check && \
    make install && \
    make check-install && \
    cd /tmp && \
    rm -r hdf5-$HDF5_VERSION

# Install PETSc
RUN cd /tmp && \
    wget -nv "http://ftp.mcs.anl.gov/pub/petsc/release-snapshots/petsc-lite-$PETSC_VERSION.tar.gz" && \
    tar xzf petsc-lite-$PETSC_VERSION.tar.gz && \
    cd petsc-$PETSC_VERSION && \
    export LD_LIBRARY_PATH=/usr/lib64/openmpi/lib:$LD_LIBRARY_PATH && \
    ./configure --prefix=/usr/local/petsc --download-f-blas-lapack=1 --with-mpi-dir=/usr/lib64/openmpi --with-pic=1 && \
    make all test && \
    make install && \
    cd /tmp && \
    rm -r petsc-$PETSC_VERSION

RUN cd /tmp && \
    wget -nv "http://underworldproject.org/downloads/underworld-$UNDERWORLD_VERSION/underworld-$UNDERWORLD_VERSION.tar.gz"

# Need X11 for gLucifer to compile
RUN yum install -y mercurial freeglut-devel

# Sadly Underworld doesn't actually build correctly from the release, so we have
# to update gLucifer to the latest 1.7.x
RUN cd /usr/local && \
    tar xzf /tmp/underworld-$UNDERWORLD_VERSION.tar.gz && \
    cd Underworld-$UNDERWORLD_VERSION && \
    rm /tmp/underworld-$UNDERWORLD_VERSION.tar.gz && \
    chown -R root:root . && \
    ./configure.py --help && \
    cd gLucifer && \
    hg checkout 1.7.x && \
    hg pull --update && \
    cd .. && \
    export PATH=$PATH:/usr/lib64/openmpi/bin && \
    ./configure.py --with-debugging=0 --hdf5-dir=/usr/local/hdf5 --petsc-dir=/usr/local/petsc && \
    ./scons.py && \
    ./scons.py check && \
    ./scons.py install

RUN ln -s /usr/local/Underworld-$UNDERWORLD_VERSION /usr/local/underworld

COPY /etc /etc
