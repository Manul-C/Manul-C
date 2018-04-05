#

use ManulCTest;

require ManulC::Exception;

try {
    ManulC::Exception->throw(message => "anything");
}catch {
    say STDERR $@;
}

done_testing;