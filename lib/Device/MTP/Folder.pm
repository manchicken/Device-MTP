package Device::MTP::Folder;
use Device::MTP;
use Carp qw{confess};

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
	confess("No handle passed to ".__PACKAGE__."::from_hashref.");
    }

    return $class->new(%opts);
}

sub from_array {
    my ($class, %opts) = @_;

    my @folders = @{$opts{folders}};
    my @list = ();;
    delete($opts{folders});

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
	return $self->{handle}->{folder_id};
    }

    return undef;
}

sub parent_folder {
    my ($self) = @_;

    if (!$self->{handle}) {
	return undef;
    }

    my $parent = Device::MTP::mtp_get_parent_folder($self->{handle});

    if ($parent) {
	return __PACKAGE__->from_hashref(handle=>$parent);
    } else {
	return undef;
    }
}

sub files {
    my ($self) = @_;

    if (!$self->{handle}) {
	return undef;
    }

    my @files = Device::MTP::File->from_array(files=>Device::MTP::mtp_get_files_by_folder($self->{handle}));

    return @files;
}

1;
