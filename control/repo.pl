#!/usr/bin/perl

use utf8;
use strict;
use warnings FATAL => 'uninitialized';
use CGI qw/:all *table *pre/;
use CGI::Carp 'fatalsToBrowser';

binmode(STDOUT, ':utf8');
binmode(STDERR, ':utf8');

my $q = param('q')//'';

if($ENV{REQUEST_METHOD} eq 'POST' && param()) {
	if(param('delete')) {
		my $dist = param('dist');
		my $arch = param('arch');
		my $pkg = param('pkg');
		my @cmd = ('remove', $dist, $pkg);
		unshift @cmd, ('-A', $arch) if $arch;
		my $result = reprepro(@cmd);
		print redirect($ENV{HTTP_REFERER});
	} else {
		print h1('Unimplemented');
	}
	exit 0;
}

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

print h1('Packages repository');

print div(ul({-class=>'hor'}, li([
#	a({-href=>url(-relative=>1)}, 'Reload'),
	a({-href=>"jobs.pl"}, 'Jobs list'),
])));


if($q !~ /^\w+$/) {
	queues_list();
} elsif(param('dist')) {
	packages_list(param('dist'));
} elsif(param('pkg')) {
	packages_search(param('pkg'));
} else {
	dists_list();
}

print end_html();

sub reprepro
{
	open P, '-|', "sudo -u deb /home/deb/reprepro.sh $q @_" or die;
	my @lines;
	while(<P>) {
		chomp;
		push @lines, $_;
	}
	close P;
	return \@lines;
}

sub dists_list
{
	my $lines = reprepro('sizes');
	print p(a({-href=>"repo.pl"}, 'Repository'), '&gt;', $q);
	print p(start_form({-method=>'GET'}).'Search for package: '.hidden(-name=>'q', -value=>$q).textfield(-name=>'pkg', -force=>1).submit.end_form);
	print start_table;
	print Tr(th([split /\s+/, shift(@$lines)]));
	foreach(@$lines) {
		$_ = [split /\s+/, $_];
		$_->[0] = a({-href=>"repo.pl?q=$q\&dist=$_->[0]"}, $_->[0]);
		print Tr(td($_));
	}
	print end_table;
	print p('Browse '.a({-href=>"/$q/pool"}, 'pool'));
}

sub packages_list
{
	my($dist) = @_;
	die unless $dist =~ /^[a-z]+$/;
	my $lines = reprepro('list', $dist);
	print p(a({-href=>"repo.pl"}, 'Repository'), '&gt;', a({-href=>"repo.pl?q=$q"}, $q), '&gt;', $dist);
	print start_table({-class=>'striped'});
	print Tr(th([qw(Component Arch Package Version Action)]));
	foreach(@$lines) {
		$_ = [/^(\w+)\|(\w+)\|(\w+): (\S*) (.*)/];
		shift @$_;
		$_->[2] = a({-href=>"repo.pl?q=$q\&pkg=$_->[2]"}, $_->[2]);
		my $pform = start_form({-method=>'POST'}).hidden(-name=>'q', -value=>$q).hidden(-name=>'dist', -value=>$dist).hidden(-name=>'arch', -value=>$_->[1]).hidden(-name=>'pkg', -value=>$_->[2]).hidden(-name=>'ver', -value=>$_->[3]).submit(-name=>'delete', -value=>'Delete').end_form;
		print Tr(td($_), td($pform));
	}
	print end_table;
}

sub queues_list
{
	my @queues = qw( vir nightly );
	print p('Repository');
	print start_ul;
	foreach(@queues) {
		print li(a({-href=>"repo.pl?q=$_"}, $_));
	}
	print end_ul;
}

sub packages_search
{
	my($pkg) = @_;
	$pkg =~ s/^\W+//;
	$pkg =~ s/[^a-z0-9-].*$//;
	my $lines = reprepro('ls', $pkg);
	print p(a({-href=>"repo.pl"}, 'Repository'), '&gt;', a({-href=>"repo.pl?q=$q"}, $q), '&gt;', $pkg);
	print start_table({-class=>'striped'});
	print Tr(th([qw(Package Version Dist Archs Action)]));
	foreach(@$lines) {
		$_ = [split /\s*\|\s*/, $_];
		my $pform = start_form({-method=>'POST'}).hidden(-name=>'q', -value=>$q).hidden(-name=>'dist', -value=>$_->[2]).hidden(-name=>'pkg', -value=>$_->[0]).hidden(-name=>'ver', -value=>$_->[1]).submit(-name=>'delete', -value=>'Delete').end_form;
		$_->[2] = a({-href=>"repo.pl?q=$q\&dist=$_->[2]"}, $_->[2]);
		print Tr(td($_), td($pform));
	}
	print end_table;
}

sub now
{
	my($ss, $mm, $hh, $day, $month, $year) = localtime();
	$year+=1900; $month+=1;
	#return sprintf('%04d-%02d-%02d %02d:%02d:%02d', $year, $month, $day, $hh, $mm, $ss);
	return sprintf('%04d-%02d-%02d', $year, $month, $day);
}


