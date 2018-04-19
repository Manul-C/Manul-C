#

package ManulCTest;
require ManulC::App;
use Carp;

my $app        = ManulC::App->new;
my $specParser = $app->cfg->create( "ManulC::Config::Spec::Parser" );

$SIG{__DIE__} = sub { confess @_ };
$SIG{__WARN__} = sub { confess @_ };

$specParser->parse(
    specData => [
        -section => "Section One" => [
            -section => "Sub Section 1" => [
                "A.Cfg.Key" => [
                    -default => TRUE,
                    -expert,
                    -type => BOOLEAN,
                ],
                Split => [
                    Key => STRING => [
                        -default => "This is Split.Key",
                    ],
                ],
            ],
        ],
        -section => "Section Two" => [

        ],
    ],
);

done_testing;
