#

use ManulCTest;
use Data::Dumper;
use Carp;

require ManulC::Exception;

package __MCT::WarnException {
    use ManulC::Class;
    extends qw<ManulC::Exception>;
    with qw<ManulC::Role::Exception::Mortal>;
}

{
    local $SIG{__WARN__} = sub { __MCT::WarnException->throw( message => $_[0] ) };

    try {
        ManulC::Exception->throw( message => "anything" );
    }
    catch {
        isa_ok( $@, 'ManulC::Exception' );
        isa_ok( $@, '__MCT::WarnException' );
        like( $@->message, qr/^ManulC::Exception must not be used directly/, "warning message is correct" );
    }
}

package __MCT::SimpleObj {
    use ManulC::Class;
    extends qw<ManulC::Object>;

}

my $obj = ManulC::Object->new;

# Throw/Transmute/Rethrow on object

sub _check_excpt {
    my ( $obj, $e, $file, $line ) = @_;
    isa_ok( $e, ["ManulC::Exception::Fatal"], "correct exception class from short name." );
    DOES_ok( $e, ["ManulC::Role::Exception::Mortal"], "consumes Mortal role" );
    is( $e->object, $obj,  "initiating object is preserved" );
    is( $e->file,   $file, "source file" );
    is( $e->line,   $line, "source line" );
}

subtest "Throw on object" => sub {
    plan 5;

    # Avoid possible interference from thrid-party handlers.
    local $SIG{__DIE__};
    local $SIG{__WARN__};

    my $line;
    try {
        ( $line = __LINE__ ), $obj->Throw( "Fatal", "test exception" );
    }
    catch {
        _check_excpt( $obj, $@, __FILE__, $line );
    }
};

subtest "Transmute on obejct" => sub {
    plan 5;
    my $line;
    try {
        die "test die";
    }
    catch {
        _check_excpt( $obj, $obj->Transmute( "Fatal", $@, 0 ), __FILE__, __LINE__ );
    }
};

subtest "Rethrow on obejct" => sub {
    plan 5;

    # Avoid possible interference from thrid-party handlers.
    local $SIG{__DIE__};
    local $SIG{__WARN__};

    my $line;
    try {
        try {
            die "test die";
        }
        catch {
            ( $line = __LINE__ ), $obj->Rethrow( "Fatal", $@ );
        }
    }
    catch {
        _check_excpt( $obj, $@, __FILE__, $line );
    }
};

done_testing;
