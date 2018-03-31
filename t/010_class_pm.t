#

use ManulCTest;

# --- Test for namespace::clean applied.

package __MCT::WITH_MOO {
    use ManulC::Util qw<:errors>;
    use Moo;
    # No namespace::clean applied
}

package __MCT::WITH_MCCLASS {
    use ManulC::Util qw<:errors>;
    use ManulC::Class;
    # namespace::clean must be applied.
}

ok( __MCT::WITH_MOO->can( "FAIL" ),      "FAIL() is expected to be visible without ManulC::Class" );
ok( !__MCT::WITH_MCCLASS->can( "FAIL" ), "FAIL() must not be visible with ManulC::Class applied" );

done_testing;
