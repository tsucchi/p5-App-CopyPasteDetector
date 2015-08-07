use strict;
use warnings;

use App::CopyPasteDetector;
use Test::More;
use File::Spec;
use Capture::Tiny qw(capture_stdout);

my $hello1 = File::Spec->catfile('t', 'data', 'hello1.pl');
my $hello2 = File::Spec->catfile('t', 'data', 'hello2.pl');
my $hello3 = File::Spec->catfile('t', 'data', 'hello3.pl'); #hello3 is defferent from hello1 in (meaningless) 1 semicoron

# subtest 'run file', sub {
#     my $app = App::CopyPasteDetector->new();
#     my $stdout1 = capture_stdout {
#         $app->run($hello1, $hello2);
#     };
#     is( $stdout1, "0\n" );

#     my $stdout2 = capture_stdout {
#         $app->run($hello1, $hello3);
#     };
#     is( $stdout2, "1\n" );
# };


# subtest 'run dir', sub {
#     my $app = App::CopyPasteDetector->new();
#     my ($stdout) = capture_stdout {
#         $app->run( File::Spec->catdir('t', 'data') );
#     };
#     my $expected = ".------------------------------------------------------------.\n";
#     $expected   .= "| file1            | file2            | Levenshtein Distance |\n";
#     $expected   .= "+------------------+------------------+----------------------+\n";
#     $expected   .= "| t/data/hello1.pl | t/data/hello2.pl |                    0 |\n";
#     $expected   .= "| t/data/hello1.pl | t/data/hello3.pl |                    1 |\n";
#     $expected   .= "| t/data/hello2.pl | t/data/hello3.pl |                    1 |\n";
#     $expected   .= "'------------------+------------------+----------------------'\n";

#     is( $stdout, $expected);
# };


# subtest 'distance_all_files', sub {
#     my $app = App::CopyPasteDetector->new();
#     my @result = $app->distance_all_files([$hello1, $hello2, $hello3]);
#     my $expected = [
#         [$hello1, $hello2, 0],
#         [$hello1, $hello3, 1],
#         [$hello2, $hello3, 1],
#     ];
#     is_deeply( \@result, $expected );
# };

subtest 'distance_between_files', sub {
    my $app = App::CopyPasteDetector->new();
    is( $app->distance_between_files($hello1, $hello2), 0);
    is( $app->distance_between_files($hello1, $hello3), 1);
};

subtest 'distance', sub {
    my $app = App::CopyPasteDetector->new();

    my @v1 = split '', 'sherlock';
    my @v2 = split '', 'shellshock';
    # 1 replace, 2 delete : total cost is 3
    is( $app->distance(\@v1, \@v2), 3);
};

subtest 'token_types', sub {
    my $app = App::CopyPasteDetector->new();
    my $types = $app->token_types($hello1);
    my $expected = [
        93, # use
        94, # strict
        106,# ;
        93, # use
        94, # warnings
        106,# ;
        70, # print
        172,# "Hello World!\n"
        106,# ;
    ];
    is_deeply( $expected, $types );
};


done_testing;
