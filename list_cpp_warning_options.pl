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

sub get_cmd_arguments
{
    my %arguments;

    foreach my $argument (@ARGV)
    {
        if    ($argument eq "--print-descriptions") { $arguments{"print_descriptions"} = 1;           }
        elsif ($argument eq "--enabled-only")       { $arguments{"enabled_only"}       = 1;           }
        elsif ($argument eq "--disabled-only")      { $arguments{"disabled_only"}      = 1;           }
        elsif ($argument =~ /-W(no-)?/)             { push(@{$arguments{"gcc_warnings"}}, $argument); }
        else                                        { die("Unknown argument: $argument");             }
    }

    if ($arguments{"enabled_only"} && $arguments{"disabled_only"})
    {
        die("Options `--enabled-only` and `--disabled-only` cannot be used together");
    }

    return %arguments;
}

sub filter_options
{
    my $arguments   = shift;
    my $cpp_options = shift;

    my $gcc_warnings = $arguments->{"gcc_warnings"}
               ? join(" ", @{$arguments->{"gcc_warnings"}})
               : "";
    my $filter = $arguments->{"enabled_only"}  ? "enabled"
               : $arguments->{"disabled_only"} ? "disabled"
               : "";

    my @lines          = split("\n", `gcc $gcc_warnings -Q --help=warnings`);
    my @filtered_lines = grep(/$filter/, @lines);

    my %filtered_options;
    foreach my $line (@filtered_lines)
    {
        my $option = (split(" ", $line))[0];
        if ($cpp_options->{$option})
        {
            $filtered_options{$option} = $cpp_options->{$option};
        }
    }

    return %filtered_options;
}

sub main()
{
    my %arguments = get_cmd_arguments();

    my %options          = get_warning_options();
    my %cpp_options      = get_cpp_options(%options);
    my %filtered_options = filter_options(\%arguments, \%cpp_options);

    print_options(%filtered_options, $arguments{"print_descriptions"});
}

main();

