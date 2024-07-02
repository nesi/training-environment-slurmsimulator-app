FROM fedora:37

RUN dnf upgrade -y && dnf install -y \
    # Tools
    sudo nano hostname hwloc procps-ng wget which tree git git-lfs \
    tar bzip2 xz lzip lzma lzop gzip ncompress zstd \
    cmake make autoconf automake gcc gcc-c++ gcc-gfortran openmpi pkgconf pkgconfig gcovr lcov \
    # Slurm dependencies
    dbus-devel freeipmi-devel hdf5-devel hwloc-devel libcurl-devel libssh2-devel \
    lz4-devel pam-devel pmix-devel rdma-core-devel readline-devel rrdtool-devel \
    zlib-devel ucx-devel http-parser-devel json-c-devel libjwt-devel libyaml-devel \
    numactl-devel munge munge-devel perl-devel perl-ExtUtils-MakeMaker perl-interpreter \
    perl-generators perl-podlators mariadb-server mariadb-pam mariadb-devel \
    # GitLab HPC Driver dependencies
    libconfig-devel spdlog-devel soci-sqlite3-devel boost-devel \
    gtest-devel gmock-devel \
    openldap openldap-clients openldap-servers \
    doxygen graphviz python python-pip

RUN yum install -y rsync 

#RUN localedef -i en_NZ -c -f UTF-8 -A /usr/share/locale/locale.alias en_NZ.UTF-8 
ENV LANG en_NZ.utf8

# Compile slurm with multiple-slurmd option
RUN wget -q "https://download.schedmd.com/slurm/slurm-24.05-latest.tar.bz2" && \
    tar -xjf slurm-*.tar.bz2 && \
    pushd slurm-*/ && \
    ./configure --prefix=/usr --sysconfdir=/etc/slurm --enable-shared --disable-static \
    --without-rpath --with-shared-libslurm --with-mysql_config=/usr/bin --enable-multiple-slurmd && \
    make -j && \
    make install && \
    popd && \
    rm -r slurm-*

ADD https://raw.githubusercontent.com/vishnubob/wait-for-it/master/wait-for-it.sh /usr/local/bin/
RUN chmod 755 /usr/local/bin/wait-for-it.sh

RUN echo "%wheel ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    useradd --system -c "Slurm Workload Manager" -s /sbin/nologin slurm && \
    mkdir -p /etc/slurm && chown slurm:slurm /etc/slurm && \
    mkdir -p /var/{spool,run,log}/slurm && chown slurm /var/{spool,run,log}/slurm && \
    useradd -c "Cluster Admin"  -G users,wheel -m --uid=1000 ca && \
    useradd -c "Cluster User 1" -G users       -m --uid=2001 cu1 && \
    useradd -c "Cluster User 2" -G users       -m --uid=2002 cu2

COPY docker-entrypoint.sh /usr/local/bin/

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["su", "--login", "ca"]

# install jupyterlab
RUN pip3 --no-cache-dir install jupyterlab