#!/usr/local/bin/perl
package Linkomatic;

use strict;



sub new {
    my $proto = shift;
    my $self = {};
    $self->{dbi} = shift;

    my $class = ref($proto) || $proto;
    bless ( $self, $class);

    return $self;
}

sub DESTROY {
    my $self = shift;
    undef $self->{dbi};

}

sub get_link {
    my $self = shift;
    my $id = shift;
    return $self->{dbi}->selectrow_array("select * from linkomatic where id=$id");
}

sub get_amount {
    my $self = shift;
    my $site = shift;
    my @qq = $self->{dbi}->selectrow_array("select count(*) from linkomatic where site=$site");
    return $qq[0];
}

sub get_links {

    my $self = shift;
    my %d = @_;
    my $o;
    if(defined $d{order}) {
	$o = $d{order};
    }else {
	$o = 'id';
    }
    my $w;
    if(defined $d{site}) {
	$w = " where site=$d{site} ";
    }
    return $self->{dbi}->selectall_arrayref("select * from linkomatic $w order by $o");

}


sub count_in {
    my $self = shift;
    my $id = shift;

    $self->{dbi}->do("update linkomatic set click_in = click_in+1 where id=$id");
}

sub count_out {
    my $self = shift;
    my $id = shift;

    $self->{dbi}->do("update linkomatic set click_out = click_out+1 where id=$id");

}

sub update_link {
    my $self = shift;
    
    my %l = @_;
    my @ss;
    push @ss , "title='$l{title}'" if $l{title};
    push @ss , "contact='$l{contact}'" if $l{contact};
    push @ss , "email='$l{email}'" if $l{email};
    push @ss , "url='$l{url}'" if $l{url};
    push @ss , "password='$l{password}'" if $l{password};

    my $qq = "update linkomatic set " . join (',', @ss) . " where id=$l{id}";

    $self->{dbi}->do($qq);

}

sub remove_link {
    my $self = shift;
    my $id = shift;

    $self->{dbi}->do("delete from linkomatic where id=$id");

}

sub add_link {
    my $self = shift;
    my $title = shift;
    my $contact = shift;
    my $email = shift;
    my $url=shift;
    my $passwd=shift;
    my $site=shift;

    $title = $self->{dbi}->quote($title);;
    $contact = $self->{dbi}->quote($contact);
    $passwd = $self->{dbi}->quote($passwd);
    my $query = "insert into linkomatic ( title, contact, email , url , password, click_in, click_out, site ) values ($title,$contact,'$email' , '$url', $passwd,0,0,$site)";
    #die $query;
    $self->{dbi}->do($query) || die $DBI::errstr . "\n" . $query;

    my @ii = $self->{dbi}->selectrow_array("select last_insert_id() from linkomatic");
    return $ii[0];
    
}


sub dispatch_link {
    my $self = shift;
    my $site=shift;
    $site = 0 unless $site;
    my @retval = $self->{dbi}->selectrow_array("select id, title, click_in, click_out, impressions from linkomatic where site=$site order by impressions asc limit 1");

    $self->{dbi}->do("update linkomatic set impressions=impressions+1 where id=$retval[0]");
    return \@retval;
}
1;
