#!/usr/sbin/dtrace -s

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
        /* printf("%s request in %d ms for export: %s\n", probefunc, this->ms, self->export );  */

	@read[self->export] = avg(this->ms);
	
        self->start == 0
}

tick-10sec
{
        
        printa(@read);
        trunc(@read);
}
