#!/usr/bin/perl

use utf8;
use strict;
use warnings FATAL => 'uninitialized';
use CGI qw/:all *table *pre *div *ul/;
use CGI::Carp 'fatalsToBrowser';

binmode(STDOUT, ':utf8');
binmode(STDERR, ':utf8');

my $script = << '***';
function resize_handler()
{
	var v = document.getElementById("view");
	var l = document.getElementById("jobslist");

	// set full iframe width
	v.style.width = (l.offsetLeft - 20) + 'px';

	// set full iframe height
	v.style.height = (window.innerHeight - v.offsetTop - 20) + 'px';

	// set list height
	l.style.height = (window.innerHeight - l.offsetTop - 20) + 'px';

	// scroll list to bottom
	l.scrollTop = l.scrollHeight;

	// scroll log to bottom
	//scrollBottom(v);
}
function frameLoad(e)
{
	scrollBottom(e);
}
function scrollBottom(e)
{
	var doc = e.contentWindow ? e.contentWindow.document : e.contentDocument;
	var h = doc.compatMode != 'CSS1Compat' ? doc.body.scrollHeight : doc.documentElement.scrollHeight;
	e.contentWindow.scrollTo(0, h);
}
***

print header(
	-type=>"text/html; charset=UTF-8",
);
print start_html(
	-lang=>'ru-RU',
	-title=>$0,
	-author=>'vir@ctm.ru',
	-style=>{'src'=>'style.css'},
	-script=>{code=>$script},
	-onLoad=>'window.onresize = resize_handler; resize_handler();',
);

#print pre(`env`);
#print pre(`id`);

my $h = "/home/deb/";

my @jobs;
my $time = time();
my @labels = qw( Today Yesterday );
for(;;) {
	my $d = date($time);
	my @j = get_jobs_for_date($d);
	unshift @jobs, @j;
	unshift @jobs, shift(@labels) || $d;
	last if @jobs > 35;
	$time -= 86400;
}
my @w = get_waiting_jobs();
if(@w) {
	push @jobs, 'Waiting';
	push @jobs, @w;
}

print start_div({-style=>'float:right'});
print start_form({-method=>'post', -action=>'control.pl'});
print submit(-name=>'pushqueue', -value=>'Push queue');
#print button(-onClick=>"frameLoad(getElementById('view'))", -value=>'frameLoad()');
print end_from;
print end_div."\n";

print h1('Recent jobs');
print start_div({-id=>'jobslist'}).start_table."\n";
foreach my $j(@jobs) {
	if(ref($j)) {
		my $status = pop @$j;
		print Tr({-class=>lc $status}, td($j), td($status))."\n";
	} else {
		print Tr(td({-colspan=>5}, $j))."\n";
	}
}
print end_table.end_div."\n";

print div(ul({-class=>'hor'}, li([
	a({-href=>url(-relative=>1)}, 'Reload'),
	a({-href=>"control.pl"}, 'Incoming queues'),
	a({-href=>"repo.pl"}, 'Packages repository'),
	a({-href=>"/logs/".date(), -target=>'view'}, 'Today build logs'),
])))."\n";

print iframe({-id=>'view', -name=>'view', -style=>'width:50%; height:100%;', -scrolling=>'auto', -onLoad=>'frameLoad(this);'})."\n";

print end_html();

sub get_jobs_for_date
{
	my($date) = @_;
	return map { load_job($_) } glob $h."/logs/$date/*";
}

sub load_job
{
	my($path) = @_;
	my($queue, $dist, $name, $log, $status, $arch);
	$log = $path; $log =~ s#.*/(?=\d{4}-\d\d-\d\d)##;
#warn "Check $path: ".join(' ', glob("$path/*"))."\n";
	if(open F, "< $path/job.txt") {
		my $d = <F>;
		close F;
		chomp $d;
		($queue, $dist, undef, $name, $arch) = split /\s+/, $d;
		$arch ||= '-';
	}
	my $id = $path; $id =~ s#.*/##;
	my @oks = glob "$path/*-OK.log";
	my @errs = glob "$path/*-ERROR.log";
#warn "Oks: (@oks)\n";
#warn "Errs:(@errs)\n";
	if(-d "$h/tasks/$id") {
		$status = 'Building';
	} elsif(@errs) {
		$status = 'Error';
	} elsif(@oks) {
		$status = 'Ok';
	} else {
		$status = 'Unknown';
	}
#warn "Status: $status\n";
	return [ a({-href=>"/logs/$log/build.log", -title=>$status, -target=>'view'}, $id), $queue, $name||'-', $dist||'-', $arch, $status ];
}

sub get_waiting_jobs
{
	my @tasks = glob $h."/tasks/*";
	my $d = date(time());
	my @wjobs = grep { s#.*/##; !/\D/ && ! -d $h."/logs/$d/$_" } @tasks;
	my @r;
	foreach my $id(@wjobs) {
		my($dist, $name, $status, $queue);
		if(open F, "< $h/tasks/$id/queue") {
			my $queue = <F>;
			close F;
			chomp $queue;
		}
		my($chf) = glob "$h/tasks/$id/*_source.changes";
		if($chf) {
			open F, $chf or warn;
			while(<F>) {
				chomp;
				if(/^Distribution:\s*(.*)/) { $dist = $1; }
			}
			close F;
			if($chf =~ /.*\/(\S+)_source.changes$/) {
				$name = $1;
			}
			$status = 'Waiting';
		} else {
			$status = 'Error';
		}
		push @r, [ $id, $queue||'-', ($name?$name.mk_start_button($id):'-'), $dist||'-', '-', $status ];
	}
	return @r;
}

sub mk_start_button
{
	my($id) = @_;
}

sub date
{
	my($ss, $mm, $hh, $day, $month, $year) = localtime($_[0] || time);
	$year+=1900; $month+=1;
	#return sprintf('%04d-%02d-%02d %02d:%02d:%02d', $year, $month, $day, $hh, $mm, $ss);
	return sprintf('%04d-%02d-%02d', $year, $month, $day);
}


