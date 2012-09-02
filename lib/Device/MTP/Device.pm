package Device::MTP::Device;
use Device::MTP;
use Device::MTP::File;
use Device::MTP::Folder;

sub new {
  my ($class, %opts) = @_;

  my $self = {map { $_ => $opts{$_} } keys(%opts)};

  bless ($self, $class);

  $self->{handle} ||= undef;

  return $self;
}

sub DESTROY {
  my ($self) = @_;

  if ($self && $self->{handle}) {
    $self->release();
  }

  return;
}

sub from_handle {
  my ($class, %opts) = @_;

  if (!$opts{handle}) {
    die("No handle passed to ".__PACKAGE__."::from_handle.");
  }

  return $class->new(%opts);
}

sub release {
  my ($self) = @_;

  if ($self->{handle}) {
    Device::MTP->_release_device($self->{handle});
    $self->{handle} = undef;
    return 1;
  } else {
    return undef;
  }
}

sub model_name {
  my ($self) = @_;

  if ($self->{handle}) {
    return Device::MTP::mtp_get_model_name($self->{handle});
  }

  return undef;
}

sub serial_number {
  my ($self) = @_;

  if ($self->{handle}) {
    return Device::MTP::mtp_get_serial_number($self->{handle});
  }

  return undef;
}

sub version {
  my ($self) = @_;

  if ($self->{handle}) {
    return Device::MTP::mtp_get_device_version($self->{handle});
  }

  return undef;
}

sub device_name {
  my ($self) = @_;

  if ($self->{handle}) {
    return Device::MTP::mtp_get_device_name($self->{handle});
  }

  return undef;
}

sub storage_info {
  my ($self) = @_;

  if ($self->{handle}) {
    return Device::MTP::mtp_get_storage_info($self->{handle});
  }

  return undef;
}

sub battery_level {
  my ($self) = @_;

  if ($self->{handle}) {
    return Device::MTP::mtp_get_battery_level($self->{handle});
  }

  return undef;
}

sub secure_time {
  my ($self) = @_;

  if ($self->{handle}) {
    return Device::MTP::mtp_get_secure_time($self->{handle});
  }

  return undef;
}

sub certificate {
  my ($self) = @_;

  if ($self->{handle}) {
    return Device::MTP::mtp_get_device_certificate($self->{handle});
  }

  return undef;
}

sub supported_file_types {
  my ($self) = @_;

  if ($self->{handle}) {
    return Device::MTP::mtp_get_supported_file_types($self->{handle});
  }

  return ();
}

sub files {
  my ($self) = @_;

  if ($self->{handle}) {
    return Device::MTP::File->from_array(files=>Device::MTP::mtp_get_file_listing($self->{handle}));
  }

  return ();
}

sub _get_folder_by_id {
  my ($self, $id) = @_;

  if (!$self->{handle} || !$id) {
    return undef;
  }

  return Device::MTP::Folder->from_hashref(handle=>Device::MTP::mtp_get_folder_by_id($self->{handle},$id));
}

sub music_folder {
  my ($self) = @_;

  if ($self->{handle}) {
    return $self->_get_folder_by_id($self->{handle}->{default_music_folder});
  }

  return undef;
}

sub organizer_folder {
  my ($self) = @_;

  if ($self->{handle}) {
    return $self->_get_folder_by_id($self->{handle}->{default_organizer_folder});
  }

  return undef;
}

sub picture_folder {
  my ($self) = @_;

  if ($self->{handle}) {
    return $self->_get_folder_by_id($self->{handle}->{default_picture_folder});
  }

  return undef;
}

sub playlist_folder {
  my ($self) = @_;

  if ($self->{handle}) {
    return $self->_get_folder_by_id($self->{handle}->{default_playlist_folder});
  }

  return undef;
}

sub video_folder {
  my ($self) = @_;

  if ($self->{handle}) {
    return $self->_get_folder_by_id($self->{handle}->{default_video_folder});
  }

  return undef;
}

sub zencast_folder {
  my ($self) = @_;

  if ($self->{handle}) {
    return $self->_get_folder_by_id($self->{handle}->{default_zencast_folder});
  }

  return undef;
}

sub send_file($$$;$) {
  my ($self, $file, $folderid, $callback) = @_;

  if (!(-e $file)) {
    $Device::MTP::ERRMSG = "Cannot send file '$file': $!";
    return undef;
  } elsif (!(-r $file)) {
    $Device::MTP::ERRMSG = "Cannot send file '$file': $!";
  }

  if ($self->{handle}) {
    return Device::MTP::mtp_post_file($self->{handle}, $file, $folderid, $callback);
  }

  return undef;
}

1;
