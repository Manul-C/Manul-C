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

package __MCT::Role {
    use ManulC::Role;

    has roleAttr => (
        is      => 'rw',
        default => __PACKAGE__,
    );
}

package __MCT::ClassWithRole {
    use ManulC::Class;
    with '__MCT::Role';
}

my $o = __MCT::ClassWithRole->new;
ok( $o->does( '__MCT::Role' ), 'object consumes role' );
is( $o->roleAttr, '__MCT::Role', 'role applied correctly' );

package __MCT::Plugin::Test {
    use ManulC::Class -plugin;
    extends qw<ManulC::Object>;
}

$o = __MCT::Plugin::Test->new;
ok( $o->does( "ManulC::Role::Plugin" ), "valid plugin object is created" );

package __MCT::TypedAttr {
    use ManulC::Class -allTypes;

    has typedAttr => (
        is => 'rw',
        isa => Maybe [Str],
    );
}

done_testing;
