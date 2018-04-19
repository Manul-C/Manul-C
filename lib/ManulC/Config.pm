#
# ABSTRACT: Confugation handling
package ManulC::Config;

use ManulC::Class -allTypes, -parent;
extends qw<ManulC::Object>;

our $VERSION = 'v0.001.001';

# Configuration data
has data => (
    is        => 'rw',
    isa       => AnyOf [ Ref ["HASH"], Tied ["ManulC::Config::DataHash"] ],
    lazy      => 1,
    predicate => 1,
    clearer   => 1,
    builder   => 'initData',
);

# --- Public methods.

# Create a new tied configuration data hash.
sub createSpecData {
    my $this = shift;

    my %newData;
    tie %newData, "ManulC::Config::DataHash", app => $this->app, parent => $this;

    return \%newData;
}

# Create a new spec parser
sub createSpecParser {
    my $this = shift;

    return $this->create( "ManulC::Config::Spec::Parser" );
}

# Switch configuration object into specification support mode. Slow operation, slow mode.
sub specMode {

}

# --- Attribute initializers

sub initData {
    my $this = shift;
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
