#

use ManulCTest;

require ManulC::Exception;

package __MCT::WarnException {
    use ManulC::Class;
    extends qw<ManulC::Exception>;
    with qw<ManulC::Exception::Mortal>;
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

done_testing;
