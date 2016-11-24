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
        my @columns = split(" ", $line);
        my $option  = $columns[0];

        if (defined($option))
        {
            if ($option =~ /-W[^=]+[^-]$/) { $valid_options{$option} = (); }
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

sub main()
{
    my %options     = get_warning_options();
    my %cpp_options = get_cpp_options(%options);

    printf("C++ warnings options found: %d\nHere is the list:\n%s\n",
        scalar(keys(%cpp_options)),
        join(" ", keys(%cpp_options)));
}

main();

