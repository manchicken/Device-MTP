package Device::MTP::Handle;

# Stolen from Device::USB::Device.  He had to make oodles of accessors, and boy, so do I.
sub _parm
{
    my $name = shift;

    return eval qq{sub $name
        {
            my \$self = shift;
            return \$self->{descriptor}->{$name};
        }
    };
}

_parm('interface_number');
_parm('params');
_parm('usbinfo');
_parm('storage_id');
_parm('maximum_battery_level');
_parm('default_music_folder');
_parm('default_playlist_folder');
_parm('default_picture_folder');
_parm('default_video_folder
