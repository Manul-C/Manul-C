#

package ManulC::Plugin::Empty;

use ManulC::Class -plugin;

our $VERSION = 'v0.001';

plugin
  demands  => [qw<FEATURE1 FEATURE2>],
  abstract => "Some abstract",
  depends  => [qw<OtherPlugin>],
  after    => [qw<NonRequiredPlugin1 NonRequiredPlugin2>],
  before   => q<NonRequiredPlugin3 NonRequiredPlugin4>,
  class    => {
    'ManulC::Response' => 'ManulC::Plugin::Empty::Response',
    'ManulC::UI'       => 'UI',                              # 'ManulC::Plugin::Empty::' will be prepended automatically
  },
  ;

1;

