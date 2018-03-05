<%doc>
pull highscore data into memory. Expire if file changed
</%doc>


<%init>
#decide whether to pull data from disk

$Gamesite::scoredata{'lines'} = { global=>{ age=>0 }, today=> {age=>0}} if($m->current_comp->first_time);




if($Gamesite::scoredata{lines}->{today}->{age} < (stat $Gamesite::config{'datapath'} . "/lines.daily")[9]) {
# read today scores ...
my @scr;
die $! unless open SF , $Gamesite::config{'datapath'} . "/lines.daily";
while(<SF>) {
chop;
my @qq =  split '\[\]', $_, -1;
push @scr ,  \@qq;

}
close SF;

$Gamesite::scoredata{lines}->{today}->{scores} = \@scr;
$Gamesite::scoredata{lines}->{today}->{age} = (stat $Gamesite::config{'datapath'} . "/lines.daily")[9];
#undef @scr;
}
 
if($Gamesite::scoredata{lines}->{global}->{age} < (stat $Gamesite::config{'datapath'} . "/lines.global")[9]) {
# read today scores ...
my @scr;
die $! unless open SF , $Gamesite::config{'datapath'} . "/lines.global";
while(<SF>) {
chop;
my @qq =  split '\[\]', $_, -1;
push @scr ,  \@qq;

}
close SF;

$Gamesite::scoredata{lines}->{global}->{scores} = \@scr;
$Gamesite::scoredata{lines}->{global}->{age} = (stat $Gamesite::config{'datapath'} . "/lines.global")[9];
#undef @scr;
}
return undef;
</%init>