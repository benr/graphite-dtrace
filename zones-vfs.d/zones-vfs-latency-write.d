#!/usr/sbin/dtrace -s

#pragma D option quiet

/**
fbt::fop_read:entry
/ zonename != "global" /
{
        self->startr = timestamp;
}

fbt::fop_read:return
/ self->startr /
{
	this->time = (timestamp - self->startr) / 1000000;
	@read[zonename] = avg(this->time);
        self->startr = 0;
}
**/

fbt::fop_write:entry
/ zonename != "global" /
{
        self->startw = timestamp;
}

fbt::fop_write:return
/ self->startw /
{


	this->time = (timestamp - self->startw) / 1000000;
	@write[zonename] = avg(this->time);
        self->startw = 0;
}


tick-10sec
{

	printa(@write);
	trunc(@write);
}
