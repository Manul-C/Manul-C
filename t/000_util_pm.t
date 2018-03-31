#

use ManulCTest;
use ManulC::Util qw<:all>;

ok(1, "OK");

# --- Test for low-lever failure messaging.
my $failMsg = "test failure";
try {
    FAIL($failMsg);
}
catch {
    like($@, qr/^$failMsg/, "Incorrect failure message");
}

# --- See if messaging works with a custom handler.
setFailSub(
    sub {
        die "FAIL:" . join('', @_);
    }
);

try {
    FAIL($failMsg);
}
catch {
    like($@, qr/^FAIL:$failMsg/, "Failure message not processed by fail sub");
}

# --- Return back to the default handler
setFailSub(undef);
try {
    FAIL($failMsg);
}
catch {
    unlike($@, qr/^FAIL:$failMsg/, "Failure message not processed by fail sub");
    like($@, qr/^$failMsg/, "incorrect failure message after restoring default handler");
}

# --- Namespace manipulations
package __MCT::NSManip {
    our $v1 = 3.1415926;
    my $v2 = "no access";
}

ok(!getNS("__MCT::___NOT_HERE__"), "true returned for non-existing namespace");
ok(getNS("__MCT::NSManip"), "existing namespace not found");

is(fetchGlobal('$__MCT::NSManip::v1'), 3.1415926, "wrong scalar fetched from namespace");

try {
    fetchGlobal('$__MCT::NSManip::v2');
    fail("fetching a private scalar must raise an exception");
}
catch {
    like($@, qr/^\$v2 not declared in /, "unexpected error message");
}

done_testing;