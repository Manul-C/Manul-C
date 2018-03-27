#
use v5.24;
use FindBin;
use File::Spec;
use Module::Loaded;
use Module::Load;

use constant MAIN_MODULE => 'ManulC';

sub envLib {
    return $ENV{MANULC_LIB};
}

sub envRoot {
    return $ENV{MANULC_ROOT};
}

sub _byBase {
    my $baseDir = shift;

    # Split with $no_file=true
    my ( $vol, $dir ) = File::Spec->splitpath( $baseDir, 1 );
    my @dir = File::Spec->splitdir( $dir );

    # Empty dir??? How come? But, anyway – don't try it.
    return undef if !@dir;

    pop @dir;
    return File::Spec->catpath( $vol, File::Spec->catdir( @dir ) );
}

sub byBin {
    return _byBase($FindBin::Bin);
}

sub byRealBin {
    return _byBase($FindBin::RealBin);
}

sub findLibs {
    my @methods = qw<envLib envRoot byBin byRealBin>;

  ITERATE:
    foreach my $method ( @methods ) {
        no strict 'refs';
        my $libDir = $method->();
        use strict 'refs';
        if ( $libDir ) {
            unshift @INC, $libDir;
            load MAIN_MODULE;
            if (is_loaded( MAIN_MODULE )) {
                say STDERR "Found module in ", $libDir, " by ", $method;
                last ITERATE;
            }
            # Unsuccessfull
            shift @INC;
        }
    }
}

findLibs();

my $app = \&ManulC::App->psgi;
