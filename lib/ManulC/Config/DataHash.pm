#
# ABSTRACT: This class implements tieing for class data
package ManulC::Config::DataHash;

use ManulC::Class -allTypes, -parent, -child;
extends qw<ManulC::Object>;

our $VERSION = 'v0.001.001';

# The default class of data node.
has nodeClass => (
    is      => 'rw',
    isa     => ClassName,
    lazy    => 1,
    builder => 'initNodeClass',
);

# Collection of data nodes of this hash key.
has nodes => (
    is      => 'rwp',
    isa     => HashRef [ InstanceOf ['ManulC::Config::Node'] ],
    lazy    => 1,
    clearer => 1,
    builder => 'initNodes',
);

# --- Public methods

sub TIEHASH {
    my $class  = shift;
    my %params = @_;

    $class = ref( $class ) || $class;

    # Don't use create() because we're being created with it.
    my $this = $class->new( @_ );

    return $this;
}

sub EXISTS {
    my $this = shift;
    my ( $key ) = @_;

    $this->_readValidateNode( $key );

    return defined $this->nodes->{$key};
}

sub FETCH {
    my $this = shift;
    my ( $key ) = @_;

    $this->_readValidateNode( $key );

    my $nodes = $this->nodes;

    return ( exists $nodes->{$key} ? $nodes->{$key} : undef );
}

# --- Private methods

sub _readValidateNode {
    my $this    = shift;
    my ( $key ) = @_;
    my $nodes   = $this->nodes;
    $this->warn( "Undefined node for key '", $key, "' -- broken structure detected!" )
      if exists $nodes->{$key} && !defined $nodes->{$key};
}

# --- Attribute initializers

sub initNodeClass {
    return 'ManulC::Config::Node';
}

sub initNodes {
    return {};
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
