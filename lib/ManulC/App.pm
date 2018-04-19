#

package ManulC::App;

use ManulC::Util qw<:namespace :errors>;
use ManulC::Exception;

our $VERSION = 'v0.001.001';

use ManulC::Class -allTypes;
extends qw<ManulC::Object>;

# --- Public attributes

# Server environment variables. PSGI %env, for example.
has env => (
    is      => 'rw',
    isa     => HashRef,
    lazy    => 1,
    builder => 'initEnv',
);

has cfg => (
    is        => 'rw',
    isa       => InstanceOf ['ManulC::Config'],
    predicate => 1,
    lazy      => 1,
    clearer   => 1,
    builder   => 'initCfg',
);

# Class of the engine object.
has engineClass => (
    is      => 'ro',
    isa     => ClassName,
    lazy    => 1,
    default => 'ManulC::Engine::PSGI',
);

# Engine object.
has engine => (
    is      => 'ro',
    isa     => InstanceOf ['ManulC::Engine'],
    lazy    => 1,
    builder => 'initEngine',
);

# HTTP request
has req => (
    is      => 'ro',
    isa     => InstanceOf ['ManulC::Request'],
    lazy    => 1,
    builder => 'initReq',
);

# Extension manager
has extMgr => (
    is        => 'ro',
    lazy      => 1,
    clearer   => 1,
    predicate => 1,
    isa       => InstanceOf ['ManulC::ExtMgr'],
    builder   => 'initExtMgr',
);

# --- Public methods

sub BUILD {
    my $this = shift;

    # This is to prevent ManulC::Object::create() from falling into a deep recursion pitfall. After all, what's the
    # point of pointing to itself?
    $this->_set_app( undef );
}

# Create a new object within ManulC application ecosystem.
around create => sub {
    my $orig      = shift;
    my $this      = shift;
    my $baseClass = shift;

    $baseClass = $this->_preValidateClass( $baseClass );

    my $class = $this->has_extMgr ? $this->extMgr->mapClass( $baseClass ) : $baseClass;

    my @profile;

    if ( hasRegisteredClass( $class ) && $class->isAttribute( 'app' ) ) {
        push @profile, app => $this;
    }

    return $orig->( $this, $class, @profile, @_ );
};

sub run {
    my %profile = @_;

    if ( exists $profile{engine} ) {
        $profile{engineClass} //= 'ManulC::Engine::' . $profile{engine}
          if defined $profile{engine};
        delete $profile{engine};
    }

    my $app = __PACKAGE__->new( %profile );

    return $app->handleRequest;
}

# --- Attribute initializers

sub initEnv {
    my $this = shift;

    if ( $this->TEST ) {
        return \%ENV;
    }
    else {
        FAIL( "Application attribute env must be pre-initialized prior use!" );
    }
}

sub initEngine {
    my $this = shift;

    return $this->create( $this->engineClass );
}

sub initReq {
    my $this = shift;

    return $this->engine->prepareRequest;
}

sub initExtMgr {
    my $this = shift;
    return $this->create( 'ManulC::ExtMgr' );
}

sub initCfg {
    my $this = shift;
    
    return $this->create('ManulC::Config');
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
