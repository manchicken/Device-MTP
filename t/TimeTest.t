use lib ('../lib','./lib');
# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 4;
BEGIN { use_ok('Device::MTP') };

use Data::Dumper;
use constant TOTAL_SLEEP=>300;
use constant SLEEP_INCREMENT=>2;

my $device = undef;
ok($device = Device::MTP->grab_device(), "Grab device object...");
#DEBUG && diag(Dumper($device));

my $sleep_time = TOTAL_SLEEP;
while ($sleep_time) {
  print "Sleeping $sleep_time more seconds...          \r";
  my $bit = SLEEP_INCREMENT;
  $sleep_time -= $bit;
  sleep($bit);
}
print "\n";

my @ftypes = ();
ok(@ftypes = $device->supported_file_types(), "Grabbing supported file types...");
diag(Dumper(\@ftypes));


ok($device->release(), "Release the device object...");
