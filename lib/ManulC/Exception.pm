#

package ManulC::Exception;

our $VERSION = 'v0.001.001';

use ManulC::Class;
extends qw<ManulC::Object>;
with 'Throwable';

# Exception main message.
has message => (
    is => 'rw',
    lazy => 1,
    builder => 'initMessage',
);

sub initMessage {
    my $this = shift;
    return 'INTERNAL ERROR: No exception message was provided';
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
