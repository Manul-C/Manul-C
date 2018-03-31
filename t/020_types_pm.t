#

use ManulCTest;
use ManulC::Object;

package __MCT::TypeTest {
    use ManulC::Class;
    extends qw<ManulC::Object>;
    use ManulC::Types -all;

    has attr => (
        is => 'rw',
        isa => AllOf [ InstanceOf ['ManulC::Object'], ConsumerOf ['__MCT::ARole'], HasMethods [qw<m1 m2>] ],
    );
}

package __MCT::ARole {
    use ManulC::Role;
    roleInit;

    sub m1 { }
}

# --- Use a conforming class
package __MCT::Conforming {
    use ManulC::Class;
    extends qw<ManulC::Object>;
    with qw<__MCT::ARole>;

    sub m2 { }
}

my $obj = __MCT::TypeTest->new();
try {
    $obj->attr( __MCT::Conforming->new );
    ok( 1, "Accepted object of conforming class" );
}
catch {
    fail( "Attribute validation unexpectedly failed: " . $@ );
}

# --- Test against a missing method class
package __MCT::NoMethod {
    use ManulC::Class;
    extends qw<ManulC::Object>;
    with qw<__MCT::ARole>;
}

try {
    $obj->attr( __MCT::NoMethod->new );
    fail( "Non-conforming object with a missing method has been accepted" );
}
catch {
    like(
        $@,
        qr/Reference .* did not pass type constraint .* The reference cannot "m2"/s,
        "exception thrown with proper error message about missing method"
    );
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
    fail( "Non-conforming object without required role consumed has been accepted" );
}
catch {
    like(
        $@,
        qr/Reference .* did not pass type constraint .* The reference .* doesn't __MCT::ARole/s,
        "exception thrown with proper error message about missing role"
    );
}

# --- Test against wrong base class
package __MCT::BaseClass {
    use Moo;
}

package __MCT::BadBase {
    use ManulC::Class;
    extends qw<__MCT::BaseClass>;
    with qw<__MCT::ARole>;

    sub m2 { }
}

try {
    $obj->attr( __MCT::BadBase->new );
    fail( "Non-conforming object with bad base class has been accepted" );
}
catch {
    like(
        $@,
        qr/Reference .* did not pass type constraint .* The reference .* isa .* and __MCT::BaseClass/s,
        "exception thrown with proper error message about base classes"
    );
}

# --- Test for bad parameters
try {
    package __MCT::ToFewParam {
        use ManulC::Class;
        extends qw<ManulC::Object>;
        use ManulC::Types -all;

        has attr => (
            is => 'rw',
            isa => AllOf [],
        );
    };
    
    fail("AllOf[`a] with 0 paramters erroneously passed");
}
catch {
    like(
        $@,
        qr/AllOf\[`a\] requires at least one parameter/,
        "exception thrown with proper error message about not enough parmeters"
    );
}

try {
    package __MCT::BadParam {
        use ManulC::Class;
        extends qw<ManulC::Object>;
        use ManulC::Types -all;

        has attr => (
            is => 'rw',
            isa => AllOf [InstanceOf['Moo::Object'], Int],
        );
    };
    
    fail("AllOf[`a] with Int paramter erroneously passed");
}
catch {
    like(
        $@,
        qr/Parameter to AllOf\[`a\] expected to be InstanceOf\[`a\], ConsumerOf\[`a\], and HasMethods\[`a\]/,
        "exception thrown with proper error message about wrong parameter type"
    );
}

done_testing;
