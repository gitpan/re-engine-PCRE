use strict;
use inc::Module::Install;

if (not -e "pcre_wrap.c") {
    system(
        'swig',
        qw(-noproxy -module re::engine::PCRE -includeall -exportall -perl5 pcre.i)
    )
}

name            're-engine-PCRE';
all_from        'lib/re/engine/PCRE.pm';
cc_inc_paths    '.';
cc_files        (grep { !/printint|ucp(?:type)?table/ } glob("*.c"));

can_cc() or die "This module requires a C compiler";

sign; WriteAll;
