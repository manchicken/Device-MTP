# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Device-MTP.t'

use constant DEBUG => $ENV{DEBUG};

#########################
use lib ('../lib','./lib');
# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 24;
BEGIN { use_ok('Device::MTP') };

use Data::Dumper;

my $device = undef;
ok($device = Device::MTP->grab_device(), "Grab device object...");
DEBUG && diag(Dumper($device));

my $modelname = undef;
ok($modelname = $device->model_name(), "Grabbing model name...");
DEBUG && diag("Model name is $modelname.");

my $serial = undef;
ok($serial = $device->serial_number(), "Grabbing serial number...");
DEBUG && diag("Serial number is $serial.");

my $version = undef;
ok($version = $device->version(), "Grabbing the version...");
DEBUG && diag("Version is $version.");

my $owner = undef;
ok($owner = $device->device_name(), "Grabbing the device name...");
DEBUG && diag("Owner is $owner.");

my $info = undef;
ok($info = $device->storage_info(), "Grabbing storage info...");
DEBUG && diag(Dumper($info));

my $batt = undef;
ok($batt = $device->battery_level(), "Grabbing battery level...");
DEBUG && diag(Dumper($batt));

my $sec_time = undef;
ok($sec_time = $device->secure_time(), "Grabbing secure time...");
DEBUG && diag($sec_time);

my $cert = undef;
ok($cert = $device->certificate(), "Grabbing device certificate...");
DEBUG && diag($cert);

my @ftypes = ();
ok(@ftypes = $device->supported_file_types(), "Grabbing supported file types...");
DEBUG && diag(Dumper(\@ftypes));

my @files = ();
ok(@files = $device->files(), "Grabbing file list...");
DEBUG && diag(Dumper(\@files));

my $use_file = $files[-2];
my $folder = undef;
ok($folder = $use_file->folder(), "Grabbing folder entry...");
DEBUG && diag("File: ".Dumper($use_file)."\nFolder: ".Dumper($folder));

my $pfolder = undef;
ok($pfolder = $folder->parent_folder(), "Grabbing parent folder...");
DEBUG && diag(Dumper($pfolder));

my $music = undef;
ok($music = $device->music_folder(), "Grabbing music folder...");
DEBUG && diag(Dumper($music));

my @musics = ();
ok(@musics = $music->files(), "Grabbing music file listing...");
DEBUG && diag(Dumper(\@musics));

my $org = undef;
ok($org = $device->organizer_folder(), "Grabbing organizer folder...");
DEBUG && diag(Dumper($org));

my $pic = undef;
ok($pic = $device->picture_folder(), "Grabbing picture folder...");
diag(Dumper($pic));

my $plist = undef;
ok($plist = $device->playlist_folder(), "Grabbing playlist folder...");
DEBUG && diag(Dumper($plist));

my $vid = undef;
ok($vid = $device->video_folder(), "Grabbing video folder...");
DEBUG && diag(Dumper($vid));

my $cast = undef;
ok($cast = $device->zencast_folder(), "Grabbing zencast folder...");
DEBUG && diag(Dumper($cast));

my @casts = ();
ok(@casts = $cast->files(), "Grabbing zencast files...");
DEBUG && diag(Dumper(\@casts));

sub callback_func {
  my ($complete, $total) = @_;
  my $percent = int(($complete / $total)*100);

  printf("Progress: %d of %d bytes (%d%%)\n", $complete, $total, $percent);
  return;
}

ok($device->send_file("t/test_image.jpg", $device->picture_folder->id, \&callback_func), "Send an image...") ||
  diag("Failed: ".$Device::MTP::ERRMSG." -- ".$!);

ok($device->release(), "Release the device object...");
