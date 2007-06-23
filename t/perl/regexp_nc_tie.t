use Test::More tests => 13;
use re::engine::PCRE;

"hlagh" =~ /
    (?<a>.)
    (?<b>.)
    (?<c>.)
    .*
    (?<d>$)
/x;

# FETCH
is($+{a}, "h", "FETCH");
is($+{b}, "l", "FETCH");
is($+{c}, "a", "FETCH");
is($+{d}, "", "FETCH");

# STORE
eval { $+{a} = "yon" };
ok(index($@, "read-only") != -1, "STORE");

# DELETE
eval { delete $+{a} };
ok(index($@, "read-only") != -1, "DELETE");

# CLEAR
eval { %+ = () };
ok(index($@, "read-only") != -1, "CLEAR");

# EXISTS
ok(exists $+{b}, "EXISTS");
ok(!exists $+{e}, "EXISTS");

# FIRSTKEY/NEXTKEY
is(join('|', sort keys %+), "a|b|c|d", "FIRSTKEY/NEXTKEY");
is(join('|', sort keys %-), "a|b|c|d", "FIRSTKEY/NEXTKEY");

# SCALAR
is(scalar(%+), 4, "SCALAR");
is(scalar(%-), 4, "SCALAR");
