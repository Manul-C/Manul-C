#
# ABSTRACT: This role implements parent object functionality.
package ManulC::Role::Parent;

use ManulC::Role;

our $VERSION = 'v0.001.001';

around create => sub {
    my $orig      = shift;
    my $this      = shift;
    my $baseClass = shift;

    my $child = $orig->( $this, $baseClass, @_ );

    if ( $child->DOES( "ManulC::Role::Child" ) ) {
        $child->parent( $this );

        # For an object which would like to keep track of its childs or process new child in any other way.
        if ( $this->can( "registerChildObject" ) ) {
            $this->registerChildObject( $child );
        }
    }

    return $child;
};

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
