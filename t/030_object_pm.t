#

use ManulCTest;
use ManulC::Object;
use ManulC::Util qw<:data>;
use Data::Dumper;

# --- Object ID
my $obj = ManulC::Object->new;

like( $obj->__id, qr/^ManulC__Object_\d+$/, "valid object id" );

# --- Basic object structure with debug but no stack trace.
my $line;
$obj = ManulC::Object->new( DEBUG => is_true( $line = __LINE__ ), STACKTRACE => 0 );

is(
    $obj,
    {
        STACKTRACE  => 0,
        DEBUG       => 1,
        __orig_file => __FILE__,
        __orig_line => $line,
        __orig_sub  => 'ManulC::Object::new',
        __orig_pkg  => 'main',
    },
    "Valid object structure"
);

# --- Test for correct origination stack trace
sub createObj {
    return ManulC::Object->new( DEBUG => 1, STACKTRACE => 1, );
}

sub wrapCreate {
    return createObj;
}
is( wrapCreate->__orig_stack->frame_count, 3, "number of origination stack frames" );

done_testing;
