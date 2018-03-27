#


package ManulC::Class;

use v5.24;
use utf8;
use strict;
use warnings;

use Module::Load qw<load load_remote>;
use ManulC::Util qw<:namespace>;

use constant DEFAULT_BASEVERSION => '5.24';

# Data about each class declared with this module.
our %_classInfo;

# Module parameters and their properties
my %paramSet = (
    '.ROLE'        => {},
    #application    => { roles => [qw<Optrade::Role::App>], },
    #dbiTransparent => { roles => [qw<Optrade::Role::DBI::Transparent>], },
    #dbiBase        => { roles => [qw<Optrade::Role::DBI::Base>], },
    #dbiRWMode      => { roles => [qw<Optrade::Role::DBI::RWMode>], },
    #dbiConfig      => { roles => [qw<Optrade::Role::DBI::Config>], },
    #logging        => { roles => [qw<Optrade::Role::Logging>], },
    #tuner          => { roles => [qw<Optrade::Role::Tuner>], },
);

sub import {
    my $class = shift;
    my $target = caller;

    # .ROLE param can only be the first in the list.
    my $isRole = defined $_[0] && $_[0] eq '.ROLE';
    shift if $isRole; # Remove .ROLE from the arguments list.

    $_classInfo{$target}{isRole} = 1;
    
    my $featureSet = ':' + DEFAULT_BASEVERSION;
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