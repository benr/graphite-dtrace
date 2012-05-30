#!/bin/bash
#
#  NFSv3 Read Latnecy Grapher
#  ( Graphite/DTrace Integration Experiement 2.0 )
#
# <benr@joyent.com>     8/19/11
#

export GRAPHITE_SERVER="1.2.3.4"


export TARGET="dtrace.nfslatency.${HOSTNAME}.*.read"
export HOSTNAME=`hostname | gsed 's/.joyent.com//'`
echo "Graphite URL: http://${GRAPHITE_SERVER}:8080/render/?width=586&height=303&target=${TARGET}&from=-1hours&tz=utc"





FIFO="/var/run/.dtrace_latency.$$.fifo"
mkfifo $FIFO

## DTRACE ################################################################
 /usr/sbin/dtrace -n '
        #pragma D option quiet

        rfs3_read:entry
        {
                self->time = timestamp;
                self->start = 1;
                self->export =  stringof(args[2]->exi_export.ex_path);
        }


        rfs3_read:return
        /self->start == 1/
        {
                this->elapsed   = timestamp;
                this->ms        = (this->elapsed - self->time)/1000000;

                @[self->export] = avg( this->ms );

                self->start == 0
        }

        tick-10sec
        {
                printa(@);
                trunc(@);
        }
 ' >$FIFO &


cat $FIFO | while read SHARE LATENCY
do
        TIME=`perl -e '$DATE = time(); print("$DATE\n");'`
        if [[ $LATENCY ]]
        then
                echo "dtrace.nfslatency.${HOSTNAME}.${SHARE}.read ${LATENCY} ${TIME}"
        fi
done


### Need to cleanup on exit.
rm -f $FIFO
