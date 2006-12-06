use strict;
use inc::Module::Install;

name            're-engine-PCRE';
all_from        'lib/re/engine/PCRE.pm';
cc_inc_paths    '.';
cc_files        (grep { !/printint|ucp(?:type)?table/ } glob("*.c"));

can_cc() or die "This module requires a C compiler";

sign; WriteAll;
