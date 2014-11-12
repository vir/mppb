#!/usr/bin/perl

use strict;
use warnings;
use File::CounterFile;
#use File::Path qw(mkpath);

die "Usage: $0 queue prefix\n" unless @ARGV == 2;
my($queue, $prefix) = @ARGV;

$queue =~ /^(\w+)$/ or die "Invalid queue $queue";
$queue = $1;

my $home = '/home/deb';

chdir "$home/inq/$queue" or die "Can't chdir to incoming: $!\n";
my @l = map { /(.*\..*)/ } glob("$prefix*");
die "Not enough files" unless -f "$prefix.dsc" and @l >= 3;

my $c = File::CounterFile->new("$home/BUILDCOUNTER", "000000");
my $id = $c->inc;
($id) = $id =~ /(.*)/; # untaint it

my $dir = $home.'/tasks/'.$id;
mkdir $dir or die "Can't create directory $dir: $!\n";
open Q, '>:utf8', "$dir/queue" or die "Can't create $dir/queue: $!\n";
print Q $queue, "\n";
close Q or die "Can't write to $dir/queue: $!\n";

foreach(@l) {
	rename $_, $dir.'/'.$_ or die "Can't move $_ into $dir: $!\n";
}

my $d = now();
my $logdir = "$home/logs/$d/$id";

open S, "> $home/buildqueue/$id.sh" or die;
print S "#!/bin/sh\ncd $dir\n";
print S "mkdir -p $logdir || exit 1\n";
print S "nohup $home/build_task.sh $id > $logdir/build.log 2>&1 &\n";
print S "exit 0\n";
close S or die;
chmod 0755, "$home/buildqueue/$id.sh";

$< = $>; # start as 'deb' user
system("$home/pushqueue.sh");

print "BuildPackage: $prefix\n";
print "BuildId: $id\n";
print "BuildLogs: $d/$id\n";
print "BuildQueue: $queue\n";

sub now
{
	my($ss, $mm, $hh, $day, $month, $year) = localtime();
	$year+=1900; $month+=1;
	#return sprintf('%04d-%02d-%02d %02d:%02d:%02d', $year, $month, $day, $hh, $mm, $ss);
	return sprintf('%04d-%02d-%02d', $year, $month, $day);
}

