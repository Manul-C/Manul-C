#
# ABSTRACT: Manul•C installation of a contrib/extension into the core development directory by symlinking.
use v5.24;
use utf8;

package Dist::Zilla::App::Command::mc_linkinstall 0.001;
use Data::Dumper;
use Syntax::Keyword::Try;
use Path::Tiny;

#our $VERSION = 'v0.001.001';

use Dist::Zilla::App -command;

sub command_names { qw(mc-linkinstall) }

sub abstract { 'Manul•C symlinked installation of contribs & plugins' }

#sub description {
#    <<DESC;
#Description is not available yet.
#DESC
#}

sub opt_spec {
    [ 'destination|d=s', 'Manul•C distribution root directory', ],
      #[ 'symlink!', 'Install submodules by symlinking', { default => !!1 } ],
      #['plugin=s@', 'Specifiy plugins to install'],
}

sub link_to_dest {
    my $this   = shift;
    my %params = @_;

    if ( !opendir my $dh, $params{from} ) {
        die "Cannot read from directory $params{from}: " . $!;
    }

    try {
        foreach my $entry ( readdir $dh ) {
            next if $entry =~ /^\.\.?$/n;
            my $fromPath = path( $params{from} . "/$entry" );
            my $destPath = path( $params{to} . "/$entry" );
            if ( -e $destPath ) {
                if ( -l $destPath ) {
                    my $linkVal = readlink $destPath;
                    die "Cannot read symlink " . $destPath . ": " . $! unless defined $linkVal;
                    $linkVal  = path( $linkVal )->absolute;
                    $fromPath = path($fromPath )->absolute;
                    die "Destination link doesn't point back to the source: " . $linkVal . " != " . $fromPath
                      if $linkVal != $fromPath;
                }
                elsif ( -d $destPath ) {
                    if ( -f $fromPath ) {
                        die "Entries mismatch: destination "
                          . $destPath
                          . " is a directory while source "
                          . $fromPath
                          . " is a plain file";
                    }
                    $this->link_to_dest(
                        from     => $fromPath,
                        to       => $destPath,
                        packlist => $params{packlist},
                    );
                }
                elsif ( -f $destPath && -d $fromPath ) {
                    die "Entries mismatch: destination "
                      . $destPath
                      . " is a plain file while source "
                      . $fromPath
                      . " is a directory";
                }
            }
            else {
                $this->log( "$fromPath => $destPath" );
                if ( !symlink $fromPath, $destPath ) {
                    die "Failed to link $fromPath to $destPath: $!";
                }
            }
        }
    }
    catch {
        # Rethrow exception.
        die $@;
    }
    finally {
        closedir $dh;
    }
}

sub execute {
    my ( $this, $opt, $arg ) = @_;

    my $zill   = $this->zilla;
    my $root   = $zill->root->absolute;

    # Check if symlinks are supported on this system
    try {
        # Would die if no symlinking on this system.
        symlink( "", "" );
    }
    catch {
        die "linkinstall won't work on ", $^O, ": no symlinking support";
    }

    my $destBase = $opt->destination || $ENV{MANULC_SRC};

    die "linkinstall requires MANULC_SRC environment variable or --destination to be set" unless $destBase;

    foreach my $entry ( qw<lib static store> ) {
        my $fromPath = path( $root . "/$entry" );
        next unless -d $fromPath;
        my $destPath = path( $destBase . "/$entry" );
        $this->link_to_dest(
            from => $fromPath,
            to   => $destPath,
        );
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
