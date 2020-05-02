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
use List::Util qw( min max );

#####
## PROTOS
#####
sub extractScore ($);	# Filename
sub statsCalc(@);	# array of values to stat

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
		push (@scores, extractScore ("$SEARCHDIR/$file"));
	}
}
closedir ($dh);

my ($max, @stats) = statsCalc(@scores);

my $graph = GD::Graph::bars->new(800, 600);
$graph->set(
	transparent			=> 0,
	x_label				=> 'Score',
	y_label				=> 'Occurences',
	x_label_position	=> 1,
	y_label_position	=> 0,
	title				=> 'Spam Statistics',
	logo				=> 'logo.png',
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
open(IMG, '>', 'graph.png') or die $!;
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

	open(my $fh, "<", $filename)
		or die "Can't open $filename $!\n";
	while (<$fh>) {
		my $line = $_;
		chomp ($line);
		if ( $line =~ /^X-Spam-Status: [NoYes]+, score=([0-9.-]+)/) {
			chomp ($1);
			$result = $1;
			last;
		}
	}
	close ($fh);
	return $result;
}

sub statsCalc(@) {	# array of values to stat, returns Y max, array to plot
	my @values = @_;
	my %stats;
	my @xplot;
	my @yplot;
	my @stats;

	my $min = int (min (@values));
	my $max = int (max (@values));

# Init hash;
	for (my $i=$min; $i<=$max; $i++) {
		$stats{$i} = 0;
	}
# get values
	foreach my $value (@values) {
		my $val = int($value);
		#~ $val = sprintf "%1f", int($value);
		#~ $val = int($val);
		$stats{$val}++,
	}
# Extract X, Y
	foreach my $value ( keys %stats) {
		$xplot[$value-$min] = int($value);
		$yplot[$value-$min] += $stats {$value};
	}
	$stats[0] = \@xplot;
	$stats[1] = \@yplot;
	return (max(@yplot), @stats);
}

=pod

=head1 NAME

SpamStats : Graph score distribution

=head1 AUTHOR

Xavier Humbert <xavier-at-amdh-dot-fr>

=cut
