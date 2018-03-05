#!/usr/local/bin/perl
{
#subclassed HTML parser to extract meta tags & calculate word
#weights
    package MetaMaster;
    
    use HTML::Parser;
    use Data::Dumper;
    use HTML::Entities;
    use Text::ParseWords;
    use Carp;
    our @ISA=qw(HTML::Parser);
    
    use strict;
    use vars qw($AUTOLOAD);
    
    my %fields = ( 
		  TITLE=>undef,
		  META => undef,
		  TEXT => undef,
		  WORDS => undef
		  );
    
    
    sub new
    {
	my $proto = shift;
	my $class = ref($proto) || $proto;   
	
	
	my $self = bless $proto->SUPER::new(), $class;
	my $element;
	foreach  $element (keys %fields) {
		$self->{_permitted}->{$element} = $fields{$element};
	}
	$self->{META} = {};
	$self->{WORDS} = {};
	$self->{bypass} = 0;
	return $self;
    }

sub start {
    my($self, $tag, $attr, $attrseq, $origtext) = @_;
    
    if($tag eq 'meta') {
#	print Data::Dumper->Dump([$attr]) , "\n";
	$self->{META}->{lc $attr->{name}} =  $attr->{content};
    } elsif( $tag eq 'script') {
	$self->{bypass}++;
    } elsif( $tag eq 'style') {
	$self->{bypass}++;
    } elsif($tag eq 'title') {
	$self->{intitle} = 1;
    }
}

sub end {
    my($self,$tag,$orig) = @_;
    if($tag eq 'script') {
	$self->{bypass}--;
    }elsif($tag eq 'style') {
	$self->{bypass}--;
    }elsif ( $tag eq 'title' ) {
	$self->{intitle} = 0;
    }
}
sub text
{
    my($self, $text) = @_;
    use locale;    
    return if $self->{bypass};
    return unless $text =~ /\w/;
    decode_entities($text);
    
    $text =~ s!^\s*!!; # remove leading ...
    $text =~ s!\s*$!!; # ... and trailing whitespace
    if($self->{intitle}) {
	$self->{TITLE} .= ' ' . $text;
	return;
    }
    $self->{TEXT} .= ' ' . $text;

    my @words = split /\W/ , $text;

    foreach(@words) {
	next unless $_;
	$_ = lc $_;
	if(defined $self->{WORDS}->{$_}) {
	    $self->{WORDS}->{$_}++;
	} else {
	    $self->{WORDS}->{$_} = 1;
	}
    }
    no locale;
}



sub AUTOLOAD {
    my $self = shift;
    my $type = ref($self)
	or croak "$self is not an object";
    
    my $name = $AUTOLOAD;
    $name =~ s/.*://;   # strip fully-qualified portion
    
    unless (exists $self->{_permitted}->{$name} ) {
	#croak "Can't access `$name' field in class $type";
	# fall back to parent
	 return HTML::Parser->AUTOLOAD($self);
    }
    
    if (@_) {
	return $self->{$name} = shift;
    } else {
	return $self->{$name};
    }

}

sub DESTROY {
}

}


1;












