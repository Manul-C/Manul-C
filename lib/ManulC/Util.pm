#

package ManulC::Util;
use v5.24;

our $VERSION = 'v0.001.001';

use Carp;
use Module::Load qw<load>;
use Module::Loaded qw<is_loaded>;

use Exporter;

our @ISA = qw<Exporter>;

our @EXPORT_OK;

our %EXPORT_TAGS = (
    all         => \@EXPORT_OK,
    namespace   => [qw<injectCode getNS fetchGlobal loadModule loadClass>],
    execControl => [qw<$DEBUG>],
    errors      => [qw<FAIL setFailSub>],
);

# Fill the @EXPORT_OK array from EXPORT_TAGS
push @EXPORT_OK, @{ $EXPORT_TAGS{$_} } foreach keys %EXPORT_TAGS;

# Debug mode.
our $DEBUG = !!( $ENV{MANULC_DEBUG} // 0 );

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

    my @keys = split /::/, $module;

    my $ref = \%::;
    while ( @keys ) {
        my $key = shift @keys;
        my $sym = "$key\:\:";
        return undef unless defined $ref->{$sym};
        $ref = $ref->{$sym};
    }
    return $ref;
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
    my $symbol = pop @keys;
    my $module = join( '::', @keys );

    my $ns = getNS( $module );

    FAIL( "Module $module not found" ) unless defined $ns;

    state $sigilSub = {
        '$' => sub { return ${ $_[0] } },
        '%' => sub { return %{ $_[0] } },
        '@' => sub { return @{ $_[0] } },
        '&' => sub { return *{ $_[0] }{CODE} },
    };
    state $sigilKey = {
        '$' => 'SCALAR',
        '%' => 'HASH',
        '@' => 'ARRAY',
        '&' => 'CODE',
    };

    FAIL( "$sigil$symbol not declared in " . $ns )
      unless defined $ns->{$symbol}
      && *{ $ns->{$symbol} }{ $sigilKey->{$sigil} };

    return $sigilSub->{$sigil}->( $ns->{$symbol} );
}

# Installs a $code reference into a module $target under the $name.
# Any existing entry will be overridden.
sub injectCode {
    my ( $target, $name, $code ) = @_;

    no warnings qw(redefine);
    getNS( $target )->{$name} = $code;
    use warnings qw(redefine);
}

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
