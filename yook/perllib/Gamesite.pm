#!/usr/local/bin/perl


#this package encapsulates necessary api functions 
# for games system

package Gamesite;

use strict;
use DBI;


sub new {
    my $proto = shift;
    my $db = shift;
    my $user = shift;
    my $passwd = shift;

    my $self = {
	db=>$db,
	user=>$user,
	passwd=>$passwd,
    };
    # open database connection 
    $self->{dbi} =  DBI->connect("dbi:mysql:database=$db",$user,$passwd) || die $DBI::errstr;

    my $class = ref($proto) || $proto;
    bless ( $self, $class);

    return $self;
}


sub DESTROY {
    my $self = shift;

    $self->{dbi}->disconnect;
    undef $self->{dbi};
}
sub get_db {
    my $self = shift;
    return $self->{dbi};
}


1;


