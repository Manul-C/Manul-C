#
# ABSTRACT: Manul•C installation of a contrib/extension into the core development directory by symlinking.
use v5.24;

package Dist::Zilla::App::Command::mc_linkinstall 0.001;
use Data::Dumper;
#use Syntax::Keyword::Try;
use File::Spec;

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
    #[ 'symlink!', 'Install submodules by symlinking', { default => !!1 } ],
    #['plugin=s@', 'Specifiy plugins to install'],
}

sub execute {
    my ( $self, $opt, $arg ) = @_;

    my $zill  = $self->zilla;
    my $root  = File::Spec->rel2abs( $zill->root );
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
