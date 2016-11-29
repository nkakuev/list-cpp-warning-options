#!/usr/bin/perl -w

use strict;
use warnings;

use File::Temp qw(tempfile);

sub get_warning_options
{
    my %valid_options;

    my @lines  = split("\n", `gcc --help=warnings`);
    my $last_option = "";

    foreach my $line (@lines)
    {
        my @columns     = split(" ", $line);
        my $option      = shift @columns;
        my $description = join(" ", @columns);

        if (defined($option))
        {
            if ($option =~ /-W[^=]+[^-=]$/)
            {
                # Special case: although it's not specified, all options
                # that start with `-Wformat` require a mandatory argument
                # and thus should be ignored:
                if ($option !~ /-Wformat/)
                {
                    $valid_options{$option} = $description;
                    $last_option = $option;
                }
            }
            elsif ($option =~ /-W.+=$/)
            {
                # Sometimes GCC lists options that take arguments twice:
                # -Wstrict-overflow     Warn about optimizations ...
                # -Wstrict-overflow=    Warn about optimizations ...
                # So if we found `-Wstrict-overflow=` we should ignore it
                # and delete `-Wstrict-overflow` as well:
                delete($valid_options{$option});
            }
            elsif ($option !~ /^-/ && $last_option)
            {
                # Concatenate description if it was split into two lines:
                $line =~ s/^\s+//;
                $valid_options{$last_option} .= " $line";
            }
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
        if ($line =~ /command line option ‘(.+)’ is valid/)
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

    foreach my $option (sort(keys(%options)))
    {
        $print_descriptions
            ? printf("  %-35s %s\n", $option, $options{$option})
            : print($option, " ");
    }

    print "\n";
}

sub print_help
{
print << "END_HELP";
OVERVIEW: Print GCC warning options applicable to C++ code
USAGE:    $0 [options]
OPTIONS:
  -h, --help                Print this message.
  -p, --print-descriptions  Print option descriptions in the following format:
                            -Wuseless-cast        Warn about useless casts.
                            -Wunused-label        Warn when a label is unused.
                            ...
  -e, --enabled-only        Print only currently enabled warning options.
                            Useful to see what you have so far.
  -d, --disabled-only       Print only currently disabled warning options.
                            Useful to see what else can be enabled.
  GCC warning options       Assorted GCC warning options: -Wall, -Wextra,
                            -Wno-deprecated, etc.
                            Use with `--enabled-only` or `--disabled-only`.

  Options `--enabled-only` and `--disabled-only` cannot be used together.
END_HELP
}

sub get_cmd_arguments
{
    my %arguments;

    foreach my $argument (@ARGV)
    {
        if ($argument eq "-h" || $argument eq "--help")
        {
            print_help();
            exit(0);
        }
        elsif ($argument eq "-p" || $argument eq "--print-descriptions")
        {
            $arguments{"print_descriptions"} = 1;
        }
        elsif ($argument eq "-e" || $argument eq "--enabled-only")
        {
            $arguments{"enabled_only"} = 1;
        }
        elsif ($argument eq "-d" || $argument eq "--disabled-only")
        {
            $arguments{"disabled_only"} = 1;
        }
        elsif ($argument =~ /-W(no-)?/)
        {
            push(@{$arguments{"gcc_warnings"}}, $argument);
        }
        else
        {
            print("Unknown argument: $argument\n");
            print_help();
            exit(1);
        }
    }

    if ($arguments{"enabled_only"} && $arguments{"disabled_only"})
    {
        print_help();
        exit(1);
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

sub main
{
    my %arguments = get_cmd_arguments();

    my %options          = get_warning_options();
    my %cpp_options      = get_cpp_options(%options);
    my %filtered_options = filter_options(\%arguments, \%cpp_options);

    print_options(%filtered_options, $arguments{"print_descriptions"});
}

main();

