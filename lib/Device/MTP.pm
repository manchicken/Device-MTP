#/*
package Device::MTP;

use 5.008008;
use strict;
use warnings;

our $VERSION = '0.01';
use vars qw{$ERRMSG};
$Device::MTP::ERRMSG = "";

use Inline (
	    C => 'DATA',
	    LIBS=>`pkg-config --libs libmtp`." -L/usr/local/lib -ggdb3",
	    NAME=>"Device::MTP",
	    CCFLAGS=>'-ggdb3',
	    WARNINGS=>'all',
	    OPTIMIZE=>'-g -ggdb3',
	    VERSION=>$VERSION,
	    CLEAN_AFTER_BUILD=>0,
	    FORCE_BUILD=>1,
	    CCFLAGS=>`pkg-config --cflags libmtp`,
	);
Inline->init();

# require Exporter;
# our @ISA = qw(Exporter);
# our %EXPORT_TAGS = ( 'all' => [ qw(
# ) ] );
# our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
# our @EXPORT = qw(
# );

use Device::MTP::Device;
use Device::MTP::File;
#use Data::Dumper;

sub new {
  return bless({},shift);
}

sub grab_device {
  my ($class, %opts) = @_;

  return Device::MTP::Device->from_handle(handle=>$class->_get_first_device(),%opts);
}

my $pkg_init;
$pkg_init = sub {
  mtp_init();
  $pkg_init = sub{};
};

sub _probe {
  my ($class) = @_;

  $pkg_init->();
  my $retval = mtp_probe();

  return $retval;
}

sub _get_first_device {
  my ($class) = @_;

  $pkg_init->();

  $class->_probe() || die ("Probe failed.");

  my $retval = mtp_get_first_device();

  return $retval;
}

sub _release_device {
  my ($class, $handle) = @_;

  if ($handle) {
    mtp_release_device($handle);
  }

  return 1;
}

sub _dump_device_info {
  my ($class, $handle) = @_;
  my $i_connected = 0;

  if (!$handle) {
    $handle = $class->_get_first_device();
    $i_connected = 1;
  }
  mtp_dump_device_info($handle);
  if ($i_connected) {
    $class->_release_device($handle);
  }

  return 1;
}

1;

__DATA__

__C__
// */
#include <libmtp.h>
#include <stdio.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <errno.h>

// I think this may not be a win32-friendly header... dunnno.  Don't care right now.
#include <libgen.h>

#define SV_STRING(VALUE)                    newSVpv(VALUE,strlen(VALUE))
#define SV_UINT(VALUE)                      newSVuv(VALUE)
#define SV_INT(VALUE)                       newSViv(VALUE)
#define SV_DECIMAL(VALUE)                   newSVnv(VALUE)
#define SV_UNDEF                            &PL_sv_undef

#define HASH_STORE_UINT(HASH,KEY,VALUE)     hv_store(HASH,KEY,strlen(KEY),SV_UINT(VALUE),0)
#define HASH_STORE_INT(HASH,KEY,VALUE)      hv_store(HASH,KEY,strlen(KEY),SV_INT(VALUE),0)
#define HASH_STORE_DECIMAL(HASH,KEY,VALUE)  hv_store(HASH,KEY,strlen(KEY),SV_DECIMAL(VALUE),0)
#define HASH_STORE_STRING(HASH,KEY,VALUE)   hv_store(HASH,KEY,strlen(KEY),SV_STRING(VALUE),0)
#define HASH_STORE_SV(HASH,KEY,VALUE)       hv_store(HASH,KEY,strlen(KEY),VALUE,0)
#define HASH_FETCH_SCALAR(HASH,KEY)         hv_fetch(HASH,KEY,strlen(KEY),0)

#define PUSH(ARY,SV)                        av_push(ARY,SV)
#define SHIFT(ARY)                          av_shift(ARY)

#define HASHREF(HASH)                       newRV_noinc((SV*)HASH)
#define ARRAYREF(ARY)                       newRV_noinc((SV*)ARY)
#define DR_HASHREF(SCALAR)                  (HV*)SvRV(SCALAR)

#define MTP_DEVICE(HASHREF)                 mtp_device_from_hashref(HASHREF, "__handle")
#define MTP_OWNING_DEVICE(HASHREF)          mtp_device_from_hashref(HASHREF, "__device")
#define MTP_FILE(HASHREF)                   mtp_file_from_hashref(HASHREF)
#define MTP_FOLDER(HASHREF)                 mtp_folder_from_hashref(HASHREF)
#define MTP_TRACK(HASHREF)                  mtp_track_from_hashref(HASHREF)
#define MTP_PLAYLIST(HASHREF)               mtp_playlist_from_hashref(HASHREF)

#define SET_ERRMSG(ERRMSG)		    SV* __errmsg = get_sv("Device::MTP::ERRMSG", TRUE);sv_setpv(__errmsg, ERRMSG);SvPOK_on(__errmsg)

#define HERE(ID)                            fprintf(stdout,"%d: HERE!!!\n",ID)
//#define HERE(ID)                            /*ID*/

/* Below are my "lazy bastage" inline functions.  They're for my convenience. */
inline char* hv_strcpy(char** dest, HV* hash, const char* key) {
  SV** ptr = HASH_FETCH_SCALAR(hash, key);
  STRLEN plen;
  char* check = (char*) SvPV(*ptr, plen);
  if (plen > 0) {
    *dest = strdup(check);
  } else {
    *dest = "\0";
  }

  return *dest;
}

inline int hv_intcpy(int* dest, HV* hash, const char* key) {
  SV** ptr = HASH_FETCH_SCALAR(hash, key);
  if (!ptr || !*ptr || *ptr == SV_UNDEF) {
    return 0;
  }

  *dest = SvIV(*ptr);

  return *dest;
}

inline uint16_t hv_uint16cpy(uint16_t* dest, HV* hash, const char* key) {
  SV** ptr = HASH_FETCH_SCALAR(hash, key);
  if (!ptr || !*ptr || *ptr == SV_UNDEF) {
    return 0;
  }

  *dest = SvUV(*ptr);

  return *dest;
}

inline uint32_t hv_uint32cpy(uint32_t* dest, HV* hash, const char* key) {
  SV** ptr = HASH_FETCH_SCALAR(hash, key);
  if (!ptr || !*ptr || *ptr == SV_UNDEF) {
    return 0;
  }

  *dest = SvUV(*ptr);

  return *dest;
}

inline uint64_t hv_uint64cpy(uint64_t* dest, HV* hash, const char* key) {
  SV** ptr = HASH_FETCH_SCALAR(hash, key);
  if (!ptr || !*ptr || *ptr == SV_UNDEF) {
    return 0;
  }

  *dest = SvUV(*ptr);

  return *dest;
}
/* END BASTAGE ROUTINES */

/* Perl-to-C routines */
SV* mtp_make_device_entry_hashref(LIBMTP_device_entry_t* entry);
SV* mtp_make_device_hashref(LIBMTP_mtpdevice_t* entry);
SV* mtp_make_file_hashref(LIBMTP_file_t* file, LIBMTP_mtpdevice_t* device);
SV* mtp_make_folder_hashref(LIBMTP_folder_t* folder, LIBMTP_mtpdevice_t* device);
SV* mtp_make_track_hashref(LIBMTP_track_t* track, LIBMTP_mtpdevice_t* device);
SV* mtp_make_playlist_hashref(LIBMTP_playlist_t* pl, LIBMTP_mtpdevice_t* device);
LIBMTP_mtpdevice_t* mtp_device_from_hashref(SV* hashref, const char* key);
LIBMTP_file_t* mtp_file_from_hashref(SV* hashref);
LIBMTP_folder_t* mtp_folder_from_hashref(SV* hashref);
LIBMTP_track_t* mtp_track_from_hashref(SV* hashref);
LIBMTP_playlist_t* mtp_playlist_from_hashref(SV* hashref);

/* type constructor routines */
LIBMTP_file_t* mtp_construct_file_from_hashref(LIBMTP_file_t** dest, SV* src);
LIBMTP_folder_t* mtp_construct_folder_from_hashref(LIBMTP_folder_t** dest, SV* src);
LIBMTP_track_t* mtp_construct_track_from_hashref(LIBMTP_track_t** dest, SV* src);

/* Traffic-generating routines */
void mtp_init(void);
SV* mtp_probe(void);
SV* mtp_get_first_device(void);
void mtp_release_device(SV* device);
void mtp_dump_device_info(SV* device);
char* mtp_get_model_name(SV* device);
char* mtp_get_serial_number(SV* device);
char* mtp_get_device_version(SV* device);
char* mtp_get_device_name(SV* device);
SV* mtp_get_storage_info(SV* device);
SV* mtp_get_battery_level(SV* device);
SV* mtp_get_secure_time(SV* device);
SV* mtp_get_device_certificate(SV* device);
AV* mtp_get_supported_file_types(SV* device);
AV* mtp_get_file_listing(SV* device);
SV* mtp_get_folder_from_file(SV* base);
SV* mtp_get_parent_folder(SV* base);
SV* mtp_get_folder_by_id(SV* device, SV* sv_id);
AV* mtp_get_files_by_folder(SV* in_folder);
void mtp_scan_folders_recursively(AV** dest, LIBMTP_folder_t* start, LIBMTP_mtpdevice_t* device, LIBMTP_file_t* file_list);
void mtp_scan_folder(AV** dest, LIBMTP_folder_t* parent, LIBMTP_mtpdevice_t* device, LIBMTP_file_t* list);
LIBMTP_filetype_t mtp_grab_filetype_from_extension(const char* fname);
LIBMTP_file_t* mtp_grab_file_info(LIBMTP_file_t** f, const char* fname);
int mtp_call_progress_callback(uint64_t const sent, uint64_t const total, void const * const data);

/* Post routines */
int mtp_post_file(SV* in_device, SV* sv_fname, SV* sv_folder, SV* callback);

/* Grab routines */

char errmsg[BUFSIZ] = "\0";

SV* mtp_make_device_entry_hashref(LIBMTP_device_entry_t* entry) {
  HV* hash = newHV();

  HASH_STORE_STRING(hash, "name", entry->name);
  HASH_STORE_UINT(hash, "vendor_id", entry->vendor_id);
  HASH_STORE_UINT(hash, "product_id", entry->product_id);

  return HASHREF(hash);
}

SV* mtp_make_device_hashref(LIBMTP_mtpdevice_t* entry) {
  HV* hash = newHV();

  HASH_STORE_INT(hash, "__handle", PTR2IV(entry));
  HASH_STORE_UINT(hash, "interface_number", entry->interface_number);
  HASH_STORE_INT(hash, "__params", PTR2IV(entry->params));
  HASH_STORE_INT(hash, "__usbinfo", PTR2IV(entry->usbinfo));
  HASH_STORE_UINT(hash, "storage_id", entry->storage_id);
  HASH_STORE_UINT(hash, "maxiumum_battery_level", entry->maximum_battery_level);
  HASH_STORE_UINT(hash, "default_music_folder", entry->default_music_folder);
  HASH_STORE_UINT(hash, "default_playlist_folder", entry->default_playlist_folder);
  HASH_STORE_UINT(hash, "default_picture_folder", entry->default_picture_folder);
  HASH_STORE_UINT(hash, "default_video_folder", entry->default_video_folder);
  HASH_STORE_UINT(hash, "default_organizer_folder", entry->default_organizer_folder);
  HASH_STORE_UINT(hash, "default_zencast_folder", entry->default_zencast_folder);

  return HASHREF(hash);
}

SV* mtp_make_file_hashref(LIBMTP_file_t* file, LIBMTP_mtpdevice_t* device) {
  HV* hash = newHV();

  HASH_STORE_INT(hash, "__handle", PTR2IV(file));
  HASH_STORE_INT(hash, "__device", PTR2IV(device));
  HASH_STORE_UINT(hash, "item_id", file->item_id);
  HASH_STORE_UINT(hash, "parent_id", file->parent_id);
  HASH_STORE_STRING(hash, "filename", file->filename);
  HASH_STORE_UINT(hash, "filesize", file->filesize);
  HASH_STORE_INT(hash, "filetype", file->filetype);
  HASH_STORE_STRING(hash, "filetype_name", LIBMTP_Get_Filetype_Description(file->filetype));

  return HASHREF(hash);
}

SV* mtp_make_folder_hashref(LIBMTP_folder_t* folder, LIBMTP_mtpdevice_t* device) {
  HV* hash = newHV();

  HASH_STORE_INT(hash, "__handle", PTR2IV(folder));
  HASH_STORE_INT(hash, "__device", PTR2IV(device));
  HASH_STORE_UINT(hash, "folder_id", folder->folder_id);
  HASH_STORE_UINT(hash, "parent_id", folder->parent_id);
  HASH_STORE_STRING(hash, "name", folder->name);

  return HASHREF(hash);
}

SV* mtp_make_track_hashref(LIBMTP_track_t* track, LIBMTP_mtpdevice_t* device) {
  HV* hash = newHV();

  HASH_STORE_INT(hash, "__handle", PTR2IV(track));
  HASH_STORE_INT(hash, "__device", PTR2IV(device));
  HASH_STORE_UINT(hash, "item_id", track->item_id);
  HASH_STORE_STRING(hash, "title", track->title);
  HASH_STORE_STRING(hash, "artist", track->artist);
  HASH_STORE_STRING(hash, "genre", track->genre);
  HASH_STORE_STRING(hash, "album", track->album);
  HASH_STORE_STRING(hash, "date", track->date);
  HASH_STORE_STRING(hash, "filename", track->filename);
  HASH_STORE_UINT(hash, "tracknummber", track->tracknumber);
  HASH_STORE_UINT(hash, "duration", track->duration);
  HASH_STORE_UINT(hash, "samplerate", track->samplerate);
  HASH_STORE_UINT(hash, "nochannels", track->nochannels);
  HASH_STORE_UINT(hash, "wavecodec", track->wavecodec);
  HASH_STORE_UINT(hash, "bitrate", track->bitrate);
  HASH_STORE_UINT(hash, "bitratetype", track->bitratetype);
  HASH_STORE_UINT(hash, "rating", track->rating);
  HASH_STORE_UINT(hash, "usecount", track->usecount);
  HASH_STORE_UINT(hash, "filesize", track->filesize);
  HASH_STORE_INT(hash, "filetype", track->filetype);
  HASH_STORE_STRING(hash, "filetype_name", LIBMTP_Get_Filetype_Description(track->filetype));

  return HASHREF(hash);
}

SV* mtp_make_playlist_hashref(LIBMTP_playlist_t* pl, LIBMTP_mtpdevice_t* device) {
  HV* hash = newHV();

  HASH_STORE_INT(hash, "__handle", PTR2IV(pl));
  HASH_STORE_INT(hash, "__device", PTR2IV(device));
  HASH_STORE_UINT(hash, "playlist_id", pl->playlist_id);
  HASH_STORE_STRING(hash, "name", pl->name);
  HASH_STORE_UINT(hash, "no_tracks", pl->no_tracks);

  return HASHREF(hash);
}

LIBMTP_mtpdevice_t* mtp_device_from_hashref(SV* hashref, const char* key) {
  HV* hash = DR_HASHREF(hashref); /* Grab our hash */
  LIBMTP_mtpdevice_t * mtph = (LIBMTP_mtpdevice_t*)NULL;
  SV** ptr = (SV**)NULL;

  /* Grab the handle */
  ptr = HASH_FETCH_SCALAR(hash, key);
  mtph = INT2PTR(LIBMTP_mtpdevice_t*, SvIV(*ptr));

  return mtph;
}

LIBMTP_file_t* mtp_file_from_hashref(SV* hashref) {
  HV* hash = DR_HASHREF(hashref);
  LIBMTP_file_t* file = (LIBMTP_file_t*)NULL;
  SV** ptr = (SV**)NULL;

  ptr = HASH_FETCH_SCALAR(hash, "__handle");
  file = INT2PTR(LIBMTP_file_t*, SvIV(*ptr));

  return file;
}

LIBMTP_folder_t* mtp_folder_from_hashref(SV* hashref) {
  HV* hash = DR_HASHREF(hashref);
  LIBMTP_folder_t* folder = (LIBMTP_folder_t*)NULL;
  SV** ptr = (SV**)NULL;

  ptr = HASH_FETCH_SCALAR(hash, "__handle");
  folder = INT2PTR(LIBMTP_folder_t*, SvIV(*ptr));

  return folder;
}

LIBMTP_track_t* mtp_track_from_hashref(SV* hashref) {
  HV* hash = DR_HASHREF(hashref);
  LIBMTP_track_t* track = (LIBMTP_track_t*)NULL;
  SV** ptr = (SV**)NULL;

  ptr = HASH_FETCH_SCALAR(hash, "__handle");
  track = INT2PTR(LIBMTP_track_t*, SvIV(*ptr));

  return track;
}

LIBMTP_playlist_t* mtp_playlist_from_hashref(SV* hashref) {
  HV* hash = DR_HASHREF(hashref);
  LIBMTP_playlist_t* playlist = (LIBMTP_playlist_t*)NULL;
  SV** ptr = (SV**)NULL;

  ptr = HASH_FETCH_SCALAR(hash, "__handle");
  playlist = INT2PTR(LIBMTP_playlist_t*, SvIV(*ptr));

  return playlist;
}

LIBMTP_file_t* mtp_construct_file_from_hashref(LIBMTP_file_t** dest, SV* src) {
  HV* hash = DR_HASHREF(src);

  if (dest == NULL || *dest == NULL) {
    /* Maybe make a new one if it doesn't exist? */
    return NULL;
  }

  hv_uint32cpy(&((*dest)->item_id), hash, "item_id");
  hv_uint32cpy(&((*dest)->parent_id), hash, "parent_id");
  hv_strcpy(&((*dest)->filename), hash, "filename");
  hv_uint64cpy(&((*dest)->filesize), hash, "filesize");
  hv_intcpy((int*) &((*dest)->filetype), hash, "filetype");

  return *dest;
}

LIBMTP_folder_t* mtp_construct_folder_from_hashref(LIBMTP_folder_t** dest, SV* src) {
  HV* hash = DR_HASHREF(src);

  if (dest == NULL || *dest == NULL) {
    /* Maybe make a new one if it doesn't exist? */
    return NULL;
  }

  hv_uint32cpy(&((*dest)->folder_id), hash, "folder_id");
  hv_uint32cpy(&((*dest)->parent_id), hash, "parent_id");
  hv_strcpy(&((*dest)->name), hash, "name");

  return *dest;
}

LIBMTP_track_t* mtp_construct_track_from_hashref(LIBMTP_track_t** dest, SV* src) {
  HV* hash = DR_HASHREF(src);

  if (dest == NULL || *dest == NULL) {
    /* Maybe make a new one if it doesn't exist? */
    return NULL;
  }

  hv_uint32cpy(&((*dest)->item_id), hash, "item_id");
  hv_strcpy(&((*dest)->title), hash, "title");
  hv_strcpy(&((*dest)->artist), hash, "artist");
  hv_strcpy(&((*dest)->genre), hash, "genre");
  hv_strcpy(&((*dest)->album), hash, "album");
  hv_strcpy(&((*dest)->date), hash, "date");
  hv_strcpy(&((*dest)->filename), hash, "filename");
  hv_uint16cpy(&((*dest)->tracknumber), hash, "tracknumber");
  hv_uint32cpy(&((*dest)->duration), hash, "duration");
  hv_uint32cpy(&((*dest)->samplerate), hash, "samplerate");
  hv_uint16cpy(&((*dest)->nochannels), hash, "nochannels");
  hv_uint32cpy(&((*dest)->wavecodec), hash, "wavecodec");
  hv_uint32cpy(&((*dest)->bitrate), hash, "bitrate");
  hv_uint16cpy(&((*dest)->bitratetype), hash, "bitratetype");
  hv_uint16cpy(&((*dest)->rating), hash, "rating");
  hv_uint32cpy(&((*dest)->usecount), hash, "usecount");
  hv_uint64cpy(&((*dest)->filesize), hash, "filesize");
  hv_intcpy((int*) &((*dest)->filetype), hash, "filetype");

  return *dest;
}

/* IN CAR!!!  DOUBLECHECK!!! */
LIBMTP_playlist_t* mtp_construct_playlist_from_hashref(LIBMTP_playlist_t** dest, SV* src) {
  HV* hash = DR_HASHREF(src);

  if (dest == NULL || *dest == NULL) {
    /* Maybe make a new one?  Dunno. */
    return NULL;
  }

  hv_uint32cpy(&((*dest)->playlist_id), hash, "playlist_id");
  hv_strcpy(&((*dest)->name), hash, "name");
  hv_uint32cpy(&((*dest)->no_tracks), hash, "no_tracks");

  /* Can we copy the tracks? */

  return *dest;
}

/* */
void mtp_init() {
  LIBMTP_Init();

  return;
}

SV* mtp_probe() {
  HV* descriptor = newHV();

  uint16_t vendor = 0;
  uint16_t product = 0;
  int retval = 0;

  retval = LIBMTP_Detect_Descriptor(&vendor, &product);
  if (retval > 0) {
    HASH_STORE_UINT(descriptor, "vendor_id", vendor);
    HASH_STORE_UINT(descriptor, "product_id", product);
  } else {
    return SV_UNDEF;
  }

  return HASHREF(descriptor);
}

SV* mtp_get_first_device() {
  LIBMTP_mtpdevice_t* mtph = (LIBMTP_mtpdevice_t*)NULL;

  mtph = LIBMTP_Get_First_Device();
  if (mtph != NULL) {
    return mtp_make_device_hashref(mtph);
  } else {
    return SV_UNDEF;
  }
}

void mtp_release_device(SV* device) {
  /* Call lib's release function */
  LIBMTP_Release_Device(MTP_DEVICE(device));

  return;
}

void mtp_dump_device_info(SV* device) {
  LIBMTP_Dump_Device_Info(MTP_DEVICE(device));
}

char* mtp_get_model_name(SV* device) {
  return LIBMTP_Get_Modelname(MTP_DEVICE(device));
}

char* mtp_get_serial_number(SV* device) {
  return LIBMTP_Get_Serialnumber(MTP_DEVICE(device));
}

char* mtp_get_device_version(SV* device) {
  return LIBMTP_Get_Deviceversion(MTP_DEVICE(device));
}

char* mtp_get_device_name(SV* device) {
  return LIBMTP_Get_Friendlyname(MTP_DEVICE(device));
}

SV* mtp_get_storage_info(SV* device) {
  HV* info = newHV();
  uint64_t total_bytes = 0;
  uint64_t free_bytes = 0;
  char* storage_description;
  char* volume_label;
  int retval = 0;

  retval = LIBMTP_Get_Storageinfo(MTP_DEVICE(device), &total_bytes,
				  &free_bytes, &storage_description,
				  &volume_label);

  if (retval) {
    return SV_UNDEF;
  }

  HASH_STORE_UINT(info, "total_bytes", total_bytes);
  HASH_STORE_UINT(info, "free_bytes", free_bytes);
  HASH_STORE_STRING(info, "storage_description", storage_description);
  HASH_STORE_STRING(info, "volume_label", volume_label);

  return HASHREF(info);
}

SV* mtp_get_battery_level(SV* device) {
  HV* info = newHV();
  uint8_t maxlevel = 0;
  uint8_t currlevel = 0;
  float percent = 0.00;
  int retval = 0;

  retval = LIBMTP_Get_Batterylevel(MTP_DEVICE(device), &maxlevel, &currlevel);

  if (retval) {
    return SV_UNDEF;
  }

  percent = ((float)currlevel/(float)maxlevel)*100;
  HASH_STORE_UINT(info,"max_level",maxlevel);
  HASH_STORE_UINT(info,"current_level",currlevel);
  HASH_STORE_DECIMAL(info,"percent",percent);

  return HASHREF(info);
}

SV* mtp_get_secure_time(SV* device) {
  char* to_return;

  if (!LIBMTP_Get_Secure_Time(MTP_DEVICE(device), &to_return)) {
    return SV_STRING(to_return);
    // Needs "free" somewhere?
  }

  return SV_UNDEF;
}

SV* mtp_get_device_certificate(SV* device) {
  char* to_return;

  if (!LIBMTP_Get_Device_Certificate(MTP_DEVICE(device), &to_return)) {
    return SV_STRING(to_return);
    // Needs "free" somewhere?
  }

  return SV_UNDEF;
}

AV* mtp_get_supported_file_types(SV* device) {
  AV* ftype_ary = newAV();
  uint16_t* ftypes = 0;
  uint16_t ftypes_len = 0;
  uint16_t i = 0;

  if (LIBMTP_Get_Supported_Filetypes(MTP_DEVICE(device), &ftypes, &ftypes_len)) {
    return ftype_ary;
  }

  for (i = 0; i < ftypes_len; i++) {
    PUSH(ftype_ary, SV_STRING(LIBMTP_Get_Filetype_Description(ftypes[i])));
  }

  return ftype_ary;
}

AV* mtp_get_file_listing(SV* device) {
  AV* f_ary = newAV();
  LIBMTP_file_t* files;
  LIBMTP_file_t* one;
  LIBMTP_file_t* tmp;

  files = LIBMTP_Get_Filelisting(MTP_DEVICE(device));
  if (files == NULL) {
    return f_ary;
  }

  one = files;
  while (one != NULL) {
    tmp = one;
    PUSH(f_ary, mtp_make_file_hashref(one, MTP_DEVICE(device)));
    one = one->next;
  }

  return f_ary;
}

SV* mtp_get_folder_from_file(SV* base) {
  LIBMTP_folder_t* folder = (LIBMTP_folder_t*)NULL;
  LIBMTP_file_t* file = MTP_FILE(base);
  LIBMTP_mtpdevice_t* device = MTP_OWNING_DEVICE(base);

  if (!device) {
    fprintf(stderr, "ACK!  No device!\n");
    return SV_UNDEF;
  } else if (!file) {
    fprintf(stderr, "ACK!  No file!\n");
    return SV_UNDEF;
  }

  if (file->parent_id) {
    folder = LIBMTP_Find_Folder(LIBMTP_Get_Folder_List(device), file->parent_id);
  } else {
    return SV_UNDEF;
  }

  return mtp_make_folder_hashref(folder,device);
}

SV* mtp_get_parent_folder(SV* base) {
  LIBMTP_folder_t* folder = MTP_FOLDER(base);
  LIBMTP_folder_t* parent_folder = (LIBMTP_folder_t*)NULL;
  LIBMTP_mtpdevice_t* device = MTP_OWNING_DEVICE(base);

  if (!device) {
    fprintf(stderr, "ACK!  No device!\n");
    return SV_UNDEF;
  } else if (!folder) {
    fprintf(stderr, "ACK!  No folder!\n");
    return SV_UNDEF;
  }

  if (folder->parent_id) {
    parent_folder = LIBMTP_Find_Folder(LIBMTP_Get_Folder_List(device), folder->parent_id);
  } else {
    return SV_UNDEF;
  }

  return mtp_make_folder_hashref(parent_folder,device);
}

SV* mtp_get_folder_by_id(SV* device, SV* sv_id) {
  LIBMTP_folder_t* folder = (LIBMTP_folder_t*)NULL;
  uint32_t id = SvUV(sv_id);

  if (id) {
    return mtp_make_folder_hashref(LIBMTP_Find_Folder(LIBMTP_Get_Folder_List(MTP_DEVICE(device)), id), MTP_DEVICE(device));
  }

  return SV_UNDEF;
}

AV* mtp_get_files_by_folder(SV* in_folder) {
  LIBMTP_folder_t* folder = MTP_FOLDER(in_folder);
  LIBMTP_mtpdevice_t* device = MTP_OWNING_DEVICE(in_folder);
  LIBMTP_file_t* files = (LIBMTP_file_t*)NULL;

  AV* f_ary = newAV();

  LIBMTP_file_t* t_file = (LIBMTP_file_t*)NULL;

  files = LIBMTP_Get_Filelisting(device);
  if (files == NULL) {
    return f_ary;
  }

  mtp_scan_folders_recursively(&f_ary, folder, device, files);

  return f_ary;
}

void mtp_scan_folders_recursively(AV** dest, LIBMTP_folder_t* start, LIBMTP_mtpdevice_t* device, LIBMTP_file_t* file_list) {
  LIBMTP_folder_t* one = (LIBMTP_folder_t*)NULL;

  if (start == NULL) {
    return;
  }

  /* Scan myself */
  mtp_scan_folder(dest, start, device, file_list);

  /* Check siblings */
  one = start->sibling;
  while (one != NULL) {
    /* Scan sibling */
    mtp_scan_folder(dest, start, device, file_list);

    /* Get children */
    if (one->child != NULL) {
      mtp_scan_folders_recursively(dest, start, device, file_list);
    }

    one = one->sibling;
  }

  return;
}

void mtp_scan_folder(AV** dest, LIBMTP_folder_t* parent, LIBMTP_mtpdevice_t* device, LIBMTP_file_t* list) {
  LIBMTP_file_t* one = (LIBMTP_file_t*)NULL;
  LIBMTP_file_t* tmp = (LIBMTP_file_t*)NULL;

  if (list == NULL) {
    return;
  }

  one = list;
  while (one != NULL) {
    tmp = one;
    one = one->next;
    if (tmp->parent_id == parent->folder_id) {
      PUSH(*dest, mtp_make_file_hashref(tmp, device));
    }
  }

  return;
}

LIBMTP_filetype_t mtp_grab_filetype_from_extension(const char* filename) {
  char* end = (char*)NULL;
  char* dot = (char*)NULL;
  //  char* filename = strdup(fname);
  char ext[10] = "";
  int count = 9;

  if (filename == NULL) {
    return LIBMTP_FILETYPE_UNKNOWN;
  }
  fprintf(stderr, "%d: file name '%s'\n", __LINE__, filename);

  HERE(__LINE__);

  /* Yeah, I know this isn't the best way to do this, but I can't think of anything
     more clever yet.  Perhaps later? */
  end = filename;
  fprintf(stderr, "%d: END: file name '%s'\n", __LINE__, end);
  HERE(__LINE__);
  while (*end != '\0') {
    //    fprintf(stderr, "%d: %c\n", __LINE__, *end);
    end++;
  }
  HERE(__LINE__);

  dot = end;
  HERE(__LINE__);
  while (*(dot-sizeof(char)) != '.') {
    if (--count > 0) {
      dot--;
    } else {
      HERE(__LINE__);
      //      free(filename);
      return LIBMTP_FILETYPE_UNKNOWN;
    }
  }
  HERE(__LINE__);

  if (strlen(dot) < 10) {
    strcpy(ext, dot);
  } else {
    HERE(__LINE__);
    //    free(filename);
    return LIBMTP_FILETYPE_UNKNOWN;
  }
  HERE(__LINE__);
  //  free(filename);
  HERE(__LINE__);

  fprintf(stderr, "The file extension is '%s'\n", ext);

  /* Now for the ugly elsif... */
  if (!strcasecmp(ext,"wav")) {
    return LIBMTP_FILETYPE_WAV;
  } else if (!strcasecmp(ext,"mp3")) {
    return LIBMTP_FILETYPE_MP3;
  } else if (!strcasecmp(ext,"wma")) {
    return LIBMTP_FILETYPE_WMA;
  } else if (!strcasecmp(ext,"ogg")) {
    return LIBMTP_FILETYPE_OGG;
  } else if (!strcasecmp(ext,"mp4")) {
    return LIBMTP_FILETYPE_MP4;
  } else if (!strcasecmp(ext,"wmv")) {
    return LIBMTP_FILETYPE_WMV;
  } else if (!strcasecmp(ext,"avi")) {
    return LIBMTP_FILETYPE_AVI;
  } else if (!strcasecmp(ext,"mpeg") || !strcasecmp(ext,"mpg")) {
    return LIBMTP_FILETYPE_MPEG;
  } else if (!strcasecmp(ext,"asf")) {
    return LIBMTP_FILETYPE_ASF;
  } else if (!strcasecmp(ext,"qt") || !strcasecmp(ext,"mov")) {
    return LIBMTP_FILETYPE_QT;
  } else if (!strcasecmp(ext,"wma")) {
    return LIBMTP_FILETYPE_WMA;
  } else if (!strcasecmp(ext,"jpg") || !strcasecmp(ext,"jpeg")) {
    return LIBMTP_FILETYPE_JPEG;
  } else if (!strcasecmp(ext,"jfif")) {
    return LIBMTP_FILETYPE_JFIF;
  } else if (!strcasecmp(ext,"tif") || !strcasecmp(ext,"tiff")) {
    return LIBMTP_FILETYPE_TIFF;
  } else if (!strcasecmp(ext,"bmp")) {
    return LIBMTP_FILETYPE_BMP;
  } else if (!strcasecmp(ext,"gif")) {
    return LIBMTP_FILETYPE_GIF;
  } else if (!strcasecmp(ext,"pic") || !strcasecmp(ext,"pict")) {
    return LIBMTP_FILETYPE_PICT;
  } else if (!strcasecmp(ext,"png")) {
    return LIBMTP_FILETYPE_PNG;
  } else if (!strcasecmp(ext,"wmf")) {
    return LIBMTP_FILETYPE_WINDOWSIMAGEFORMAT;
  } else if (!strcasecmp(ext,"ics")) {
    return LIBMTP_FILETYPE_VCALENDAR2;
  } else if (!strcasecmp(ext,"exe") || !strcasecmp(ext,"com") || 
	     !strcasecmp(ext,"bat") || !strcasecmp(ext,"dll") || 
	     !strcasecmp(ext,"sys")) {
    return LIBMTP_FILETYPE_WINEXEC;
  } else {
    fprintf(stderr, "File type \"%s\" is not yet supported\n", ext);
    return LIBMTP_FILETYPE_UNKNOWN;
  }

  return LIBMTP_FILETYPE_UNKNOWN;
}

int mtp_call_progress_callback(uint64_t const sent, uint64_t const total,
				       void const * const data) {
  fprintf(stderr, "mtp_call_progress_callback!!!!\n");
  HERE(__LINE__);
  SV* callback = (SV*)data;
  if (callback == NULL || callback == SV_UNDEF) {
    fprintf(stderr, "No callback defined.\n");
    return 0;
  }

  dSP;
  ENTER;
  SAVETMPS;

  PUSHMARK(SP);
  XPUSHs(sv_2mortal(newSVuv(sent)));
  XPUSHs(sv_2mortal(newSVuv(total)));
  PUTBACK;

  /* TODO: Get this taking a return value from Perl.  Nonzero returns should
     be returned to libmtp to cancel the transfer. */
  call_sv(callback, G_DISCARD);

  FREETMPS;
  LEAVE;

  return 0;
}

LIBMTP_file_t* mtp_grab_file_info(LIBMTP_file_t** f, const char* fname) {
  struct stat64 sb;
  uint64_t fsize = 0;
  char* stripped_fname = (char*)NULL;
  char* in_fname = (char*)NULL;

  HERE(__LINE__);
  if (!f || !fname) {
    HERE(__LINE__);
    sprintf(errmsg, "Got null file object or file name.\n");
    HERE(__LINE__);
    SET_ERRMSG(errmsg);
    HERE(__LINE__);
    return NULL;
  } else {
    fprintf(stderr, "File name '%s'\n", fname);
  }

  HERE(__LINE__);
  in_fname = strdup(fname);
  fprintf(stderr, "Duplicated file name '%s'\n", in_fname);
  HERE(__LINE__);
  if (!in_fname) {
    HERE(__LINE__);
    sprintf(errmsg, "Out of memory?!");
    SET_ERRMSG(errmsg);
    return NULL;
  }
  HERE(__LINE__);

  stripped_fname = basename(in_fname);
  fprintf(stderr, "%d: Duplicated file name '%s'\n", __LINE__, in_fname);
  HERE(__LINE__);
  if (stripped_fname == NULL) {
    sprintf(errmsg, "Couldn't basename '%s'.\n", in_fname);
    SET_ERRMSG(errmsg);
    free(in_fname);
    return NULL;
  }
  HERE(__LINE__);
  fprintf(stderr, "%d: Duplicated file name '%s'\n", __LINE__, in_fname);

  if (stat64(in_fname, &sb) == -1) {
    HERE(__LINE__);
    sprintf(errmsg, "%s: ", in_fname, strerror(errno));
    SET_ERRMSG(errmsg);
    free(in_fname);
    return NULL;
  }
  HERE(__LINE__);
  fprintf(stderr, "%d: Stripped file name '%s'\n", __LINE__, stripped_fname);

  (*f)->filesize = (uint64_t)sb.st_size;
  HERE(__LINE__);
  (*f)->filename = strdup(stripped_fname);
  HERE(__LINE__);
  (*f)->filetype = mtp_grab_filetype_from_extension(stripped_fname);
  HERE(__LINE__);
  fprintf(stderr, "%d: Duplicated file name '%s'\n", __LINE__, in_fname);

  //  free(in_fname);
  HERE(__LINE__);

  return *f;
}

int mtp_post_file(SV* in_device, SV* sv_fname, SV* sv_folder, SV* callback) {
  HERE(__LINE__);
  int retval = 0;
  LIBMTP_mtpdevice_t* device = MTP_DEVICE(in_device);
  LIBMTP_file_t* file = LIBMTP_new_file_t();
  void* cb_ptr = (void*)NULL;
  STRLEN sv_len;
  char* fname = SvPV(sv_fname, sv_len);
  fname[sv_len] = '\0';
  uint32_t folder = SvUV(sv_folder);

  /* Construct the file struct */
  if (!mtp_grab_file_info(&file, fname)) {
    sprintf(errmsg, "Failed to get file info: %s", strerror(errno));
    SET_ERRMSG(errmsg);
    LIBMTP_destroy_file_t(file);
    return 0;
  }

  if (callback != SV_UNDEF) {
    cb_ptr = (void*)callback;
  }

  printf("type ID is '%d'\nFolder is %d\n", file->filetype, folder);
  printf("Description is '%s'\n", LIBMTP_Get_Filetype_Description(file->filetype));

  HERE(__LINE__);
  retval = LIBMTP_Send_File_From_File(device, fname, file, mtp_call_progress_callback, cb_ptr, folder);
  if (retval) {
    fprintf(stderr, "I got %d back from the sender.... I think that means I failed.\n", retval);
  } else {
    fprintf(stderr, "I got %d back from the sender.... I think that means it succeeded.\n", retval);
  }
  HERE(__LINE__);  HERE(__LINE__);


  LIBMTP_destroy_file_t(file);

  return 1;
}
