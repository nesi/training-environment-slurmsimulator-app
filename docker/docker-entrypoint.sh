#!/bin/bash

_munge_setup() {
    sudo -u munge mungekey -b 1024 -f

    mkdir -p /run/munge
    chown munge:munge /run/munge

    sudo -u munge munged
}

_mysql_setup() {
    mysql_install_db --user=mysql       > /dev/null
    mysqld_safe --user=mysql --no-watch > /dev/null
    wait-for-it.sh -q localhost:3306

    mysql <<EOF
CREATE USER 'slurm'@'localhost';
SET PASSWORD FOR 'slurm'@'localhost' = PASSWORD('password');
GRANT USAGE ON *.* TO 'slurm'@'localhost';
CREATE DATABASE slurm_acct_db;
GRANT ALL ON slurm_acct_db.* TO 'slurm'@'localhost';
FLUSH PRIVILEGES;
EOF
}

_slurmdb_setup() {
    cat > /etc/slurm/slurmdbd.conf <<EOF
#
# See the slurmdbd.conf man page for more information.
#

DbdHost=localhost
PidFile=/var/run/slurm/slurmdbd.pid
SlurmUser=slurm
StorageType=accounting_storage/mysql
StorageUser=slurm
StoragePass=password
EOF

    chown slurm:slurm /etc/slurm/slurmdbd.conf
    chmod 600 /etc/slurm/slurmdbd.conf

    slurmdbd
    wait-for-it.sh -q localhost:6819
}

_slurm_setup() {

    cat > /etc/slurm/slurm.conf <<EOF
#
# See the slurm.conf man page for more information.
#

EnforcePartLimits=ALL
MailProg=/bin/true
ProctrackType=proctrack/linuxproc
SlurmctldHost=localhost
SlurmctldPidFile=/var/run/slurm/slurmctld.pid
SlurmdPidFile=/var/run/slurm/slurmd-%n.pid
SlurmdSpoolDir=/var/spool/slurm/slurmd-%n
SlurmUser=slurm
StateSaveLocation=/var/spool/slurm/slurmctld

# ACCOUNTING
ClusterName=sid
AccountingStorageType=accounting_storage/slurmdbd
JobAcctGatherType=jobacct_gather/linux

# LOGGING
SlurmctldLogFile=/var/log/slurm/slurmctld.log
SlurmdLogFile=/var/log/slurm/slurmd-%n.log

# COMPUTE NODES AND PARTITIONS
NodeName=sidc[1-4] NodeHostName=localhost Port=[6801-6804]
PartitionName=sidp Nodes=sidc[1-4] Default=YES MaxTime=1:00:00 State=UP
EOF

    mkdir -p /var/spool/slurm/slurmd-sidc{1..4}
    chown slurm:slurm /var/spool/slurm/slurmd-sidc{1..4}

    slurmctld -c
    slurmd -N sidc1
    slurmd -N sidc2
    slurmd -N sidc3
    slurmd -N sidc4
}

_slurm_accounting() {
    {
        sacctmgr -i add cluster sid
        sacctmgr -i add account admins Cluster=sid Description="cluster admins" Organization="none"
        sacctmgr -i add account users  Cluster=sid Description="cluster users"  Organization="none"
        sacctmgr -i add user ca  DefaultAccount=admins
        sacctmgr -i add user cu1 DefaultAccount=users
        sacctmgr -i add user cu2 DefaultAccount=users
    } > /dev/null
}

_main() {

    if [[ "${1:0:1}" == "-" ]]; then
        echo "Please pass a program name to the container!"
        exit 1
    fi

    _munge_setup
    _mysql_setup
    _slurmdb_setup
    _slurm_setup
    _slurm_accounting

    exec "$@"

}

_main "$@"
