#
use v5.24;
use utf8;

package Dist::Zilla::App::Command::mc_develinstall 0.001;
use Data::Dumper;
use Syntax::Keyword::Try;
use Path::Tiny;
use Cwd;
require Git::Wrapper;

# ABSTRACT: Manul•C developer installation – install all contribs&plugins as symlinks in the development directory.

use Dist::Zilla::App -command;

sub command_names { qw(mc-develinstall) }

sub abstract { 'Manul•C developer installation' }

#sub description {
#    <<DESC;
#Description is not available yet.
#DESC
#}

sub opt_spec {
    #[ 'symlink!', 'Install submodules by symlinking', { default => !!1 } ],
    #['plugin=s@', 'Specifiy plugins to install'],
}

sub runBuild {
    my $this       = shift;
    my ( $subDir ) = @_;
    my $cwd        = cwd;
    try {
        chdir $subDir or die "Can't chdir to $subDir: " . $!;
        my $buildCmd = "./build";
        $this->zilla->log_debug( "WARNING: $buildCmd is not executable." ) unless -e $buildCmd && -x $buildCmd;
        $buildCmd = "dzil" unless -x $buildCmd;
        my $cmd = "$buildCmd mc-linkinstall";
        system( $cmd );
        die "'$cmd' failed with rc=" . $? if $? != 0;
    }
    catch {
        die $@;
    }
    finally {
        chdir $cwd;
    }
}

sub execute {
    my $this = shift;
    my ( $opt, $arg ) = @_;

    my $zilla  = $this->zilla;
    my $root   = path( $zilla->root )->absolute;
    my @mcLibs = (
        path( $root . '/lib' ),
        path( $root . '/build_lib' ),
    );

    my @autoCreateDirs = qw<lib/ManulC/Plugin lib/ManulC/Contrib>;

    # Prepare environment variables for subprocesses
    $ENV{MANULC_SRC} = $root;
    $ENV{PERL5LIB}   = join(
        ':',
        (
            @mcLibs,
            split /:/, ( $ENV{PERL5LIB} // '' )
          )
    );

    # Autocreate missing directories.
    foreach my $adir ( @autoCreateDirs ) {
        my $subdir = path( $root . "/$adir" );
        unless ( -d $subdir ) {
            $this->log( "Creating missing $adir" );
            $subdir->mkpath( { mode => 0770 } );
        }
    }

    $this->log( "Preparing Manul•C Build contrib." );
    my $buildContribDir = path( $root . "/contrib/ManulCBuild" );
    $this->runBuild( $buildContribDir );

    my $git = Git::Wrapper->new( $root );
    try {
        my @submodList = grep { $_ !~ m[contrib/ManulCBuild] } map { ( split " " )[1] } $git->submodule;
        foreach my $submod ( @submodList ) {
            $this->log( "Installing $submod" );
            my $smDir = path( $root . "/$submod" );
            $this->runBuild( $smDir );
        }
    }
    catch {
        if ( $@->isa( "Git::Wrapper::Exception" ) ) {
            $zilla->log_fatal( "Git failed [rc=" . $@->status . "]: " . $@->error );
        }
        else {
            $zilla->log_fatal( $@ );
        }
    }
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
