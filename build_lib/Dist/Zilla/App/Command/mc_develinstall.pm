#
use strict;
use warnings;

package Dist::Zilla::App::Command::mc_develinstall 0.001;
use Data::Dumper;
use Syntax::Keyword::Try;
use Path::Tiny;
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

sub execute {
    my ( $self, $opt, $arg ) = @_;

    my $zill   = $self->zilla;
    my $root   = path( $zill->root )->absolute;
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
        path( $root . "/$adir" )->mkpath( { mode => 0770 } );
    }

    my $buildContribDir = path( $root . "/contrib/ManulCBuild" );
    chdir $buildContribDir or die "Cannot chdir to $buildContribDir: $!";

    try {
        system( "dzil mc-linkinstall" );
        die "mc-linkinstall failed for Build contrib" if $? != 0;
    }
    catch {
        chdir $root;
        die $@;
    }

    my $git = Git::Wrapper->new( $root );
    try {
        my @shCmd;
        #my @shCmd = $opt->symlink ? ( "MANULC_USE_SYMLINKS=1" ) : ();
        push @shCmd, (
            "dzil mc-linkinstall",
            #'dzil build --in .MCdistro',
            #'cd .MCdistro',
            #"perl Build.PL",
            #"./Build develinstall",
            #"cd ..",
            #"rm -rf .MCdistro",
        );
        say STDERR join( "\n", $git->submodule( foreach => join( " && ", @shCmd ) ) );
    }
    catch {
        say STDERR "Git failed [rc=", $@->status, "]: ", $@->error;
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
