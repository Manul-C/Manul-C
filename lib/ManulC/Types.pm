#

package ManulC::Types;

use ManulC::Util qw<:errors>;

use Type::Library -base, -declare => qw<AllOf>;
use Type::Utils -all;
require Error::TypeTiny;
require Type::Tiny::Intersection;
BEGIN { extends "Types::Standard"; }

our $VERSION = 'v0.001.001';

declare AllOf, 
  where { 1 },
  constraint_generator => sub {
    my @cParams = @_;
    Error::TypeTiny->throw( message => "AllOf[`a] requires at least one parameter" ) unless @cParams > 1;
    foreach my $validator ( @cParams ) {
        $validator->isa( "Type::Tiny::Class" )
          || $validator->isa( "Type::Tiny::Role" )
          || $validator->isa( "Type::Tiny::Duck" )
          || Error::TypeTiny->throw(
            message => "Parameter to AllOf[`a] expected to be InstanceOf[`a], ConsumerOf[`a], and HasMethods[`a]"
          );
    }

    return Type::Tiny::Intersection->new(
        type_constraints => \@cParams,
        display_name => sprintf( 'AllOf[%s]', join( ",", @cParams ) ),
    );
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
