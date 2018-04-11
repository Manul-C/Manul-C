#

use ManulCTest;
use Data::Dumper;
require ManulC::App;

my $app = ManulC::App->new;
ok( defined $app, "application object created" );

is( $app->extMgr->namePrefix, 'ManulC::Ext', "expected extension name prefix" );

$app->extMgr->_set_namePrefix( 'ManulC::Plugs::' );

like( $app->extMgr->namePrefix, 'ManulC::Plugs', "extension name prefix coercion" );

my @testDirs = qw<./t/data/extMgr/lib ./t/data/extMgr/lib2>;
$ENV{MANULC_EXTDIRS} = join( ':', @testDirs );
$app = ManulC::App->new;
is( $app->extMgr->extDirs, \@testDirs, "MANULC_EXTDIRS works" );
delete $ENV{MANULC_EXTDIRS};

$app = ManulC::App->new;
$app->extMgr->loadExtensions;

done_testing;
