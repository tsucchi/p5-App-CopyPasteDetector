package App::CopyPasteDetector;
use 5.008001;
use strict;
use warnings;

use List::Util qw(min);
use List::MoreUtils qw(uniq);
use Compiler::Lexer;
use Carp qw();
use File::Find;

our $VERSION = "0.01";

sub new {
    my ($class) = @_;
    my $self = {
        cache => {},
    };
    bless $self, $class;
}

sub run {
    my ($self, @args) = @_;
    if ( scalar(@args) == 2 && -f $args[0] && -f $args[1] ) {
        print $self->distance_between_files($args[0], $args[1]) . "\n";
        return;
    }

    my @dirs = grep { -d $_ } @args;
    my @files = $self->_find_all_perl_files(@dirs);
    # TODO: switch algorithms by command line option
    $self->distance_all_files(\@files);
}

sub distance_all_files {
    my ($self, $files_aref) = @_;

    for my $file1 ( @{ $files_aref } ) {
        for my $file2 ( @{ $files_aref } ) {
            next if ( $file1 eq $file2 );
            next if ( $file1 gt $file2 );

            #my $difference = $self->distance_between_files($file1, $file2);
            my $difference = $self->difference_token_frequency_between_files($file1, $file2);
            print "$file1,$file2,$difference\n";
        }
    }
}

sub difference_token_frequency_between_files {
    my ($self, $file1, $file2) = @_;
    my $freqs1 = $self->token_freqs_ngram($file1, 2);
    my $freqs2 = $self->token_freqs_ngram($file2, 2);
    my $diff = $self->difference_token_frequency($freqs1, $freqs2);
    return $diff;
}

sub difference_token_frequency {
    my ($self, $freqs1, $freqs2) = @_;
    my @types = (keys %{ $freqs1 }, keys %{ $freqs2 });
    my $result = 0;
    for my $type ( uniq sort @types ) {
        my $freq1 = $freqs1->{$type} || 0;
        my $freq2 = $freqs2->{$type} || 0;
        $result += abs($freq1 - $freq2);
    }
    return $result;
}

sub distance_between_files {
    my ($self, $file1, $file2) = @_;
    my $token_types1 = $self->token_types($file1);
    my $token_types2 = $self->token_types($file2);
    my $distance = $self->distance($token_types1, $token_types2);
    return $distance;
}

# compute Levenshtein Distance using DP
sub distance {
    my ($self, $vector1, $vector2) = @_;

    my $size1 = scalar(@{ $vector1 });
    my $size2 = scalar(@{ $vector2 });

    my $result;
    for (my $i=0; $i<$size1; $i++) {
        $result->[$i]->[0] = $i;
    }
    for (my $i=0; $i<$size2; $i++) {
        $result->[0]->[$i] = $i;
    }

    for (my $i=1; $i<$size1; $i++) {
        for (my $j=1; $j<$size2; $j++) {
            my $cost = $vector1->[$i-1] eq $vector2->[$j-1] ? 0 : 1;
            $result->[$i]->[$j] = min(
                $result->[$i-1]->[$j] + 1,
                $result->[$i]->[$j-1] + 1,
                $result->[$i-1]->[$j-1] + $cost
            );
        }
    }
    return $result->[$size1-1]->[$size2-1];
}

sub token_types {
    my ($self, $filename) = @_;
    my $tokens = $self->_tokens($filename);
    my @result = map { $_->type } @{ $tokens };
    return \@result;
}

sub token_freqs {
    my ($self, $filename) = @_;
    my $tokens = $self->_tokens($filename);
    my %result = ();
    for my $token ( @{ $tokens } ) {
        $result{ $token->type }++;
    }
    return \%result;
}

sub token_freqs_ngram {
    my ($self, $filename, $n) = @_;
    if( exists $self->{cache}->{$filename} ) {
        return $self->{cache}->{$filename};
    }

    my $tokens = $self->_tokens($filename);
    my @buffer = ();
    my $result = {};
    for my $token ( @{ $tokens } ) {
        if ( scalar(@buffer) >= $n ) {
            shift @buffer;
        }
        push @buffer, $token->type;
        my $key = join ':', @buffer;
        $result->{$key}++;
    }
    $self->{cache}->{$filename} = $result;
    return $result;
}


sub _tokens {
    my ($self, $filename) = @_;
    open my $fh, '<', $filename or Carp::croak "can't open $filename : $!";
    my $script = do { local $/; <$fh> };
    my $lexer = Compiler::Lexer->new();
    my $tokens = $lexer->tokenize($script);
    return $tokens;
}

sub _find_all_perl_files {
    my ($self, @dirs) = @_;
    my @files;
    for my $dir ( @dirs ) {
        my @found = $self->_find_perl_files($dir);
        @files = (@found, @files);
    }
    @files = uniq sort @files;
    return @files;
}

sub _find_perl_files {
    my ($self, $dir) = @_;
    if ( !defined $dir ) {
        $dir = '.';
    }
    my @result;
    find( {
        no_chdir => 1,
        wanted   => sub {
            if ( $_ =~ /\.(pl|pm|t)$/i ) {
                push @result, $_
            }
        }
    }, $dir);
    return @result;
}


1;
__END__

=encoding utf-8

=head1 NAME

App::CopyPasteDetector - It's new $module

=head1 SYNOPSIS

    use App::CopyPasteDetector;

=head1 DESCRIPTION

App::CopyPasteDetector is ...

=head1 METHODS

=head2 my $value = $self->distance($aref1, $aref2);

calculate Levenshtein Distance between $aref1 and $aref2

=head1 LICENSE

Copyright (C) Takuya Tsuchida.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Takuya Tsuchida E<lt>tsucchi@cpan.orgE<gt>

=cut

