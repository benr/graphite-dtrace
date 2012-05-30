#!/usr/perl5/bin/perl
#
# GraphiteAssist v0.1
# <benr@joyent.com>  8/5/11
#
# The primary purpose is to provide a way
# for DTrace Aggregates to be injected into Graphite
#

use IO::Socket;

## Default Values:
my $POD = "ev3";
my $GRAPHITE_SERVER = "graphite.joyent.com";
my $GRAPHITE_PORT   = 2003;




if ( ! $ARGV[0] ) {
	die("USAGE: $0 <zonename>\n");
} 

my $ZONE = $ARGV[0];
my $HOSTNAME = `hostname`; 
chomp($HOSTNAME);
$HOSTNAME =~ s/.joyent.com//;
my $KEY_PREFIX = "joyent.${POD}.${HOSTNAME}.${ZONE}.mysql";

## Prep the socket
my $sock = IO::Socket::INET->new(
    Proto    => 'tcp',
    PeerPort => $GRAPHITE_PORT,
    PeerAddr => $GRAPHITE_SERVER,
) or die "Could not create socket: $!\n";


	

while(<STDIN>) {
  chomp($_);
  my ($DATE,$QUERIES,$LATENCY,$SLOW) = split(/\s+/);

  # Sanity check (catches unexpected input of various types)
  unless ( $DATE > 1313100000 ) {
	next;
  }

  #print("I saw $QUERIES at $DATE, with avg latency of $LATENCY, and $SLOW slow queries.\n");


  #print("Sending:\n${KEY_PREFIX}.queries_count_all $QUERIES $DATE\n${KEY_PREFIX}.queries_latency_avg $LATENCY $DATE\n${KEY_PREFIX}.queries_count_slow $SLOW $DATE\n");
  $sock->send("${KEY_PREFIX}.queries_count_all $QUERIES $DATE\n${KEY_PREFIX}.queries_latency_avg $LATENCY $DATE\n${KEY_PREFIX}.queries_count_slow $SLOW $DATE\n") or die "Send error: $!\n";

}

print("All done.  I\'m outta here.\n");
