#

package ManulC::PluginMgr;
use v5.24;

use Module::Find;
use Module::Path qw<module_path>;
use ManulC::Util qw<:namespace>;

use ManulC::Class -allTypes;
extends qw<ManulC::Object>;

# --- Static variables
our $VERSION = 'v0.001.001';

my %registeredPlugins;    # Hash of registered plugins; maps a plugin name into its options.

# --- Public attributes

# Map of full plugin names into respecive objects.
has plugins => (
    is      => 'rw',
    lazy    => 1,
    clearer => 1,
    builder => 'initPlugins',
);

has namePrefix => (
    is      => 'rwp',
    coerce  => sub { $_[0] =~ m/^(.*?)(?:\::)?$/; $1 },
    default => 'ManulC::Plugin',
);

# List of directories to look for plugins in.
has pluginDirs => (
    is      => 'rw',
    isa     => ArrayRef [Str],
    lazy    => 1,
    clearer => 1,
    builder => 'initPluginDirs',
);

# --- Public methods

sub BUILD {
    my $this = shift;

    $this->loadPlugins;
}

sub normalizePlugName {
    my $this = shift;
    my ( $name, %params ) = @_;

    my $prefix = $params{prefix} // $this->namePrefix;

    return $name =~ /^$prefix/ ? $name : "${prefix}::${name}";
}

sub loadPlugins {
    my $this = shift;

    setmoduledirs( @{ $this->pluginDirs } );
    my @plugModules = findallmod $this->namePrefix;
    setmoduledirs( undef );

    foreach my $plugMod ( @plugModules ) {
        loadModule( $plugMod );
    }
}

# --- Static methods
sub registerPlugin {
    my ( $plugName, %params ) = @_;

    # XXX TODO Make a copy of %params in first place!
    $registeredPlugins{$plugName} = \%params;
}

# --- Attribute initializers

sub initPlugins {
    my $this = shift;
}

sub initPluginDirs {
    my $this = shift;

    my $plugDirs = $this->app->env->{MANULC_PLUGDIRS} // $this->app->env->{MANULC_LIBS};
    unless ( $plugDirs ) {
        my $modDir = module_path( __PACKAGE__ ) // $INC{'ManulC/App.pm'};
        my ( $vol, $path ) = File::Spec->splitpath( $modDir );
        my @dirs = File::Spec->splitdir( File::Spec->canonpath( $path ) );
        pop @dirs;    # Remove ManulC part
        $plugDirs = File::Spec->catpath( $vol, File::Spec->catdir( @dirs ), undef );
    }

    my @dirList = split /:/, $plugDirs;
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
