#

package ManulC::Util;
use v5.24;

our $VERSION = 'v0.001.001';

use Carp;
use Module::Load qw<load>;
use Module::Loaded qw<is_loaded>;
use Sub::Install qw<install_sub>;
use Scalar::Util qw<looks_like_number>;
use Sub::Quote;
require Package::Stash;

use Exporter;

our @ISA = qw<Exporter>;

our @EXPORT_OK;

our %EXPORT_TAGS = (
    all       => \@EXPORT_OK,
    namespace => [
        qw<
          injectCode getNS fetchGlobal loadModule loadClass
          hasRegisteredClass getClassAttributes hasAttribute
          object2class
          >
    ],
    execControl => [qw<$DEBUG>],
    errors      => [qw<FAIL setFailSub>],
    data        => [qw<is_true>],
);

# Fill the @EXPORT_OK array from EXPORT_TAGS
push @EXPORT_OK, @{ $EXPORT_TAGS{$_} } foreach keys %EXPORT_TAGS;

# Debug mode.
our $DEBUG = !!( $ENV{MANULC_DEBUG} // 0 );

# --- Install aliased functions

install_sub(
    {
        code => \&ManulC::Class::registeredClass,
        as   => 'hasRegisteredClass',
    }
);

# --- ERROR Handling functions
my $failSub = undef;

# Low-level fatal reporting routine. Must only be used where no higher-level reporting is possible.
sub FAIL {
    if ( $failSub ) {
        $failSub->( @_ );
    }
    else {
        # Support objects throwig in themselves as the first argument.
        my $msg = join( "", @_ );
        if ( $DEBUG ) {
            Carp::confess( $msg );
        }
        die $msg;
    }
}

# Sets user-defined fail handling subroutine.
sub setFailSub {
    my $sub = shift;

    if ( defined $sub ) {
        if ( ref( $sub ) eq 'CODE' ) {
            $failSub = $sub;
        }
        else {
            die "setFailSub() parameter must be a code ref";
        }
    }
    else {
        undef $failSub;
    }
}

# --- NAMESPACE manipulation routines

# Returns reference to $module's namespace (stash)
sub getNS($) {
    my ( $module ) = @_;

    state %stashObjects;
    return $stashObjects{$module} if defined $stashObjects{$module};

    # Package::Stash auto-vivifys a namespace if it doesn't existist. So, we check this manually.
    # Unfortunately, the result of the check cannot be cached as the namespace could be create any time.
    my @keys = split /::/, $module;

    my $ref = \%::;
    while ( @keys && defined $ref ) {
        my $key = shift @keys;
        my $sym = "$key\:\:";
        #return undef unless defined $ref->{$sym};
        $ref = $ref->{$sym};
    }
    return undef unless defined $ref;
    return $stashObjects{$module} = Package::Stash->new( $module );
}

# Fetches a global symbol value by its full name; 'full' stand for sigil+namespace+name.
# For example:
# &ManulC::Util::fetchGlobal returns CODEREF
# $ManulC::Util::DEBUG returns content of $DEBUG variable.
sub fetchGlobal {
    my ( $fullName ) = @_;

    $fullName =~ s/^([\$%@&])//
      or FAIL( __PACKAGE__, "::fetchGlobal(): Invalid sigil in `$fullName'" );
    my $sigil = $1;

    my @keys   = split /::/, $fullName;
    my $symbol = $sigil . pop @keys;
    my $module = join( '::', @keys );

    my $ns = getNS( $module );

    FAIL( "Module $module not found" ) unless defined $ns;

    FAIL( "$symbol not declared in " . $ns )
      unless $ns->has_symbol( $symbol );

    my $symVal = $ns->get_symbol( $symbol );
    return ($sigil eq '&' ? $symVal : eval "$sigil\{ \$symVal }");
}

# Installs a $code reference into a module $target under the $name.
# Any existing entry will be overridden.
sub injectCode {
    my ( $target, $name, $code ) = @_;

    FAIL( "Cannot inject ", ref( $code ), " as a sub into $target" ) unless ref( $code ) eq 'CODE';
    getNS( $target )->add_symbol( "&$name", $code );
}

# Makes flat-string class name from its parameter
quote_sub 'ManulC::Util::object2class', q{ return ref($_[0]) || $_[0]; };

# Loads a module by its name. Checks if $params{method} is provided by the module.
sub loadModule {
    my $module = shift;
    my %params = @_;

    my $loaded = is_loaded( $module );
    if ( !$loaded ) {
        # Don't use try here – avoid 3rd party dependencies
        eval {
            load( $module );
        };
        FAIL( $@ ) if $@;
    }

    $loaded = is_loaded( $module );

    if ( $loaded && defined $params{method} ) {
        if ( !$module->can( $params{method} ) ) {
            $loaded = 0;
            mark_as_unloaded( $module );
        }
    }

    return $loaded;
}

# Same as loadModule() but implicitly adds check for method 'new'.
sub loadClass {
    return loadModule( @_, method => 'new' );
}

# Converts its parameter into a boolean value. Perl-false values (except undef) are used as-is. Others either checked
# for being a number; or a string representing basic boolean words yes|on|true or no|off|false.
# For any other value 'undef' is returned.
sub is_true {
    my $val = shift;

    return undef unless defined $val;
    return !!0 if !$val;

    if ( looks_like_number( $val ) ) {
        return !!$val;
    }

    return !!1 if $val =~ /^(yes|on|true)$/ni;
    return !!0 if $val =~ /^(no|off|false)$/ni;

    return undef;
}

# NOTE: getClassAttributes and hasAttribute work only for classes declared with ManulC::Class!

# Returns list of all attributes of $class
sub getClassAttributes {
    my $class = shift;
    $class = ref( $class ) // $class;
    return ManulC::Class::getAllAttrs( $class );
}

# Returns true if $attr is defined in $class
sub hasAttribute {
    my ( $class, $attr ) = @_;
    FAIL( "No class name defined" )     unless defined $class;
    FAIL( "No attribute name defined" ) unless defined $attr;

    $class = ref( $class ) if ref( $class );

    return defined ManulC::Class::getClassAttrs( $class )->{$attr};
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
