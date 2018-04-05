#

use ManulCTest;

use ManulC::App;

my $app = ManulC::App->new;

ok( defined $app,  "application object created ok" );
ok( $app->has_app, "\$app->app attribute was set" );
is( $app->app, undef, "\$app->app attribute is undefined" );

done_testing;
