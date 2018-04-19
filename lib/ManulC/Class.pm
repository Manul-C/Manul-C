#

package ManulC::Class;

use v5.24;
use utf8;

our $VERSION = 'v0.001.001';

require Moo;
require Moo::Role;
require namespace::clean;
require Syntax::Keyword::Try;
require MooX::TypeTiny;

use Data::Dumper;
use B::CompilerPhase::Hook qw<enqueue_UNITCHECK>;

use Module::Load qw<load load_remote>;
use ManulC::Util qw<:namespace>;

use constant DEFAULT_BASEVERSION => '5.24';

# Data about each class declared with this module.
our %_classInfo;

# Module options and their properties
my %_optionSet = (
    '-role'      => { handler => \&_option_role, },
    '-allTypes'  => {},
    '-extension' => { roles => [qw<ManulC::Role::Extension>], },
    '-parent'    => { roles => [qw<ManulC::Role::Parent>], },
    '-child'     => { roles => [qw<ManulC::Role::Child>], },
);

# Syntax sugars. See registerSugar().
# Format: sugarName => { code => \&sub }
my %_sugars = (
    newSugar => {
        code   => \&registerSugar,
        option => '-sugar',
    },
);

# Register all currently existing syntax sugars on their respective options
_updateSugars();

# **BEGIN Install wrappers for Moo's has/with/extends to record basic object

# Moo doesn't provide a clean way to get all object's attributes. The only
# really good way to distinguish between a key on object's hash and an
# attribute is to record what is passed to Moo's sub 'has'. Since Moo
# generates it for each class separately (as well as other 'keywords') and
# since Moo::Role does it on its own too then the only correct approach to
# intercept everything is to tap into Moo's guts. And the best way to do so
# is to intercept calls to _install_tracked() as this sub is used to
# register every single Moo-generated code ref. Though this is a hacky way
# on its own but the rest approaches seem to be even more hacky and no doubt
# unreliable.
#
# Additionally, interception is used to tap into processing of Moo::extends in
# order to apply modifiers to the target classes. This is the only known way to
# get around a problem with failed to compile modules. The problem is about
# applying roles to them. This is causing a fatal exception which masks the
# actual compilation error.

my %MooSugars = (
    'extends' => '_after_extends',
    'with'    => '_after_with',
    'has'     => '_after_has',
);

foreach my $module ( qw(Moo Moo::Role) ) {
    my $_install_tracked = ManulC::Util::fetchGlobal( "&${module}::_install_tracked" );
    ManulC::Util::injectCode(
        $module,
        '_install_tracked',
        sub {
            my $ovCode;
            my $target    = $_[0];
            my $codeName  = $_[1];
            my $ovSubName = $MooSugars{$codeName};
            $ovCode = __PACKAGE__->can( $ovSubName ) if $ovSubName;
            if ( $ovCode ) {

                #say STDERR "Installing wrapper $codeName on $target";
                my $origCode = $_[2];
                $_[2] = sub {

                    #say STDERR "Orig ${target}::$codeName(".join(",",@_).") code first.";
                    &$origCode( @_ );

                    #say STDERR "Extension ${target}::$codeName code next.";
                    $ovCode->( $target, @_ );
                };
            }
            goto &$_install_tracked;
        }
    );
}

# **END of has/with/extends wrappers.

sub import {
    my $class  = shift;
    my $target = caller;

    $_classInfo{$target}{baseMod} = 'Moo';    # The target is a class by default.

    my $featureSet = ':' . DEFAULT_BASEVERSION;
    my @passOnOpts;
    my @myOpts = qw<-all>;                    # -all is applied by default and cannot be turned off.

    #say STDERR Dumper( \%_optionSet );

    while ( @_ ) {
        my $option = shift;
        if ( $option =~ /^:/ ) {
            $featureSet = $option;
        }
        elsif ( defined $_optionSet{$option} ) {
            #say STDERR "Using ", $option, " as mine";
            push @myOpts, $option;
        }
        else {
            push @passOnOpts, $option;
        }
    }

    foreach my $myOpt ( @myOpts ) {
        ( my $optName = $myOpt ) =~ s/^-//;
        #say STDERR "Applying option $myOpt to $target";

        if ( $_optionSet{$myOpt}{roles} ) {
            _assign_roles( $target, @{ $_optionSet{$myOpt}{roles} } );
        }

        if ( $_optionSet{$myOpt}{handler} ) {
            $_optionSet{$myOpt}{handler}->( $class, $target );
        }

        # Install pre-registered syntax sugars.
        if ( $_optionSet{$myOpt}{sugars} ) {
            foreach my $sgName ( @{ $_optionSet{$myOpt}{sugars} } ) {
                ManulC::Util::injectCode( $target, $sgName, $_sugars{$sgName}{code} );
            }
        }

        if ( my $installer = __PACKAGE__->can( "_install_$optName" ) ) {
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

    if ( $_classInfo{$target}{isRole} ) {
        # Auto-init roles only where 'extends' sugar is not used.
        # For classes we only can do it _after_ extends for the roles to be correctly applied
        enqueue_UNITCHECK {
            # Automate application of roles and any other post-load procedures.
            _modInit( $target );
        };
    }

    # classInit might be useful for non-ManulC::Object based classes. Though there must be no such classes!
    #ManulC::Util::injectCode(
    #    $target, ( $_classInfo{$target}{isRole} ? "roleInit" : "classInit" ),
    #    sub { _modInit( $target ) }
    #);

    my $baseMod = $_classInfo{$target}{baseMod};
    @_ = ( $baseMod, @passOnOpts );
    goto \&{"${baseMod}::import"};
}

# This sub applies what was defined by options.
sub _modInit {
    my $target = shift;

    _apply_roles( $target );
}

sub _option_role {
    my ( $class, $target ) = @_;

    $_classInfo{$target}{isRole}  = 1;
    $_classInfo{$target}{baseMod} = 'Moo::Role';
}

# Records the roles to be assigned to the target class.
sub _assign_roles {
    my $class = shift;
    push @{ $_classInfo{$class}{assignedRoles} }, @_;
}

# Applies earlier recorded roles to the class.
# XXX REDO!!!!
sub _apply_roles {
    my @targets = grep { defined $_classInfo{$_}{assignedRoles} } ( scalar( @_ ) ? @_ : keys %_classInfo );
    
    return if @targets < 1;

    #state $level = 0;
    state $nowApplying = 0;
    
    #my $pfx = "  " x $level++;

    #say STDERR $pfx, "###[$nowApplying] _apply_roles(", join( ",", @targets ), ")";

    foreach my $target ( @targets ) {
        $nowApplying++;
        my @classRoles = @{ $_classInfo{$target}{assignedRoles} };
        #say STDERR $pfx, "###[$nowApplying] preloading role modules [", join( ",", @classRoles ), "] for $target";
        # Preload modules. This must reveal any possible syntax errors.
        loadModule( $_ ) foreach @classRoles;
        $nowApplying--;
    }

    if ( !$nowApplying ) {
        #say STDERR $pfx, "###[$nowApplying] Actually applying roles";
        foreach my $target ( @targets ) {
            my @classRoles = @{ $_classInfo{$target}{assignedRoles} };

            push @{ $_classInfo{$target}{WITH} }, @classRoles;

            #say STDERR $pfx, "###[$nowApplying] Apply roles->roles for $target: [", join( ",", @classRoles ), "]";
            _apply_roles( @classRoles );
            Moo::Role->apply_roles_to_package( $target, @classRoles );
            $_classInfo{$target}{baseMod}->_maybe_reset_handlemoose( $target );
            delete $_classInfo{$target}{assignedRoles};
        }
    }
    
    #$level--;

}

# _rebuildCache() rebuilds cached information about class' structures. Note that it doesn't rebuilds all information but
# rather updates cache with newly declared classes.
sub _rebuildCache {
    foreach my $class ( @_ ) {
        next if defined $_classInfo{'.cached'}{$class};
        my @classAttrs;
        if ( defined $_classInfo{$class}{registeredAttrs} ) {
            if ( defined $_classInfo{$class}{registeredAttrs}{list} ) {
                push @classAttrs,
                  map { $_->{attr} }
                  @{ $_classInfo{$class}{registeredAttrs}{list} };
            }
        }
        if ( defined $_classInfo{$class}{ISA} ) {
            push @classAttrs, getAllAttrs( @{ $_classInfo{$class}{ISA} } );
        }
        if ( defined $_classInfo{$class}{WITH} ) {
            push @classAttrs, getAllAttrs( @{ $_classInfo{$class}{WITH} } );
        }
        my @base = eval "\@$class\::ISA";
        push @classAttrs, getAllAttrs( @base ) if @base;

        # Leave uniq only attrs.
        @classAttrs = keys %{ { map { $_ => 1 } @classAttrs } };
        $_classInfo{'.cached'}{$class}{registeredAttrs} =
          { map { $_ => !!1, } @classAttrs };
    }
}

# Returns list of all class(es) attributes, including its roles and ancestors.
# Accepts list of classes as parameters
sub getAllAttrs {
    _rebuildCache( @_ );
    return map { keys %{ $_classInfo{'.cached'}{$_}{registeredAttrs} } } @_;
}

# Returns a hash of $class registered attributes. Hash maps attribute name into true value.
sub getClassAttrs {
    my ( $class ) = @_;
    _rebuildCache( $class );
    return $_classInfo{'.cached'}{$class}{registeredAttrs};
}

sub registeredClass {
    my ( $class ) = @_;
    return defined $_classInfo{$class};
}

sub _updateSugars {
    # Clean up old sugar registrations;
    foreach my $opt ( keys %_optionSet ) {
        $_optionSet{$opt}{sugars} = [];
    }
    # Build new lists of registered sugars.
    foreach my $sgName ( keys %_sugars ) {
        push @{ $_optionSet{ $_sugars{$sgName}{option} }{sugars} }, $sgName;
    }
}

# Registration of a new syntax sugar. Any module loaded after this call could make use of it.
#registerSugar(
#    -all => {
#        sugar1 => \&_handler_sugar1,
#    },
#    -extensions => {
#        sugar2 => {
#            code => \&_handler_sugar2,
#        },
#    },
#);
sub registerSugar {
    my %params = @_;

    foreach my $option ( keys %params ) {
        foreach my $sgName ( keys %{ $params{$option} } ) {
            my $sgParam = $params{$option}{$sgName};

            die "No parameters for new sugar $sgName" unless defined $sgParam;
            die "Bad parameters type for new sugar $sgName: must be a hash or code ref but got "
              . ( ref( $sgParam ) || 'SCALAR' )
              unless ref( $sgParam ) && ref( $sgParam ) =~ /^(CODE|HASH)$/n;
            die "No code defined for sugar $sgName"
              unless ref( $sgParam ) eq 'CODE' || ( defined $sgParam->{code} && ref( $sgParam->{code} ) eq 'CODE' );
            die "Duplicate sugar name $sgName" if exists $_sugars{$sgName};

            $sgParam = { code => $sgParam } if ref( $sgParam ) eq 'CODE';
            $sgParam->{option} = $option;
            $_sugars{$sgName} = $sgParam;
            push @{ $_optionSet{$option}{sugars} }, $sgName;
        }
    }

    _updateSugars;
}

sub _after_extends {
    my $target = shift;

    #say STDERR "_after_extends(", $target, ")";

    push @{ $_classInfo{$target}{ISA} }, @_;
    delete $_classInfo{'.cached'};

    _modInit( $target );
}

sub _after_with {
    my $target = shift;

    push @{ $_classInfo{$target}{WITH} }, @_;
    delete $_classInfo{'.cached'};
}

sub _after_has {
    my $target = shift;
    my ( $attr ) = @_;

    #say STDERR "Recording attribute $attr on $target";

    my $attrData = { attr => $attr, options => [ @_[ 1 .. $#_ ] ] };
    push @{ $_classInfo{$target}{registeredAttrs}{list} }, $attrData;
    delete $_classInfo{'.cached'};
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
