#

package ManulC::ExtMgr;
use v5.24;

use Module::Find;
use Module::Path qw<module_path>;
use ManulC::Util qw<:namespace>;

use ManulC::Class -allTypes, -sugar;
extends qw<ManulC::Object>;

# --- Static variables
our $VERSION = 'v0.001.001';

my %registeredExtensions;    # Hash of registered extensions; maps a extension name into its options.

# --- Pre-initializing code

# Register 'extension' syntax sugar – extensions must register themselves by using it.
newSugar -extension => {
    extension => \&_extension_sugar,
};

# --- Public attributes

# Map of full extension names into respecive objects.
has extensions => (
    is      => 'rw',
    lazy    => 1,
    clearer => 1,
    builder => 'initExtensions',
);

has namePrefix => (
    is      => 'rwp',
    coerce  => sub { $_[0] =~ m/^(.*?)(?:\::)?$/; $1 },
    default => 'ManulC::Ext',
);

# List of directories to look for extensions in.
has extDirs => (
    is      => 'rw',
    isa     => ArrayRef [Str],
    lazy    => 1,
    clearer => 1,
    builder => 'initExtDirs',
);

# --- Public methods

sub BUILD {
    my $this = shift;

    $this->loadExtensions;
}

sub normalizeExtName {
    my $this = shift;
    my ( $name, %params ) = @_;

    my $prefix = $params{prefix} // $this->namePrefix;

    return $name =~ /^$prefix/ ? $name : "${prefix}::${name}";
}

sub loadExtensions {
    my $this = shift;

    setmoduledirs( @{ $this->extDirs } );
    my @extModules = findallmod $this->namePrefix;
    setmoduledirs( undef );

    foreach my $extMod ( @extModules ) {
        loadModule( $extMod );
    }
}

# Returns extended name for a base class.
sub mapClass {
    my $this = shift;
    my ($class) = shift;
    # Just a stub for now.
    return $class;
}

# --- Static methods

# Handler for the 'extension' syntax sugar
sub _extension_sugar (%) {
    my ( @params ) = @_;
    my $extModule = caller;    # What module is registering as extension
    registerExtension( $extModule, @params );
}

sub registerExtension {
    my ( $extName, %params ) = @_;

    # XXX TODO Make a copy of %params in first place!
    $registeredExtensions{$extName} = \%params;
}

# --- Attribute initializers

sub initExtensions {
    my $this = shift;
}

sub initExtDirs {
    my $this = shift;

    my $extDirs = $this->app->env->{MANULC_EXTDIRS} // $this->app->env->{MANULC_LIBS};
    unless ( $extDirs ) {
        my $modDir = module_path( __PACKAGE__ ) // $INC{'ManulC/App.pm'};
        my ( $vol, $path ) = File::Spec->splitpath( $modDir );
        my @dirs = File::Spec->splitdir( File::Spec->canonpath( $path ) );
        pop @dirs;    # Remove ManulC part
        $extDirs = File::Spec->catpath( $vol, File::Spec->catdir( @dirs ), undef );
    }

    my @dirList = split /:/, $extDirs;
    # Record all directories from @INC in a hash to test against and avoid duplicate entries.
    my %incDirs = map { File::Spec->rel2abs( $_ ) => 1 } @INC;

    foreach my $dir ( @dirList ) {
        push @INC, $dir unless $incDirs{ File::Spec->rel2abs( $dir ) };
    }

    return \@dirList;
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
