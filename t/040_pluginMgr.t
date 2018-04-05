#

use ManulCTest;
use Data::Dumper;
require ManulC::App;

my $app = ManulC::App->new;
ok( defined $app, "application object created" );

#say STDERR $app->pluginMgr->namePrefix;
is( $app->pluginMgr->namePrefix, 'ManulC::Plugin', "expected plugin name prefix" );

$app->pluginMgr->_set_namePrefix( 'ManulC::Plugs::' );

like( $app->pluginMgr->namePrefix, 'ManulC::Plugs', "plugin name prefix coercion" );

my @testDirs = qw<./t/data/pluginMgr/lib ./t/data/pluginMgr/lib2>;
$ENV{MANULC_PLUGDIRS} = join( ':', @testDirs );
$app = ManulC::App->new;
is( $app->pluginMgr->pluginDirs, \@testDirs, "MANULC_PLUGDIRS works" );
delete $ENV{MANULC_PLUGDIRS};

$app = ManulC::App->new;
$app->pluginMgr->loadPlugins;

done_testing;
