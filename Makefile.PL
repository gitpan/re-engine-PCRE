use strict;
use inc::Module::Install;

perl_version '5.009005';

name 're-engine-PCRE';
{ use utf8; author 'Ævar Arnfjörð Bjarmason <avar@cpan.org>'; }

abstract_from 'PCRE.pm';
license_from 'PCRE.pm';
version_from 'PCRE.pm';

# t/
build_requires 'Config'     => 0;
build_requires 'XSLoader'   => 0;
build_requires 'Test::More' => 0; # 5.007003

my $extra = 'PCRE.c';
my @C = grep { $_ ne $extra } glob "*.c";
my $object = join " ", map { s/\.c$/\$(OBJ_EXT)/; $_ } (@C => $extra);

makemaker_args DEFINE => pcre_config_h();
makemaker_args INC    => '-I.';
makemaker_args C      => [ @C ];
makemaker_args XS     => { 'PCRE.xs' => 'PCRE.c' };
makemaker_args OBJECT => $object;
makemaker_args clean  => { FILES => "*\$(OBJ_EXT) $extra" };

tests 't/*.t t/*/*.t';

auto_install;
WriteAll;

sub pcre_config_h
{
    my @def;

    my @config_h2Configure = (
        'EBCDIC'           => 'ebcdic',
        # 'HAVE_BITS_TYPE_TRAITS_H',
        'HAVE_BCOPY'       => 'd_bcopy',
        'HAVE_DIRENT_H'    => 'i_dirent',
        'HAVE_DLFCN_H'     => 'i_dlfcn',
        'HAVE_INTTYPES_H'  => 'i_inttypes',
        'HAVE_LIMITS_H'    => 'i_limits',
        'HAVE_LONG_LONG'   => 'd_longlong',
        'HAVE_MEMMOVE'     => 'd_memmove',
        'HAVE_MEMORY_H'    => 'i_memory',
        #'HAVE_STDINT_H',     # XXX
        'HAVE_STDLIB_H'    => 'i_stdlib',
        'HAVE_STRERROR'    => 'd_strerror',
        #'HAVE_STRING',        # XXX
        #'HAVE_STRINGS_H',     # XXX
        #'HAVE_STRING_H',      # XXX
        'HAVE_STRTOLL'     => 'd_strtollp',
        'HAVE_STRTOQ'      => 'd_strtoq',
        'HAVE_SYS_STAT_H'  => 'i_sysstat',
        'HAVE_SYS_TYPES_H' => 'i_systypes',
        #'HAVE_TYPE_TRAITS_H', # XXX
        'HAVE_UNISTD_H'    => 'i_unistd',
        #'HAVE_UNSIGNED_LONG_LONG', # XXX
    );

    # config.h to -D via Configure.pm
    while (my @kv = splice @config_h2Configure, 0, 2) {
        use Config;
        push @def => $kv[0] if $Config{$kv[1]};
    }

    # Assume that we have windows.h on Win32
    push @def => 'HAVE_WINDOWS_H' if $^O eq 'MSWin32',

    # Options that are set manually by the maintainer, see libpcre's
    # config.h for information about the keys
    push @def => 'LINK_SIZE=2';
    push @def => 'MATCH_LIMIT=10000000';
    push @def => 'MATCH_LIMIT_RECURSION=10000000';
    push @def => 'MAX_DUPLENGTH=30000';
    push @def => 'MAX_NAME_COUNT=10000';
    push @def => 'MAX_NAME_SIZE=32';
    push @def => 'NEWLINE=10';
    #push @def => 'NO_RECURSE';

    # The PCRE version needs to be updated if the library is
    push @def => 'PACKAGE=pcre';
    push @def => 'PACKAGE_BUGREPORT=avar@cpan.org';
    push @def => 'PACKAGE_NAME=PCRE';
    push @def => 'PACKAGE_STRING="PCRE 7.2"';
    push @def => 'PACKAGE_TARNAME=pcre';
    push @def => 'PACKAGE_VERSION=7.2';

    # push @def => 'PCRE_EXP_DEFN';
    # push @def => 'PCRE_STATIC';

    push @def => 'POSIX_MALLOC_THRESHOLD=10';
    push @def => 'STDC_HEADERS';

    # If Unicode properties are not supported, \X, \P, and \p are not
    # allowed
    push @def => 'SUPPORT_UCP';

    # Support for the UTF-8 Unicode encoding.
    push @def => 'SUPPORT_UTF8';

    # pcre_printint.src 
    #push @def => 'DEBUG=1';

    # XS defines this too and PCRE doesn't seem to use it
    #push @def => 'VERSION="7.2"';

    return join ' ', map { "-D$_" } @def;
}
