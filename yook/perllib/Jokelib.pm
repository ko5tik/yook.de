#!/usr/local/bin/perl

{
    package Joke;

    use Persistent::MySQL;

    @ISA = qw(Persistent::MySQL);


    use constant JOKE => 1;
    use constant TALE => 2;
    # status constant
    use constant NO_REVIEW => 0;
    use constant ACCEPTED => 1;
    use constant REMOVED => 2;

sub initialize {
    my $this = shift;
    
    $this->SUPER::initialize(@_);

    $this->add_attribute('id','I','Number', undef, 11 );
    $this->add_attribute('joke','p','String',undef,undef);
    $this->add_attribute('kind','p','Number',undef,11);
    $this->add_attribute('status','p','Number',undef,11);
    $this->add_attribute('note','p','Number',undef,11);
    $this->add_attribute('voters','p','Number',undef,11);
    $this->add_attribute('date','p','Number',undef,11);
    $this->add_attribute('ip','p','Number',undef,11);
    $this->add_attribute('teller','p','String',undef,undef);
    $this->add_attribute('teller_url','p','String',undef,undef);
    $this->add_attribute('teller_email','p','String',undef,undef);
  
}


sub get_release_dates {
    my $this = shift;
    my $kind = shift;
    my $status = shift;
    my $from = shift;
    my $to = shift;

    $from = 0 unless $from;
    $to = time unless $to;

    my $ar = $this->{DataStore}->{DBH}->selectall_arrayref("select distinct date - mod(date,86400) as dd  from jokes  where kind=$kind and date > $from and date < $to and status = $status order by dd desc") || die $DBI::errstr;
    my @rv;
    foreach(@$ar) {
	push @rv , $_->[0];
    }
    return  \@rv;
}

}
