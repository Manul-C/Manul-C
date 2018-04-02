#

package ManulC::Object;


require Devel::StackTrace;
use Module::Loaded;
use Sub::Install qw<install_sub>;
use Scalar::Util qw(blessed refaddr reftype weaken isweak);

use ManulC::Util qw<:execControl :data :namespace>;
require ManulC::Exception;

use ManulC::Class qw<allTypes>;
classInit;

our $VERSION = 'v0.001.001';

# --- Install aliases to external functions for the purpose of avoiding nested calls for the perfomance purpose.

install_sub(
    {
        code => \&ManulC::Util::hasAttribute,
        as   => 'isAttribute',
    }
);

install_sub(
    {
        code => \&ManulC::Util::getClassAttributes,
        as   => 'allAttributes',
    }
);

# --- Internal attributes

has __id => (
    is      => 'ro',
    lazy    => 1,
    clearer => 1,
    isa     => Str,
    default => sub {
        my $this  = shift;
        my $strID = ref( $this ) . '_' . refaddr( $this );
        $strID =~ s/:/_/g;
        return $strID;
    },
);

has __orig_file  => ( is => 'rw', clearer => 1, );
has __orig_line  => ( is => 'rw', clearer => 1, );
has __orig_pkg   => ( is => 'rw', clearer => 1, );
has __orig_sub   => ( is => 'rw', clearer => 1, );
has __orig_stack => ( is => 'rw', clearer => 1, );

# --- Public attributes
# Main application object.
has app => (
    is        => 'rwp',
    isa       => Maybe [ InstanceOf ["ManulC::App"] ],
    predicate => 1,
    weak_ref  => 1,
);

# Boolean, true if DEBUG mode is on
has DEBUG => (
    is      => 'rw',
    isa     => Bool,
    lazy    => 1,
    clearer => 1,
    coerce  => 1,
    builder => 'initDEBUG',
);

# Boolean, true if working under unit tests
has TEST => (
    is      => 'rw',
    isa     => Bool,
    lazy    => 1,
    clearer => 1,
    coerce  => 1,
    builder => 'initTEST',
);

has STACKTRACE => (
    is      => 'rw',
    isa     => Bool,
    coerce  => 1,
    lazy    => 1,
    clearer => 1,
    builder => 'initSTACKTRACE',
);

# --- Public Methods

sub BUILD {
    my $this = shift;

    if ( $this->DEBUG ) {
        $this->__setup_origination;
    }
}

# Create a new object.
sub create {
    my $this  = shift;
    my $class = shift;

    $class = ref( $class ) // $class;

    loadClass( $class );

    # Note that application itself will always have app attribute set to undef.
    if ( $this->has_app && defined $this->app ) {
        return $this->app->create( $class, @_ );
    }

    return $class->new( @_ );
}

sub initDEBUG {
    return !!$ManulC::Util::DEBUG;
}

sub initTEST {
    return !!( $ENV{MANULC_TEST} // ( is_loaded( "ManulCTest" ) && fetchGlobal( '$ManulCTest::TESTING' ) ) // 0 );
}

sub initSTACKTRACE {
    my $this = shift;
    # Don't do tracing if running under unit tests.
    my $doTrace = !$this->TEST;
    # The following won't change $doTrace if the env variable is not defined.
    $doTrace = is_true( $ENV{MANULC_STACKTRACE} ) // $doTrace;
    return $doTrace;
}

# --- Private Methods
sub __setup_origination {
    my $this = shift;
    my ( $level ) = @_;

    my @frame;
    if ( defined $level ) {

        # Skip our own frame.
        $level++;
    }
    else {
        @frame = caller( 1 );

        # If called from BUILD then skip additional frame.
        $level = $frame[3] =~ /::BUILD$/ ? 2 : 1;
    }

    my ( @foundFrame );
    my $waitForNew = 1;
    while ( @frame = caller( $level ) ) {
        if ( $frame[3] =~ /::(?:create|new)$/ ) {
            $waitForNew = 0;
            @foundFrame = @frame;
        }
        else {
            last unless $waitForNew;
        }
        $level++;
    }

    # Support static method call. Don't try to set object attributes if called as
    # Optrade::Object->__orig or Optrade::Object::__orig.
    if ( @foundFrame && ref( $this ) ) {
        $this->__orig_pkg( $foundFrame[0] // '' );
        $this->__orig_file( $foundFrame[1] );
        $this->__orig_line( $foundFrame[2] );
        $this->__orig_sub( $foundFrame[3] // '' );
    }

    my $frmCount = 0;
    $this->__orig_stack(
        Devel::StackTrace->new(
            frame_filter => sub { $frmCount++ >= $level }
          )
      )
      if ( $this->STACKTRACE );

    return @foundFrame;
}

1;

## Copyright 2018 by Vadim Belman
##
## Licensed under the Apache License, Version 2.0 (the "License");
## you may not use this file except in compliance with the License.
## You may obtain a copy of the License at
##
##  http://www.apache.org/licenses/LICENSE-2.0
##
## Unless required by applicable law or agreed to in writing, software
## distributed under the License is distributed on an "AS IS" BASIS,
## WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
## See the License for the specific language governing permissions and
## limitations under the License.
