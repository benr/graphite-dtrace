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
my $GRAPHITE_SERVER = "graphite.joyent.com";
my $GRAPHITE_PORT   = 2003;
my $POD = "ev2";



if ( ! $ARGV[0] ) {
        die("USAGE: $0 <nfsv3_operation>\n");
}
my $METRIC = $ARGV[0];

my $HOSTNAME = `hostname`;
chomp($HOSTNAME);
$HOSTNAME =~ s/.joyent.com//;

## Prep the socket
my $sock = IO::Socket::INET->new(
    Proto    => 'tcp',
    PeerPort => $GRAPHITE_PORT,
    PeerAddr => $GRAPHITE_SERVER,
) or die "Could not create socket: $!\n";


while(<STDIN>) {
  chomp($_);
  $_ =~ s/^\s+//; # Trim any leading whitespace
  my ($EXPORT,$VALUE,$OTHER) = split(/\s+/, $_, 3);


  ### Sanity check on the input data
  if ($OTHER) {
       # print("I got some other crap here: $OTHER (Input: $_)\n");
        next;
  }
  if ($EXPORT !~ m/\w+/) {
       # print("Export looks wrong: $EXPORT (Input: $_)\n");
        next;
  }
  if ($VALUE !~ m/\d+/) {
       # print("Value looks wrong: $VALUE (Input: $_)\n");
        next;
  }

  my $KEY = "joyent.${POD}.${HOSTNAME}.exports.${EXPORT}.latency_${METRIC}";

  $DATE = time();
  #print("Sending: $KEY $VALUE $DATE\n");
  $sock->send("$KEY $VALUE $DATE\n") or die "Send error: $!\n";

}

print("All done.  I\'m outta here.\n");
