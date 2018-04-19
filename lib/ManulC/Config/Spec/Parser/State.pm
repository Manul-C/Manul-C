#
# ABSTRACT: This class implements spec parser state
package ManulC::Config::Spec::Parser::State;

# NOTE: This class must avoid calling create() method directly but rather rely upon parent->create(). This is due to the
# helper nature of this object which cannot act as a parent.

use ManulC::Class -allTypes, -child;
extends qw<ManulC::Object>;

our $VERSION = 'v0.001.001';

# --- Public attributes

# Spec section object
has section => (
    is      => 'rw',
    isa     => InstanceOf ["ManulC::Config::Spec::Section"],
    lazy    => 1,
    builder => 'initSection',
);

# Raw specs data
has specData => (
    is       => 'rw',
    isa      => ArrayRef,
    required => 1,
);

has iterator => (
    is      => 'rw',
    isa     => InstanceOf ["ManulC::Config::Spec::Iterator"],
    lazy    => 1,
    builder => 'initIterator',
);

# --- Private attributes

# --- Public methods

sub BUILD {
    my $this = shift;

    #say STDERR __PACKAGE__, ": I'm a child class" if $this->does( "ManulC::Role::Child" );
    #say STDERR __PACKAGE__, " has $_(): ", ( $this->can( $_ ) ? "YES" : "NO" ) foreach qw<_child has parent has_parent>;
}

# --- Private methods

# --- Attribute initializers

sub initSection {
    my $this = shift;
    $this->parent->create( "ManulC::Config::Spec::Section" );
}

sub initIterator {
    my $this = shift;

    my $sIterator = $this->parent->create(
        "ManulC::Config::Spec::Iterator",
        specData => $this->specData,
    );
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
