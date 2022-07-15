#!/usr/bin/perl -w

#######################################################################
# $Id: spamstats.pl, v1.0 r1 02.05.2020 06:03:49 CEST XH Exp $
#
# Copyright 2020 Xavier Humbert <xavier@amdh.fr>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
# MA  02110-1301, USA.
#
#######################################################################

use strict;
use GD::Graph::bars;
use POSIX qw(strftime);

#####
## PROTOS
#####
sub extractScore ($);	# Filename
sub statsCalc(@);	# array of values to stat
sub Min (@);
sub Max (@);

#####
## CONSTANTS
#####
our $USER = "xavier";
our $SEARCHDIR = "/home/$USER/Maildir/.Junk/cur";

#####
## VARIABLES
#####
my $rc=0;
my @scores = ();

#####
## MAIN
#####

opendir (my $dh, $SEARCHDIR)
	or die "Could not open '$SEARCHDIR' for reading: $!\n";
while (my $file = readdir $dh) {
	next if $file =~ /^[.]/;
	if (-f "$SEARCHDIR/$file") {
		my $score = extractScore ("$SEARCHDIR/$file");
		push (@scores, $score) if ($score != -999);
	}
}
closedir ($dh);

my ($max, @stats) = statsCalc(@scores);
my $xlabel = sprintf ("%s %s", "Score on ", strftime ('%Y-%m-%d %T', localtime()));

my $graph = GD::Graph::bars->new(800, 600);
$graph->set(
	transparent			=> 0,
	x_label				=> $xlabel,
	y_label				=> 'Occurences',
	x_label_position	=> 1,
	y_label_position	=> 0,
	title				=> 'Spam Statistics',
	logo				=> '/root/bin/spamstats/logo.png',
	logo_position		=> 'UL',
	logo_resize			=> 0.33,
) or die $graph->error;

$graph->set(
	accentclr		=> 'black',
	boxclr			=> undef,
	fgclr			=> 'lgray',
	borderclrs		=> 'lgray',
	shadowclr		=> 'dgreen',
	shadow_depth	=> 1,
	bgclr			=> 'black',
	dclrs			=> ['dgreen'],
	labelclr		=> 'lgray',
	axislabelclr	=> 'lgray',
	legendclr		=> 'lgray',
	valuesclr		=> 'lgray',
	textclr			=> 'lgray',
) or die $graph->error;

$graph->set(
	y_number_format	=> "%i",
	bar_spacing		=> 5,
	x_plot_values	=>1,
	y_plot_values	=>1,
	y_max_value		=> int($max+$max/100),
	y_tick_number	=> 10,
	x_long_ticks	=> 0,
	y_long_ticks	=> 1,
	y_label_skip	=> 2,
) or die $graph->error;

my $gd = $graph->plot(\@stats) or die $graph->error;
open(IMG, '>', '/usr/local/www/html/groumpf.org/FreeBSD/graph.png') or die $!;
binmode IMG;
print IMG $gd->png;
close IMG;

exit ($rc);

#######################################################################

#####
## FUNCTIONS
#####

sub extractScore ($) {	# Filename, Expression, returns score
	my $filename = shift;
	my $result = '';
	my $found = 0;

	open(my $fh, "<", $filename)
		or die "Can't open $filename $!\n";
	while (<$fh>) {
		my $line = $_;
		chomp ($line);
		if ( $line =~ /^X-Spam-Status: [NoYes]+, score=([0-9.-]+)/) {
			chomp ($1);
			$result = $1;
			$found = 1;
			last;
		}
	}
	close ($fh);
	return $found ? $result : -999;
}

sub statsCalc(@) {	# array of values to stat, returns Y max, array to plot
	my @values = @_;
	my %stats;
	my @xplot;
	my @yplot;
	my @stats;

	my $min = int (Min (\@values));
	my $max = int (Max (\@values));

# Init hash;
	for (my $i=$min; $i<=$max; $i++) {
		$stats{$i} = 0;
	}
# get values
	foreach my $value (@values) {
		$stats{int($value)}++,
	}
# Extract X, Y
	foreach my $value ( keys %stats) {
		$xplot[$value-$min] = int($value);
		$yplot[$value-$min] += $stats {$value};
	}
	$stats[0] = \@xplot;
	$stats[1] = \@yplot;
	return (Max(\@yplot), @stats);
}


sub Min (@) {
	my $arrayRef = shift;
	my $ret = $arrayRef->[0];
	foreach my $value (@{$arrayRef}) {
		$ret = $value if ($value < $ret );
	}
	return $ret;
}

sub Max (@) {
	my $arrayRef = shift;
	my $ret = $arrayRef->[0];
	foreach my $value (@{$arrayRef}) {
		$ret = $value if ($value > $ret );
	}
	return $ret;
}

=pod

=head1 NAME

SpamStats : Graph score distribution

=head1 AUTHOR

Xavier Humbert <xavier-at-amdh-dot-fr>

=cut
