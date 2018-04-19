#
# ABSTRACT: This class implements parsing of specs data array
# The purpose is to get specs array as input and return DataHash-tied hash.
package ManulC::Config::Spec::Parser;

# Workaround a bug in MooX::ClassAttribute; preloading the role fixes 'method not found' error for a static attribute.
require ManulC::Role::Config::opt; 

use ManulC;
use ManulC::Util qw<:namespace>;
require Role::Tiny;

use ManulC::Class -allTypes, -parent, -child;
extends qw<ManulC::Object>;

our $VERSION = 'v0.001.001';

# Limit our parents to configuration object only.
#has '+parent' => (
#    isa => InstanceOf ["ManulC::Config"],
#);

# --- Public methods

sub BUILD {
    my $this = shift;
    #say STDERR __PACKAGE__, " has $_(): ", ( $this->can( $_ ) ? "YES" : "NO" ) foreach qw<_child h    #say STDERR __PACKAGE__, ": I'm a child class" if $this->does( "ManulC::Role::Child" );as parent has_parent _abc123>;
}

# Initiate parsing.
sub parse {
    my $this   = shift;
    my %params = @_;

    $this->_parseSpecBody( @_ );
}

# --- Private methods

sub _opt2mod {
    my $this = shift;
    my ($context, $opt ) = @_;

    my $modName;
    if ( $opt =~ $ManulC::specOptRx ) {
        my $optName = $+{optName};
        $modName = "ManulC::Config::Spec::Opt::${context}::_$optName";
        try {
            loadClass( $modName );
        }
        catch {
            $this->Rethrow( "Config::BadSpecData", $@ );
        }
        unless ( Role::Tiny::does_role( $modName, "ManulC::Role::Config::opt" ) ) {
            $this->Throw(
                "Config::BadSpecData",
                "Option '$opt' module doesn't consume ManulC::Role::Config::opt"
            );
        }
    }
    else {
        $this->Throw( "Config::BadSpecData", "Bad option name: $opt" );
    }

    return $modName;
}

sub _parseSpecBody {
    my $this   = shift;
    my %params = @_;

    my $state = $this->create( "ManulC::Config::Spec::Parser::State", @_ );

    my $iter = $state->iterator;

    while ( $iter->hasNext ) {
        my ( $option ) = ( $iter->getNext );
        my $optMod = $this->_opt2mod( "section", $option );
        say STDERR "Got option module: ", $optMod;
        say STDERR "Option arity: ",      $optMod->arity;
    }
}

# --- Attribute initializers

sub initCursor {
    return 0;
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
