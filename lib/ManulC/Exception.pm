#

package ManulC::Exception;

use Scalar::Util qw<blessed>;
use Module::Find;
use Data::Dumper;

use ManulC::Class -allTypes;
extends qw<ManulC::Object>;
with 'Throwable';
use MooX::Aliases;

our $VERSION = 'v0.001.001';

use overload fallback => 1, q<""> => 'stringify';

# --- Public attributes

# Override ManulC::Object's app attribute to preserve application's object for later analysis if the exception would
# fall out of application's scope accidentally.
has '+app' => (
    weak_ref => 0,
);

# Exception main message.
has message => (
    is      => 'rw',
    lazy    => 1,
    builder => 'initMessage',
    alias   => [q<error>],
);

# file and line define where exception was thrown
has file => (
    is        => 'rwp',
    predicate => 1,
);

has line => (
    is        => 'rwp',
    predicate => 1,
);

# Stacktrace from the point where exception was thrown.
has stacktrace => (
    is        => 'rwp',
    predicate => 1,
);

# Object which raised the exception.
has object => (
    is        => 'ro',
    predicate => 1,
);

# --- Static methods

# makeStackProfile(detectFrame => \&isItTheFrame) => @profile
# Builds up a exception constructor profile consisting of keys stacktrace, file, line.
# detectFrame callback will be called with a single paramter – raw stack frame data, as in frame_filter callback of
# Devel::Stacktrace. It must return TRUE if the frame is the one where exception was actually thrown.
sub makeStackProfile {
    my %params = @_;

    my $itIsTheFrame = $params{detectFrame}
      // sub { my $fr = shift; !Role::Tiny::does_role( $fr->{caller}[0], 'Throwable' ); };
    my $noSkip = 0;

    # Skip all throw() wrapper frames until actual caller is found.
    my $trace = Devel::StackTrace->new(
        message      => '',
        frame_filter => sub {
            return 1 if $noSkip;
            my $fr = shift;

            return 0 if !$itIsTheFrame->( $fr );
            return $noSkip = 1;
        }
    );

    my $frame = $trace->next_frame;
    return (
        file       => $frame->filename,
        line       => $frame->line,
        stacktrace => $trace,
    );
}

# --- Public methods

around BUILDARGS => sub {
    my $orig   = shift;
    my $class  = shift;
    my %params = @_;

    my $noTracing = $params{stacktrace} && $params{file} && $params{line};
    my @profile;

    # Avoid doing extrajob if all required params are already in place.
    unless ( $noTracing ) {
        push @profile, makeStackProfile;
    }

    return $orig->(
        $class,
        @profile,
        @_
    );
};

sub BUILD {
    my $this = shift;

    warn __PACKAGE__ . " must not be used directly to create exceptions."
      if ref( $this ) eq __PACKAGE__;

    my $mortal   = "ManulC::Role::Exception::Mortal";
    my $harmless = "ManulC::Role::Exception::Harmless";

    warn ref( $this ) . " must consume either $mortal or $harmless roles"
      unless $this->does( $mortal ) || $this->does( $harmless );
}

# $exception->transmute( $srcExcpt [, $enforce [, @profile ] ] ) – converts $srcExcpt into $exception class. If $enforce
# is false then convertion is not done if $srcExcpt is a instance of ManulC::Exception. @profile is passed to the newly
# created exception object constructor.
# Exceptions derived from Error class are directly supported too.
# For exceptions of other types the methods does the best to preserve the information stored in them.
sub transmute {
    my $this    = shift;
    my $e       = shift;
    my $enforce = shift // 0;

    my $class = ref( $this ) || $this;

    unless ( UNIVERSAL::isa( $this, __PACKAGE__ ) ) {
        ManulC::Fatal->throw( message => "Cannot transmute into a non-" . __PACKAGE__ . " class " . $class );
    }

    if ( ref( $e ) ) {
        if ( $e->isa( __PACKAGE__ ) ) {
            if ( !$enforce || $e->isa( $class ) ) {
                return $e;
            }
            return $e->create( $class, %$e, @_ );
        }
        elsif ( $e->isa( 'Error' ) ) {
            return $class->new(
                message    => $e->text,
                line       => $e->line,
                file       => $e->file,
                stacktrace => $e->stacktrace,
                object     => $e->object,
                @_,
            );
        }
        # Wild cases of non-exception objects. Generally it's a serious bug but
        # we better try to provide as much information on what's happened as
        # possible.
        elsif ( $e->can( 'stringify' ) ) {
            return $class->new(
                message => "(Exception from stringify() method of " . ref( $e ) . ") " . $e->stringify,
                @_
            );
        }
        elsif ( $e->can( 'as_text' ) ) {
            return $class->new(
                message => "(Exception from as_text() method of "
                  . ref( $e ) . ") "
                  . $e->as_text,
                @_
            );
        }
        else {
            # Finally we're no idea what kind of a object has been thrown to us.
            return $class->new(
                message => "Unknown class of exception received: "
                  . ref( $e ) . "\n"
                  . Dumper( $e ),
                @_
            );
        }
    }
    return $class->new( message => $e, @_ );
}

# $exception->rethrow( $srcExcpt, @profile )
# If $exception
sub rethrow {
    my $exception = shift;

    if ( blessed( $exception ) && $exception->isa( __PACKAGE__ ) ) {

        # Never call transmute on a Optrade::Exception descendant because this
        # is not what is expected from rethrow.
        $exception->throw;
    }

    my $class = ref( $exception ) || $exception;
    my $srcExcpt = shift;

    my $newExcpt = $class->transmute( $srcExcpt, 0, @_ );
    $newExcpt->throw;
}

# stringify() converts exception into a descriptive line(s) of text.
sub stringify {
    my $this = shift;

    return $this->stringifyPrefix . $this->message . $this->stringifyPostfix;
}

sub stringifyPrefix {
    my $this = shift;

    return "Exception " . ref( $this ) . ': ';
}

sub stringifyPostfix {
    my $this = shift;

    return ( $this->DEBUG ? "\n" . $this->stacktrace : ' at ' . $this->file . ', line ' . $this->line );
}

sub initMessage {
    my $this = shift;
    return 'INTERNAL ERROR: No exception message was provided';
}

# --- Utility code

# Load all Module::Exception::Modules.
useall __PACKAGE__;

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
