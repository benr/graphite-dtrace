#!/usr/sbin/dtrace -s

#pragma D option quiet

rfs3_write:entry
{ 
        self->time = timestamp; 
        self->start = 1; 
        self->export =  stringof(args[2]->exi_export.ex_path);
} 

rfs3_write:return
/self->start == 1/
{ 
        this->elapsed   = timestamp;
        this->ms        = (this->elapsed - self->time)/1000000;

	@write[self->export] = avg(this->ms);
	
        self->start == 0
}

tick-10sec
{
        
        printa(@write);
        trunc(@write);
}
