#!/usr/bin/env bash

launch_server() {
    local server_name=$1
    local server_exec=$2
    local server_conf=$3
    local status="${server_name}.status"
    local pid="${server_name}.pid"

    # Ensure that old status and pid files are gone
    rm -f "${status}" "${pid}"

    "${server_exec}" \
        $server_conf \
        --status "${status}" 1 \
        --writepid "${pid}" \
        --explicit-exit-notify 3
}

# Load base/default configuration
. ./t_server_null_default.rc

# Load local configuration, if any
test -r ./t_server_null.rc && . ./t_server_null.rc

# Launch test servers
for SUF in $TEST_SERVER_LIST
do
    eval server_name=\"\$SERVER_NAME_$SUF\"
    eval server_exec=\"\$SERVER_EXEC_$SUF\"
    eval server_conf=\"\$SERVER_CONF_$SUF\"

    launch_server "${server_name}" "${server_exec}" "${server_conf}"
done

# Create a list of server pid files so that servers can be killed at the end of
# the test run.
#
export server_pid_files=""
for SUF in $TEST_SERVER_LIST
do
    eval server_name=\"\$SERVER_NAME_$SUF\"
    server_pid_files="${server_pid_files} ${srcdir}/${server_name}.pid"
done

# Wait until clients are no more, based on the presence of their pid files.
# Based on practical testing we have to wait at least four seconds to avoid
count=0
maxcount=4
while [ $count -le $maxcount ]; do
    ls t_server_null_client.sh*.pid > /dev/null 2>&1

    if [ $? -eq 0 ]; then
        count=0
        sleep 1
    else
        ((count++))
        sleep 1
    fi
done

echo "All clients have disconnected from all servers"

for PID_FILE in $server_pid_files
do
    kill `cat $PID_FILE`
done
