#!/usr/bin/perl -w

use strict;
use warnings;

use File::Temp qw(tempfile);

sub get_warning_options
{
    my %valid_options;

    my $output = `gcc --help=warnings`;
    my @lines  = split("\n", $output);

    foreach my $line (@lines)
    {
        my @columns     = split(" ", $line);
        my $option      = shift @columns;
        my $description = join(" ", @columns);

        if (defined($option))
        {
            if ($option =~ /-W[^=]+[^-]$/) { $valid_options{$option} = $description;}
            if ($option =~ /(-W.*)=$/) { delete($valid_options{$option}); }
        }
    }

    return %valid_options;
}

sub get_cpp_options
{
    my %options = @_;

    my (undef, $filename) = tempfile();
    my $output = `gcc -x c++ -fsyntax-only ${\join(" ", keys(%options))} $filename 2>&1`;

    my @lines  = split("\n", $output);
    foreach my $line (@lines)
    {
        if ($line =~ /command line option ‘(.*)’ is valid/)
        {
            delete($options{$1});
        }
    }

    return %options;
}

sub print_options
{
    my $print_descriptions = pop(@_);
    my %options            = @_;

    foreach my $option (keys(%options))
    {
        $print_descriptions
            ? printf("  %-35s %s\n", $option, $options{$option})
            : print($option, " ");
    }

    print "\n";
}

sub main()
{
    my $print_descriptions = grep(/--print-descriptions/, @ARGV);

    my %options     = get_warning_options();
    my %cpp_options = get_cpp_options(%options);

    print_options(%cpp_options, $print_descriptions);
}

main();

