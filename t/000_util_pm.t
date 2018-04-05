#

use ManulCTest;
use ManulC::Util qw<:all>;

ok( 1, "OK" );

# --- Test for low-lever failure messaging.
my $failMsg = "test failure";
try {
    FAIL( $failMsg );
}
catch {
    like( $@, qr/^$failMsg/, "Incorrect failure message" );
}

# --- See if messaging works with a custom handler.
setFailSub(
    sub {
        die "FAIL:" . join( '', @_ );
    }
);

try {
    FAIL( $failMsg );
}
catch {
    like( $@, qr/^FAIL:$failMsg/, "Failure message not processed by fail sub" );
}

# --- Return back to the default handler
setFailSub( undef );
try {
    FAIL( $failMsg );
}
catch {
    unlike( $@, qr/^FAIL:$failMsg/, "Failure message not processed by fail sub" );
    like( $@, qr/^$failMsg/, "incorrect failure message after restoring default handler" );
}

# --- Namespace manipulations
package __MCT::NSManip {
    our $v1 = 3.1415926;
    my $v2 = "no access";

    sub preExists {
        return $v1 / 2;
    }
}

ok( !getNS( "__MCT::___NOT_HERE__" ), "true returned for non-existing namespace" );
ok( getNS( "__MCT::NSManip" ),        "existing namespace not found" );

is( fetchGlobal( '$__MCT::NSManip::v1' ), 3.1415926, "fetch scalar from namespace" );

try {
    fetchGlobal( '$__MCT::NSManip::v2' );
    fail( "fetching a private scalar must raise an exception" );
}
catch {
    like( $@, qr/^\$v2 not declared in /, "unexpected error message" );
}

is( getNS( "__MCT::NSManip" )->get_symbol( "&__injected" ), undef, "injected sub name is not in the target namespace" );
injectCode( "__MCT::NSManip", "__injected", sub { return $__MCT::NSManip::v1 * 2 } );
is( __MCT::NSManip->__injected, $__MCT::NSManip::v1 * 2, "injected sub" );

my $__inj = fetchGlobal( '&__MCT::NSManip::__injected' );
is( ref( $__inj ), 'CODE', 'fetchglobal() returns code ref for & sigil' );
is( $__inj->(), $__MCT::NSManip::v1 * 2, "fetchGlobal() returns correct code ref for injected sub" );

my $code = fetchGlobal( "&__MCT::NSManip::preExists" );
is( $code->(), $__MCT::NSManip::v1 / 2, "fetchGloval() returns correct code ref for static sub" );

done_testing;
