#!/usr/local/bin/perl

{
    package Newsticker;
    
    use Persistent::MySQL;

    @ISA = qw(Persistent::MySQL);


sub initialize {
    my $this = shift;
    
    $this->SUPER::initialize(@_);

    $this->add_attribute('id','I','Number', undef, 11 );
    $this->add_attribute('timestamp','p','Number',undef,11);

    $this->add_attribute('headline','p','String',undef,undef);
    $this->add_attribute('teaser','p','String',undef,undef);
    $this->add_attribute('contens','p','String',undef,undef);
}

}

1;
