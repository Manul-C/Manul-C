#
# ABSTRACT: This class implements spec section
package ManulC::Config::Spec::Section;

use ManulC::Class -allTypes;
extends qw<ManulC::Object>;

our $VERSION = 'v0.001.001';

# --- Public attributes

# Section name.
has name => (
    is      => 'rw',
    isa     => Str,
    lazy    => 1,
    builder => 'initName',
);

# Sub-sections of this section.
has sections => (
    is        => 'rw',
    isa       => HashRef [ InstanceOf [__PACKAGE__] ],
    lazy      => 1,
    predicate => 1,
    builder   => 'initSections',
);

# --- Private attributes

# --- Public methods

# Creates a child section and records it sections attribute
sub createSubSection {
    my $this = shift;

    my $subSec = $this->create( $this, @_ );

    $this->sections->{ $subSec->name } = $subSec;

    return $subSec;
}

# --- Private methods

# --- Attribute initializers

sub initName {
    my $this = shift;

    # If created as a sub-section then name HAS to be defined as a constructor parameter.
    if ( $this->has_parent && $this->parent->isa( __PACKAGE__ ) ) {
        $this->Throw(
            'Config::Fatal',
            error => ref( $this )
              . " constructor is missing 'name' parameter (created as a sub-section of section '"
              . $this->parent->name . "')"
        );
    }

    # By default we create a root section.
    return ".Root";
}

sub initSections {
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
