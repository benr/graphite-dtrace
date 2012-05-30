#!/usr/perl5/bin/perl

use strict;
use Sun::Solaris::Kstat;
use IO::Socket;

## Default Values:
my $interval = 30;
my $POD = "dc1";
my $GRAPHITE_SERVER = "graphite.joyent.com";
my $GRAPHITE_PORT   = 2003;


my $Kstat = Sun::Solaris::Kstat->new();

## Prep the socket
my $sock = IO::Socket::INET->new(
    Proto    => 'tcp',
    PeerPort => $GRAPHITE_PORT,
    PeerAddr => $GRAPHITE_SERVER,
) or die "Could not create socket: $!\n";

my $HOSTNAME = `hostname`;
chomp($HOSTNAME);
$HOSTNAME =~ s/.joyent.com//;
my $KEY_PREFIX = "joyent.${POD}.${HOSTNAME}.zfs";

my $last_arcHits = 0;
my $last_arcMisses = 0;

while (1) { 

	my $arcHits = ${Kstat}->{zfs}->{0}->{arcstats}->{hits};
	my $arcMisses = ${Kstat}->{zfs}->{0}->{arcstats}->{misses};
	my $time = time();
	
	unless ($last_arcHits == 0) {
	
		my $hps = ($arcHits - $last_arcHits) / $interval;
		my $mps = ($arcMisses - $last_arcMisses) / $interval;

		#print("$time: Hits per second: $hps ($hits)\n");
		#print("$time: Misses per second: $mps ($misses)\n\n");

		$sock->send("${KEY_PREFIX}.arc_count_hits $hps $time\n${KEY_PREFIX}.arc_count_misses $mps $time\n") or die "Send error: $!\n";
	}
	

	$last_arcHits   = $arcHits;
	$last_arcMisses = $arcMisses;

        sleep($interval);
        $Kstat->update();
}
