#
# ABSTRACT: This class iterates through spec array.
package ManulC::Config::Spec::Iterator;

use ManulC::Class -allTypes, -parent, -child;
extends qw<ManulC::Object>;

our $VERSION = 'v0.001.001';

# --- Public attributes

# Limit our valid parents
has '+parent' => (
    isa => InstanceOf [ "ManulC::Config::Spec::Parser", __PACKAGE__ ],
);

# Specification array.
has specData => (
    is       => 'rw',
    isa      => ArrayRef,
    required => 1,
);

# Current position in the array - points at element to be fetched next
has cursor => (
    is      => 'rw',
    isa     => Int,
    lazy    => 1,
    clearer => 1,
    builder => 'initCursor',
);

# --- Public methods

# getNext( [ $count ] )
# Return next element(s).
sub getNext {
    my $this = shift;
    my $count = @_ ? shift : 1;

    return () unless $count > 0;

    $this->Throw( "ManulC::Exception::Config::NoSpecsLeft", error => "Can't get next element(s): the list is exhausted" )
      unless $count <= $this->remainder;

    my $cursor = $this->cursor;
    my @elems = @{ $this->specData }[ $cursor .. ( $cursor + $count - 1 ) ];
    $this->cursor( $cursor + $count );
    return @elems;
}

# How many elements left unfetched
sub remainder {
    my $this = shift;
    return ( scalar( @{ $this->specData } ) - $this->cursor );
}

# hasNext( [ $count ] )
# Do we have $count elements left? 1 if not defined.
sub hasNext {
    my $this = shift;
    my $count = @_ ? shift : 1;
    return ( $count <= $this->remainder );
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
