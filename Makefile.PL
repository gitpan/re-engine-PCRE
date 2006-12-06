use strict;
use ExtUtils::MakeMaker;
my @cfiles = grep { !/printint|ucp(?:type)?table|engine/ } glob("*.c");
my @extra = ('engine.c');    
my $object = join " ", map { my $s=$_; $s=~s/\.c$/\$(OBJ_EXT)/; $s } @cfiles,@extra;

WriteMakefile(
    NAME		=> 're::engine::PCRE',
    VERSION_FROM	=> 'lib/re/engine/PCRE.pm',
    MAN3PODS		=> {}, 	# Pods will be built by installman.
    XSPROTOARG		=> '-noprototypes',
    C                   => [ @cfiles ],
    XS                  => {
                             'engine.xs' => 'engine.c'
                           },
    OBJECT		=> $object,
    #DEFINE              => $defines,
    clean		=> { FILES => '*$(OBJ_EXT) engine.c' },
);

#cc_inc_paths    '.';
#cc_files        (grep { !/printint|ucp(?:type)?table/ } glob("*.c"));
#can_cc() or die "This module requires a C compiler";
#sign; WriteAll;
