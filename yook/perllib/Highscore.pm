#!/usr/local/bin/perl

package Highscore;

use DBI;
use strict;

# <dbi to use> ,<table to use> , <encryption key>, { structure },
# 
# structire descripts fields. Fields points & time must be present
# with type of int
# 

sub new {
   my $proto = shift;
   
   my $self = {};

   $self->{dbi} = shift;
   $self->{table} = shift;
   $self->{key} = shift;

   $self->{struct} = shift;

   #init table in not already existing

   #my $q = " ( points int not null, time int, name char(30) , url text ";

   #go for the columns
   #foreach( keys %{$self->{struct}}) {
   #    $q .= ", $_ $self->{struct}->{$_}";
   #}
   #$q.= ",index $self->{table}_points ( points ))";

   #my $query = "CREATE TABLE  $self->{table}" . $q ;

   #die $query;
   #$self->{dbi}->do($query) || die $DBI::errstr . $query;
   
   

   my $class = ref($proto) || $proto;
   bless ( $self, $class);
   return $self;  
}

sub decrypt_score {
    my $self = shift;
    my $scoredata = shift;
    my $qq =  pack("H*",$scoredata);  
    my @mask =  split(/ */,$self->{key});
    my @message = split(/ */,$qq);
    my $decrypted;
    for my $i ( 0..$#message)  {
	$decrypted .=  chr(ord($message[$i]) ^ ord($mask[$i % ($#mask+1)]));
    }

    return $decrypted;
}

# accepts hash with score values to be inserted, returns positions in 
# highscore lists
sub put_score {
    my $self = shift;
    my %scoredata = @_;

    #compose query
    my @ff;
    my @vv;
    my $qq = "insert into $self->{table} ";

    foreach(keys %scoredata) {
	push @ff , $_;
	
	if($self->{struct} =~ /int/) {
	    push @vv , $scoredata{$_};
	} else {
	    $scoredata{$_} =~ s/'/''/;
	    push @vv , "'$scoredata{$_}'";
	}
    }

    $qq .= "( " . join(',',@ff) . ") values (" . join(',',@vv) . ")";

    #$self->{dbi}->do("lock tables $self->{table} write") || die $DBI::errstr;
    my %retval;
    #determine positions
    my @pos = $self->{dbi}->selectrow_array("select count(*) from $self->{table} where points >= $scoredata{points}");
    
    $retval{global} = $pos[0] + 1;
    my $timeval = $scoredata{'time'} - $scoredata{'time'} % 86400;
    @pos = $self->{dbi}->selectrow_array("select count(*) from $self->{table} where  points >= $scoredata{points} and time > $timeval");
    $retval{daily} = $pos[0] + 1;
    #insert entry
    $self->{dbi}->do($qq) || die $DBI::errstr . $qq;

    $self->{dbi}->do('unlock tables');


    $self->{dbi}->do("update gamecount set count = count+1 where name='$self->{table}'");
    return \%retval;

}

sub cleanup_highscore {
    my $self = shift;
#cleanup highscore lists
    my @top_border;

    $self->{dbi}->do("lock tables $self->{table} write");
    
    @top_border = $self->{dbi}->selectrow_array("select points from $self->{table} order by points desc limit 199,1");

    my $now = time;
    $now = $now - $now % 86400;

    if(! $top_border[0]) {
	$self->{dbi}->do("unlock tables");
	return;
    }
    $self->{dbi}->do("delete from $self->{table} where points < $top_border[0] and time < $now") || die $DBI::errstr . "delete from $self->{table} where points < $top_border[0] and time < $now";

    $self->{dbi}->do("unlock tables");
}

#return score count from specifed time

sub get_score_count  {
    my $self = shift;
    my $timeval = shift;


    my @qq = $self->{dbi}->selectrow_array("select count(*) from $self->{table} where time > $timeval");

    return $qq[0];
}


# timeval ,from , amount ,  @fields
sub get_scores {
    my $self = shift;
    my $timeval = shift;
    my $from = shift;
    my $amount = shift;
    my $fields = shift;

    my $ff = join(',',@$fields);
    #die "select $ff from $self->{table} where time > $timeval order by points desc limit $from , $amount";
    my $scores = $self->{dbi}->selectall_arrayref("select $ff from $self->{table} where time > $timeval order by points desc limit $from , $amount");

    return $scores;

}

sub get_top_scores {

    my $self = shift;
    my $retval = {};

    my $tt = time;
    $tt -= $tt % 86400;
    my @best = $self->{dbi}->selectrow_array("select name , points,url, time from $self->{table} order by points desc limit 1");

    $retval->{global} = { name=>$best[0],points=>$best[1],url=>$best[2],'time'=>$best[3]};

    @best =  $self->{dbi}->selectrow_array("select name , points,url, time from $self->{table} where time > $tt  order by points desc limit 1");
    $retval->{today} = { name=>$best[0],points=>$best[1],url=>$best[2],'time'=>$best[3]};

    @best = $self->{dbi}->selectrow_array("select count from gamecount where name='$self->{table}' limit 1");
    $retval->{count} = $best[0];
    return $retval;
}
1;
