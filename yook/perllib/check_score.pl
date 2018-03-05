#!/usr/bin/perl


use lib '.';
use Highscore;
#print $ARGV[0] , $ARGV[1];

$s = new  Highscore(undef,'',$ARGV[1]);

print $s->decrypt_score($ARGV[0]),"\n";



