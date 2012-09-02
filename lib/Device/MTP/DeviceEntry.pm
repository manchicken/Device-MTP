package Device::MTP::DeviceEntry;

sub new {
    my ($class, %opts) = @_;

    my $self = \%opts;

    bless($self, $class);
    $self->{name} ||= "Unkown Device";

    return $self;
}

1;
