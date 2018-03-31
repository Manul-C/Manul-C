#

package ManulC::Class;

use v5.24;
use utf8;
use strict;
use warnings;

our $VERSION = 'v0.001.001';

require Moo;
require Moo::Role;
require namespace::clean;
require Syntax::Keyword::Try;
require MooX::TypeTiny;

use Module::Load qw<load load_remote>;
use ManulC::Util qw<:namespace :errors>;

use constant DEFAULT_BASEVERSION => '5.24';

# Data about each class declared with this module.
our %_classInfo;

# Module parameters and their properties
my %paramSet = (
    '-role'  => {},
    allTypes => {},
    #application    => { roles => [qw<Optrade::Role::App>], },
    #dbiTransparent => { roles => [qw<Optrade::Role::DBI::Transparent>], },
    #dbiBase        => { roles => [qw<Optrade::Role::DBI::Base>], },
    #dbiRWMode      => { roles => [qw<Optrade::Role::DBI::RWMode>], },
    #dbiConfig      => { roles => [qw<Optrade::Role::DBI::Config>], },
    #logging        => { roles => [qw<Optrade::Role::Logging>], },
    #tuner          => { roles => [qw<Optrade::Role::Tuner>], },
);

sub import {
    my $class  = shift;
    my $target = caller;

    # -role param can only be the first in the list.
    my $isRole = defined $_[0] && $_[0] eq '-role';
    shift if $isRole;    # Remove -role from the arguments list.

    my $baseMod = $isRole ? 'Moo::Role' : 'Moo';
    $_classInfo{$target}{isRole}  = 1;
    $_classInfo{$target}{baseMod} = $baseMod;

    my $featureSet = ':' . DEFAULT_BASEVERSION;
    my ( @passOnParams, @myParams );

    while ( @_ ) {
        my $param = shift;
        #say STDERR "ManulC::Class param: ", $param;
        if ( $param =~ /^:/ ) {
            $featureSet = $param;
        }
        elsif ( defined $paramSet{$param} ) {
            #say STDERR "Using ", $param, " as mine";
            push @myParams, $param;
        }
        else {
            push @passOnParams, $param;
        }
    }

    foreach my $param ( @myParams ) {
        if ( my $installer = __PACKAGE__->can( "_install_$param" ) ) {
            $installer->( $class, $target );
        }
    }

    require feature;
    feature->import( $featureSet );

    Syntax::Keyword::Try->import_into( $target );

    namespace::clean->import(
        -cleanee => $target,
        -except  => qw(meta),
    );

    # class/roleInit MUST be called by a class/role right after 'use Optrade::Role'.
    injectCode(
        $target, ( $isRole ? "roleInit" : "classInit" ),
        sub { _modInit( $target ) }
    );

    @_ = ( $baseMod, @passOnParams );

    goto \&{"${baseMod}::import"};
}

# This sub applies what was defined by parameters.
sub _modInit {
    my $target = shift;

}

sub _install_allTypes {
    my ( $class, $target ) = @_;
    #say STDERR "Installing all types into $target";
    load_remote( $target, "ManulC::Types", qw<-all> );
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
