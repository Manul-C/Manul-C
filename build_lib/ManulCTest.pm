#

package ManulCTest;

# Test functionality wrapper module

our $VERSION = 'v0.001.001';
our $TESTING = !!1;

use Module::Load qw<load_remote>;
use Carp;
require Test2::V0;
require Syntax::Keyword::Try;

sub import {
    my $class  = shift;
    my $target = caller;

    $SIG{__DIE__} = sub { confess @_ };

    require feature;
    feature->import( ':5.24' );

    Syntax::Keyword::Try->import_into( $target );

    $ENV{MANULC_TESTING} //= $TESTING;

    unshift @_, 'Test2::V0';
    goto &Test2::V0::import;
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
