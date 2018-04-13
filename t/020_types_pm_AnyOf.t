#

use ManulCTest;
use ManulC::Object;

package __MCT::AnyOfTest {
    use ManulC::Class;
    extends qw<ManulC::Object>;
    use ManulC::Types -all;

    has attr => (
        is => 'rw',
        isa => AnyOf [ InstanceOf ['ManulC::Object'], ConsumerOf ['__MCT::ARole'], HasMethods [qw<m1 m2>], Ref ["HASH"],
            Int ],
    );
}

package __MCT::ARole {
    use ManulC::Role;

    sub m1 { }
}

# --- Use a conforming class
package __MCT::Conforming {
    use ManulC::Class;
    extends qw<ManulC::Object>;
    with qw<__MCT::ARole>;

    sub m2 { }
}

my $obj = __MCT::AnyOfTest->new();
try {
    $obj->attr( __MCT::Conforming->new );
    ok( 1, "Accepted object of conforming class" );
    $obj->attr( { a => 1, b => 2 } );
    ok( 1, "accepted hashref" );
    $obj->attr( 123 );
    ok( 1, "accepted int" );
}
catch {
    fail( "Attribute validation unexpectedly failed: " . $@ );
}

# --- Test for invalid data type
try {
    $obj->attr( "You shall not pass!" );
    fail( "string erroneously accepted as attribute value" );
}
catch {
    like(
        $@,
        qr/Value "You shall not pass!" did not pass type constraint "AnyOf/,
        "string value has been correctly rejected"
    );
}

# --- Test against a missing method class
package __MCT::NoMethod {
    use ManulC::Class;
    extends qw<ManulC::Object>;
    with qw<__MCT::ARole>;
}

try {
    $obj->attr( __MCT::NoMethod->new );
    ok( 1, "missing methods are ok" )
}
catch {
    fail( "missing methods must not be a problem" );
}

# --- Test against missing role
package __MCT::NoRole {
    use ManulC::Class;
    extends qw<ManulC::Object>;

    sub m1 { }
    sub m2 { }
}

try {
    $obj->attr( __MCT::NoRole->new );
    ok( 1, "no role but correct base class" );
}
catch {
    fail( "missing role must not be a problem" );
}

# --- Test against wrong base class
package __MCT::BaseClass {
    use Moo;
}

package __MCT::BadBase {
    use ManulC::Class;
    extends qw<__MCT::BaseClass>;
    with qw<__MCT::ARole>;
}

try {
    $obj->attr( __MCT::BadBase->new );
    ok( 1, "any base class accepted as long as role is in place" );
}
catch {
    fail( "different base class must not be a problem" );
}

# --- Test for bad parameters
try {

    package __MCT::ToFewParam {
        use ManulC::Class;
        extends qw<ManulC::Object>;
        use ManulC::Types -all;

        has attr => (
            is => 'rw',
            isa => AnyOf [],
        );
    };

    fail( "AnyOf[`a] with 0 paramters erroneously passed" );
}
catch {
    like(
        $@,
        qr/AnyOf\[`a\] requires at least one parameter/,
        "exception thrown with proper error message about not enough parmeters"
    );
}

done_testing;
