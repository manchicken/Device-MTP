package Device::MTP::File;
use Device::MTP;
use Device::MTP::Folder;

sub new {
    my ($class, %opts) = @_;

    my $self = {map { $_ => $opts{$_} } keys(%opts)};

    bless($self,$class);

    $self->{handle} ||= undef;

    return $self;
}

sub DESTROY {
    my ($self) = @_;

    return;
}

sub from_hashref {
    my ($class, %opts) = @_;

    if (!$opts{handle}) {
	die("No handle passed to ".__PACKAGE__."::from_hashref.");
    }

    return $class->new(%opts);
}

sub from_array {
    my ($class, %opts) = @_;

    if (!$opts{files}) {
	return ();
    }
    my @files = @{$opts{files}};
    if (!scalar(@files)) {
	return ();
    }
    my @list = ();;
    delete($opts{files});

    for my $one (@files) {
	if ($one) {
	    push(@list, $class->from_hashref(handle => $one,%opts));
	}
    }

    return @list;
}

sub id {
    my ($self) = @_;

    if ($self->{handle}) {
	return $self->{handle}->{item_id};
    }

    return undef;
}

sub folder {
    my ($self) = @_;

    if (!$self->{handle}) {
	return undef;
    }

    my $data = Device::MTP::mtp_get_folder_from_file($self->{handle});
    my $folder = undef;

    $folder = Device::MTP::Folder->from_hashref(handle=>$data) if($data);

    return $folder;
}

1;
