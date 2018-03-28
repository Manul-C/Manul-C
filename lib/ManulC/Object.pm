#

package ManulC::Object;

our $VERSION = 'v0.001.001';

use Devel::StackTrace;
use Scalar::Util qw(blessed refaddr reftype weaken isweak);

use ManulC::Exception;

use ManulC::Class;
classInit;

# --- Internal attributes

has __id => (
    is      => 'ro',
    lazy    => 1,
    clearer => 1,
    default => sub {
        my $this  = shift;
        my $strID = ref( $this ) . '_' . refaddr( $this );
        $strID =~ s/:/_/g;
        return $strID;
    },
);

# --- Public attributes
# Main application object.
has app => (
    is        => 'rwp',
    predicate => 1,
    weak_ref  => 1,
);

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
