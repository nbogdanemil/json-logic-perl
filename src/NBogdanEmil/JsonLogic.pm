package JsonLogic;

use strict;
use 5.010;
use Carp;
use Data::Dumper;

sub new {
	my $class = shift;
	my $this  = {};

	bless($this, $class);

	return $this;
}

sub is_logic($) 
{
	my $this  = shift;
	my $logic = shift;

	if (ref($logic) eq 'HASH' && keys(%{$logic}) == 1) {
		return 1;
	}

	return;
}

sub apply($$)
{
	my $this  = shift;
	my $logic = shift || {};
	my $data  = shift || {};

	return $logic if(!$this->is_logic($logic));

	my $ops = {
		'==' => sub { 
			my ($a, $b) = @_; 
			return 0 if(!defined($a) || !defined($b));
			return 1 if($a eq $b);
			return 0;
		},
		'===' => sub { 
			my ($a, $b) = @_; 
			return 0 if(!defined($a) || !defined($b));
			return 1 if($a eq $b);
			return 0;
		},
		'!=' => sub { 
			my ($a, $b) = @_; 
			return 0 if(!defined($a) || !defined($b));
			return 1 if($a ne $b);
			return 0;
		},
		'!==' => sub { 
			my ($a, $b) = @_; 
			return 0 if(!defined($a) || !defined($b));
			return 1 if($a ne $b);
			return 0;
		},
		'>' => sub { 
			my ($a, $b) = @_;
			return 0 if(!defined($a) || $a !~ m/[0-9]+/);
			return 0 if(!defined($b) || $b !~ m/[0-9]+/);
			return 1 if($a > $b);
			return 0;
		},
		'>=' => sub { 
			my ($a, $b) = @_; 
			return 0 if(!defined($a) || $a !~ m/[0-9]+/);
			return 0 if(!defined($b) || $b !~ m/[0-9]+/);
			return 1 if($a >= $b); 
			return 0;
		},
		'<' => sub { 
			my ($a, $b, $c) = @_;
			return 0 if(!defined($a) || $a !~ m/[0-9]+/);
			return 0 if(!defined($b) || $b !~ m/[0-9]+/);
			if(!defined($c)) {
				return 1 if($a < $b);
				return 0;
			}
			return 0 if(!defined($c) || $c !~ m/[0-9]+/);
			return 1 if(($a < $b) and ($b < $c));
			return 0;
		},
		'<=' => sub { 
			my ($a, $b, $c) = @_;
			return 0 if(!defined($a) || $a !~ m/[0-9]+/);
			return 0 if(!defined($b) || $b !~ m/[0-9]+/);
			if(!defined($c)) {
				return 1 if($a <= $b);
				return 0;
			}
			return 0 if(!defined($c) || $c !~ m/[0-9]+/);
			return 1 if(($a <= $b) and ($b <= $c));
			return 0;
		},
		'%' => sub {
			my ($a, $b) = @_;
			return ($a % $b);
		},
		'!' => sub {
			my $a = shift;
			return 1 if(!$a);
			return 0;
		},
		'and' => sub {
			my ($a, $b) = @_;
			return 1 if($a && $b);
			return 0;
		},
		'or' => sub {
			my ($a, $b) = @_;
			return 1 if($a || $b);
			return 0;
		},
		'?:' => sub {
			my ($a, $b, $c) = @_;
			return $a ? $b : $c;
		},
		'log' => sub {
			my $a = shift || '';
			use Sys::Syslog qw(:DEFAULT :standard :macros);
			openlog("", 'ndelay', 'local2');
			syslog('info', $a);
			closelog();
			return $a;
		},
		'var' => sub { 
			my $a = shift;
			return if(ref($data) ne 'HASH' || !defined($a));
			my @l = split(/\./, $a);
			my $c = scalar(@l);
			if($c == 1 && exists($data->{$l[0]})) {
				return $data->{$l[0]};
			}
			if($c == 2 && exists($data->{$l[0]}->{$l[1]})) {
				return $data->{$l[0]}->{$l[1]};
			}
			return; 
		},
		'in' => sub {
			return 0 if(!defined($a));
			return 0 if(!defined($b));
			return 1 if(ref($a) eq 'SCALAR' && $a =~ m/$b/);
			return 1 if(ref($a) eq 'HASH'   && grep {$a->{$_} eq $b} %{$a});
			return 1 if(ref($a) eq 'ARRAY'  && grep {$a->[$_] eq $b} @{$a});
			return 0;
		},
		'cat' => sub {
			return print Dumper @_;
		},
		'max' => sub {
			use List::Util qw(max);
			return max(@_);
		},
		'min' => sub {
			use List::Util qw(min);
			return min(@_);
		},
		'+' => sub {
			return 0 if(!defined($a) || $a !~ m/[0-9]+/);
			return 0 if(!defined($b) || $b !~ m/[0-9]+/);
			return int($a + $b);
		},
		'-' => sub {
			return 0 if(!defined($a) || $a !~ m/[0-9]+/);
			return -$a if(!defined($b) || $b !~ m/[0-9]+/);
			return int($a - $b);
		},
		'/' => sub {
			return 0 if(!defined($a) || $a !~ m/[0-9]+/);
			return 0 if(!defined($b) || $b !~ m/[0-9]+/);
			return int($a / $b);
		},
		'*' => sub {
			return 0 if(!defined($a) || $a !~ m/[0-9]+/);
			return 0 if(!defined($b) || $b !~ m/[0-9]+/);
			return int($a * $b);
		},
		'=~' => sub {
			return 0 if(!defined($a) || !defined($b));
			return 1 if($a =~ m/$b/);
			return 0;
		},
		'!~' => sub {
			return 0 if(!defined($a) || !defined($b));
			return 1 if($a !~ m/$b/);
			return 0;
		}
	};

	my ($op, $val) = each %{$logic};

	my $vLogic = (defined($val) && ref($val) eq 'ARRAY') ? $val : [ $val ];

	foreach (sort keys @{$vLogic}) {
		next if(ref($vLogic->[$_]) ne 'HASH');
		$vLogic->[$_] = $this->apply($vLogic->[$_], $data);
	}

	if(!defined($op)) {
		confess "Undefined operator!";
	}
	
	if(!exists($ops->{$op})) {
		confess "Unrecognized operator [$op]!";
	}

	return $ops->{$op}->(@{$vLogic});
}

1;
