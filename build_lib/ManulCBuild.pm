#

use v5.24;

package ManulCBuild;
use base qw<Module::Build>;
use File::Spec;
use Data::Dumper;
use Hash::Merge;

sub new {
    my $class   = shift;
    my %profile = @_;

    # It must not be ~/tmp/www
    my $instBase = File::Spec->catdir( $ENV{HOME}, qw<Sites ManulC> );

    my %defaults = (
        install_base => $instBase,
    );

    my $merger = Hash::Merge->new;
    $merger->set_behavior( 'RIGHT_PRECEDENT' );

    my $mergedProfile = $merger->merge( \%defaults, \%profile );

    my $this = $class->SUPER::new( %$mergedProfile );

    $this->install_base_relpaths( static => 'static' );
    $this->install_base_relpaths( store  => 'store' );

    $this->add_build_element( 'static' );
    $this->add_build_element( 'store' );

    return $this;
}

sub _copy_dir {
    my $this    = shift;
    my $rootDir = shift;

    foreach my $sfile ( @{ $this->rscan_dir( $rootDir, sub { -f $_ } ) } ) {
        say STDERR "Copying ", $sfile;
        $this->copy_if_modified(
            from   => $sfile,
            to_dir => $this->blib,
        );
    }

}

sub process_static_files {
    my $this = shift;
    $this->_copy_dir( 'static' );
}

sub process_store_files {
    my $this = shift;
    $this->_copy_dir( 'store' );
}

1;
