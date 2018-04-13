#

use v5.24;
use ManulCTest;
use Test2::Tools::Tiny;
use Data::Dumper;

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

package __MCT::Ext::Test {
    use ManulC::Class -extension;
    extends qw<ManulC::Object>;
}

$o = __MCT::Ext::Test->new;
ok( $o->does( "ManulC::Role::Extension" ), "valid extension object is created" );

package __MCT::TypedAttr {
    use ManulC::Class -allTypes;

    has typedAttr => (
        is => 'rw',
        isa => Maybe [Str],
    );
}

# --- Test syntax sugar registering.

my $rc;

{
    # Eval is producing warnings output we don't want to see.
    local $SIG{__WARN__} = sub {};
    $rc = eval <<MCT_SUGAR;
package __MCT::SugarWillFail;
use ManulC::Class -testSugar;
tstSugar 'method1';
1;
MCT_SUGAR
}

is( $rc, undef, "use of unregistered sugar: expected fail" );

package __MCT::SugarSupport {
    use ManulC::Util qw<:namespace>;
    use ManulC::Class -sugar;
    newSugar -testSugar => {
        tstSugar => \&_handle_tstSugar,
    };

    sub _handle_tstSugar ($) {
        my ( $methodName ) = @_;
        my $target = caller;
        injectCode( $target, $methodName, sub { "via sugar" } );
    }
}

{
    $rc = eval <<MCT_SUGAR;
package __MCT::SugarWillWork;
use ManulC::Class -testSugar;
tstSugar 'method2';
1;
MCT_SUGAR
}

is($rc,1,"package with sugar compiled");
is(__MCT::SugarWillWork::method2(), "via sugar", "sugar-registered method works");

done_testing;
