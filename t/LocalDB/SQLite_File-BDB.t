# -*-perl-*-
# $Id$

BEGIN {
    use lib '../..';
    use Bio::Root::Test;
    @AnyDBM_File::ISA = qw( Bio::DB::SQLite_File );
    test_begin( -tests => 100,
		-requires_module => 'DBD::SQLite' );
    use Fcntl qw(O_CREAT O_RDWR O_RDONLY);
    use_ok( AnyDBM_File );
}

my $DB_HASH = $Bio::DB::SQLite_File::DB_HASH;
my $DB_BTREE = $Bio::DB::SQLite_File::DB_BTREE;
my $DB_RECNO = $Bio::DB::SQLite_File::DB_RECNO;
use constant { R_DUP => Bio::DB::SQLite_File::R_DUP(),
	       R_CURSOR => Bio::DB::SQLite_File::R_CURSOR(),
	       R_FIRST => Bio::DB::SQLite_File::R_FIRST(),
	       R_LAST => Bio::DB::SQLite_File::R_LAST(),
	       R_NEXT => Bio::DB::SQLite_File::R_NEXT(),
	       R_PREV => Bio::DB::SQLite_File::R_PREV(),
	       R_IAFTER => Bio::DB::SQLite_File::R_IAFTER(),
	       R_IBEFORE => Bio::DB::SQLite_File::R_IBEFORE(),
	       R_NOOVERWRITE => Bio::DB::SQLite_File::R_NOOVERWRITE(),
	       R_SETCURSOR => Bio::DB::SQLite_File::R_SETCURSOR()
};

my %db;
my $flags = O_CREAT | O_RDWR;
ok tie( %db, 'AnyDBM_File', 'my.db', $flags, 0666, undef, 0), "tie";
my $db = tied %db;

ok @db{qw( 1 2 3 4 5 6 7 8 )} = qw( a b c d e f g h ), "set";

# test: put, get, del, seq 
# all flags, boundaries
my ($key, $value, $ret);
$key = 4;
$value = 'D';

ok !$db->put($key, $value), "put replace";
ok !$db->get($key, $ret), "get";
is($ret, 'D', "correct put/get");

ok !$db->seq($key, $value, R_FIRST), "seq R_FIRST";
is ($key, '1', "key correct");
is ($value, 'a', "value correct");

ok !$db->seq($key, $value, R_NEXT), "seq R_NEXT";
is ($key, '2', "key correct");
is ($value, 'b', "value correct");

ok !$db->del($key, R_CURSOR), "del R_CURSOR";
ok !$db->seq($key, $value, R_CURSOR), "seq R_CURSOR";
is ($key, '3', "key correct on cursor update from del");
is ($value, 'c', "value correct on cursor update from del");

ok delete $db{'4'}, "create a stray undef with the other API";
ok !$db->seq($key, $value, R_NEXT), "run into the undef with seq/R_NEXT";
is ($key, '5', "key correct seq R_NEXT");
is ($value, 'e', "value correct seq R_NEXT");
ok !$db->seq($key, $value, R_PREV), "seq R_PREV";
is ($key, '3', "key correct seq R_PREV");
is ($value, 'c', "value correct seq R_PREV");

ok !$db->seq($key, $value, R_LAST), "seq R_LAST";
is ($key, '8', "key correct seq R_LAST");
is ($value, 'h', "value correct seq R_LAST");
# note following, NO "!"
ok $db->seq($key, $value, R_NEXT), "check fail for R_NEXT";
!$db->seq($key, $value, R_FIRST);
ok $db->seq($key, $value, R_PREV), "check fail for R_PREV";
# put with flags
$DB::single=1;
$key = 100;
$value = 'Z';
ok !$db->put($key, $value, R_IBEFORE), "put R_IBEFORE";
is($key, 0, "key set to recno");
ok !$db->seq($key, $value, R_CURSOR), "what's at the cursor";
is($value, 'a', "cursor didn't float");
ok !$db->seq($key, $value, R_FIRST), "what's at the top";
is($value, 'Z', "correct put R_IBEFORE");
$key = 101;
$value = 'X';
ok !$db->put($key, $value, R_SETCURSOR), "put R_SETCURSOR";
ok !$db->get($key, $value, R_CURSOR), "what's at the cursor";
is ($value, 'X', "cursor floated");
$key = 102;
$value = 'Y';
ok !$db->put($key, $value, R_IAFTER), "put R_IAFTER";
ok !$db->seq($key, $value, R_NEXT), "what's after the cursor?";
is($value, 'Y', "what we just put");
ok !$db->seq($key, $value, R_LAST), "what's at the bottom?";
is($value, 'Y', "what we just put");
# no '!'
ok $db->put($key, $value, R_NOOVERWRITE), "put R_NOOVERWRITE";


undef $db;
ok untie %db;

my @db;
ok tie( @db, 'AnyDBM_File', undef, $flags, 0666, $DB_RECNO), "tied array";
$db = tied @db;

ok untie(@db);

1;
