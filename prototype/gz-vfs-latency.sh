#!/bin/bash
# VFS I/O Latency DTrace/Graphite Integration
# Outputs the average VFS layer I/O latency for read/write for all zones
#
# Ben Rockwood 

export HOSTNAME=`hostname | gsed 's/.joyent.com//'`
export GRAPHITE_SERVER="1.2.3.4"
export TARGET1="dtrace.vfslatency.${HOSTNAME}.read"
export TARGET2="dtrace.vfslatency.${HOSTNAME}.write"

echo "Graphite URL: http://${GRAPHITE_SERVER}:8080/render/?width=586&height=303&target=${TARGET1}&target=${TARGET2}&from=-1hours&tz=utc"


/usr/sbin/dtrace -n '
#pragma D option destructive
#pragma D option quiet

BEGIN
{
        read_latency = 0;
        read_count = 0;

        write_latency = 0;
        write_count = 0;
}

fbt::fop_read:entry
/ zonename != "global" /
{
        self->startr = timestamp;
}

fbt::fop_read:return
/ self->startr /
{
        read_count++;
        read_latency = read_latency + (timestamp - self->startr);

        self->startr = 0;
}

fbt::fop_write:entry
/ zonename != "global" /
{
        self->startw = timestamp;
}

fbt::fop_write:return
/ self->startw /
{
        write_count++;
        write_latency = write_latency + (timestamp - self->startw);

        self->startw = 0;
}


tick-10sec
{
        read_avg = ( read_latency / 1000000 ) / read_count;
        write_avg = ( write_latency / 1000000 ) / write_count;
        
        /* 
        printf("Average read latency: %d ms (count: %d)\nAverage write latency: %d ms (count: %d)\n", read_avg, read_count, write_avg, write_count);
        */
        system("echo \"dtrace.vfslatency.${HOSTNAME}.read %d %d\ndtrace.vfslatency.${HOSTNAME}.write %d %d\" | nc ${GRAPHITE_SERVER} 2003",
                read_avg,   walltimestamp / 1000000000,
                write_avg,  walltimestamp / 1000000000);



        read_latency = 0;
        read_count = 0;
        write_latency = 0;
        write_count = 0;
}
'
