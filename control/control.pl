#!/usr/bin/perl

use utf8;
use strict;
use warnings FATAL => 'uninitialized';
use CGI qw/:all *table *pre/;
use CGI::Carp 'fatalsToBrowser';

binmode(STDOUT, ':utf8');
binmode(STDERR, ':utf8');

print header(
	-type=>"text/html; charset=UTF-8",
);
print start_html(
	-lang=>'ru-RU',
	-title=>$0,
	-author=>'vir@ctm.ru',
	-style=>{'src'=>'style.css'},
);

#print pre(`env`);
#print pre(`id`);

print h1('Incoming queues');

print div(ul({-class=>'hor'}, li([
	a({-href=>url(-relative=>1)}, 'Reload'),
	a({-href=>"jobs.pl"}, 'Jobs list'),
	a({-href=>"/logs/".now()}, 'Today build logs'),
])));

if(param()) {
	my @togo = param('name');
	my $q = param('queue');
	$q =~ s/^\s*(\w+).*$/$1/s if defined $q;
	if(param('start')) {
		jobs_start($q, @togo);
	} elsif(param('purge')) {
		jobs_purge($q, @togo);
	} elsif(param('pushqueue')) {
		my $cmd = "/usr/bin/sudo -u deb /home/deb/pushqueue.sh";
		print "\nExecuting: $cmd\n";
		system($cmd) == 0 or print p({-class=>'error'}, 'Failed');
	} else {
		print p({-class=>'error'}, 'Somthing wrong');
	}
	print p(a({-href=>url(-relative=>1)}, "Back..."));
}

sub jobs_start
{
	my($queue, @pkgs) = @_;
	foreach(@pkgs) {
		my $cmd = "/usr/bin/sudo -u deb /home/deb/startbuild.pl $queue $_";
		print start_pre();
		print "\nExecuting: $cmd\n";
		open CMD, "$cmd |" or die "Can't start $cmd: $!";
		my $log;
		while(<CMD>) {
			if(/^\s*BuildLogs:\s*(.*)?\s*/s) { chomp($log = $1); }
			print $_;
		}
		close CMD;
		print end_pre();
		print p(a({-href=>"/logs/$log"}, 'Log File')) if $log;
	}
}

sub jobs_purge
{
	my($queue, @pkgs) = @_;
	chdir "/home/deb/inq/$queue" or die;
	foreach my $p(@pkgs) {
		my @l = glob "$p*";
		unlink @l;
	}
}

foreach my $queue(qw( nightly releases vir )) {
	chdir "/home/deb/inq/$queue" or die;
	my %l = map { $_ => 86400 * -M($_) } glob("*");
	my @changes = grep { /_source.changes$/ } sort keys %l;

	print start_form();
	print h2($queue);
	if(@changes) {
		print start_table();
		print Tr(th([qw( * Name Version Age Ok )]))."\n";
		foreach my $f(@changes) {
			next unless $f =~ /(.*)_source.changes$/;
			my @errs;
			push @errs, 'No source archive' unless(grep { -f($1.$_) } qw( .tar.gz .tar.bz2 .tar.xz .debian.tar.xz ));
			push @errs, 'No .dsc file' unless -f($1.'.dsc');
			my($pn, $pv) = split('_', $1);
			print Tr(td(checkbox(-name=>'name', -value=>$1, -label=>'')), td($pn), td($pv), td($l{$f}.' seconds ago'), td(@errs?abbr({-title=>"@errs"}, 'BAD'):'Ok'))."\n";
		}
		print end_table();
		print hidden(-name=>'queue', -value=>$queue, -force=>1);
		print submit(-name=>'start', -value=>'Start building');
		print submit(-name=>'purge', -value=>'Remove selected');
	} else {
		print p('Empty');
	}
	print end_form();
}
print end_html();

sub now
{
	my($ss, $mm, $hh, $day, $month, $year) = localtime();
	$year+=1900; $month+=1;
	#return sprintf('%04d-%02d-%02d %02d:%02d:%02d', $year, $month, $day, $hh, $mm, $ss);
	return sprintf('%04d-%02d-%02d', $year, $month, $day);
}


