#!/usr/sbin/dtrace -s
/*
 * mysql_pid_avg.d	Print average query latency every second, plus more.
 *
 * USAGE: ./mysql_pid_avg.d -p mysqld_PID
 *
 * TESTED: these pid-provider probes may only work on some mysqld versions.
 *	5.0.51a: ok
 */

#pragma D option quiet

dtrace:::BEGIN
{
	query_time = 0; 
	query_count = 0;
	
	slow_count = 0;
}


pid$target::*dispatch_command*:entry
{
	self->start = timestamp;
}

pid$target::*dispatch_command*:return
/self->start && (this->time = (timestamp - self->start))/
{
	query_time = query_time + this->time;
	query_count++;
}

pid$target::*dispatch_command*:return
/self->start && (this->time > 1000000000)/
{
	slow_count++;	
}

pid$target::*dispatch_command*:return
{
	self->start = 0;
}

profile:::tick-30s
{

	avg_latnecy = ( query_time / query_count ) / 1000000;

	printf("%d %d %d %d\n",  walltimestamp / 1000000000, query_count, avg_latnecy, slow_count);

	avg_latnecy = 0;
        query_time = 0; 
        query_count = 0;
        slow_count = 0;
}
