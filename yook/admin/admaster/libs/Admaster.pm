#!/usr/local/bin/perl
package Admaster;

use DBI;
use strict;


#create object & init database connection
# $foo = $Admaster::new(<database>,<user>,<password>)
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
    
    $self->{dbi} =  DBI->connect("dbi:mysql:database=$db",$user,$passwd) || die $DBI::errstr;

    my $class = ref($proto) || $proto;
    bless ( $self, $class);

    return $self;
}

#insert new customer into
# $foo->insert_customer(name=><cutomer_name>,email=><customer_email>)
sub create_customer {
    my $self = shift;
    my %custdata = @_;

    return $self->{dbi}->do("insert into customer ( name , email ) values ('$custdata{name}','$custdata{email}')") || die $DBI::errstr ."insert into customer ( name , email ) values ('$custdata{name}','$custdata{email}'" ;

}

#get all customers ordered by id

sub get_customers {
    my $self = shift;
    return $self->{dbi}->selectall_arrayref("select * from customer order by id");
}

# get customer with specified id
# return array
sub get_customer {
    my $self = shift;
    my $id = shift;
    return $self->{dbi}->selectrow_array("select * from customer where id=$id");
}

#get specified advertising slots, params could be:
# $qq = $foo->get_slots(id=><slot_id>,cust_id=><customer id>,active=><activation status>,format_id=><id of desired format>
# returns arayref containing all selected slots.
# everything can be omited
sub get_slots {
    my $self = shift;
    my %data = @_;
    my @c;

    push @c ,  "id = $data{id} " if defined $data{id};
    push @c ,  "cust_id = $data{cust_id} " if defined $data{cust_id};
    push @c , "active = $data{active} " if defined $data{active};
    push @c ,  "format_id = $data{format_id} " if defined $data{format_id};

    my $q = "select * from slot ";
    $q .= "where " . join(' and ', @c) if scalar @c > 0;

    return $self->{dbi}->selectall_arrayref($q) || die $DBI::errstr . $q;
}

sub create_format {
    my $self = shift;
    my %data = @_;

    return $self->{dbi}->do("insert into format ( description ) values ( '$data{descr}')") || die $DBI::errstr;

}
sub create_site {
    my $self = shift;
    my %data = @_;

    return $self->{dbi}->do("insert into site ( description ) values ( '$data{descr}')") || die $DBI::errstr;

}

sub get_sites {
    my $self = shift;

    return $self->{dbi}->selectall_arrayref("select * from site order by id") || die $DBI::errstr;
}


sub get_formats {
    my $self = shift;
    return $self->{dbi}->selectall_arrayref("select * from format order by id") || die $DBI::errstr;
}



sub create_slot {
    my $self= shift;
    my %data = @_;

    my $i = "insert into slot ( ";
    my $s = " values ( ";

    if($data{cust_id}) {
	$i .= "cust_id ";
	$s .= $data{cust_id};
    }
    if($data{credits}) {
	$i .=', credits';
	$s .=", $data{credits}";
    }
    if($data{code}) {
	$i .=', code';
	$s .=", '$data{code}'";
    }
    if($data{format_id}) {
	$i .=', format_id';
	$s .=", $data{format_id}";
    }
    if($data{ratio}) {
	$i .=', ratio , ratio_used';
	$s .=", $data{ratio},  $data{ratio}";

    }

    my $query = $i . ") " . $s . ")";

    $self->{dbi}->do($query) || die $DBI::errstr . $query;
}


sub update_slot {
    my $self = shift;
    my %data = @_;
    my @u;
    $data{code} = $self->{dbi}->quote($data{code}) if defined $data{code};
    push @u , "code=$data{code}" if defined $data{code};
    push @u , "active=$data{active}" if defined $data{active};
    push @u , "impressions=$data{impressions}" if defined $data{impressions};
    push @u , "credits=$data{credits}" if defined $data{credits};
    push @u , "format_id=$data{format_id}" if defined $data{format_id};
    push @u , "ratio=$data{ratio}" if defined $data{ratio};

    my $q = "update slot set " . join(',',@u) . " where id=$data{id}";
    #die($q);
    $self->{dbi}->do($q) || die $DBI::errstr . $q;
    
}


sub remove_slot {
    my $self = shift;
    my $id = shift;

    $self->{dbi}->do("delete from slot where id=$id");

}

sub serve_ads {
    my $self = shift;
    my %data = @_;

    #get desired amount of advertising slots
    my $selquery = "select id , code , credits, ratio_used from slot where format_id=$data{'format'} and ( credits > 0 or  credits = -1) and active=1  order by ratio_used desc , seq asc limit $data{amount}";
    $self->{dbi}->do('lock tables slot write , seq write')|| die $DBI::errstr;
    my @seq = $self->{dbi}->selectrow_array("select * from seq")|| die $DBI::errstr;
    my $slots = $self->{dbi}->selectall_arrayref($selquery) || die $DBI::errstr . $selquery;

    my @retval;
    foreach(@$slots) {
    my @ss;
    my $uq;
	push @retval , $_->[1];
	push @ss , "credits = credits -1" if $_->[2] > 0;
	if($_->[3] <= 1) {
	    push @ss , "ratio_used = ratio";
	} else {
	    push @ss, "ratio_used = ratio_used-1";
	}
	$seq[0]++;
	$uq = "update slot set " . join(',',@ss) . ", impressions=impressions+1 , seq = $seq[0] where id=$_->[0]";
	$self->{dbi}->do($uq) || die $DBI::errstr . $uq;
    }
    
    $self->{dbi}->do("update seq set seqnr=$seq[0]");
    $self->{dbi}->do('unlock tables');
 return \@retval;   
}
1;
