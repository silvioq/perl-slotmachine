# vim: set cin sw=2:
use  strict;
use  warnings;

package  SlotMachine;
# TODO: Pay table

use  constant{
  JOKER => 999,
  WIN_SIMPLE     => 1,
  WIN_WITH_JOKER => 2,
  WIN_JACKPOT    => 3,
  WIN_ALL_JOKERS => 4,
  WIN_SPECIAL    => 5,
};

use  constant WIN_DESCRIPTION => {
  0 => 'Lose',
  1 => 'Win',
  2 => 'Win with joker',
  3 => 'Win jackpot',
  4 => 'All jokers',
};

# Create new SlotMachine
# Options:
#    payout:       Payout coeficient of the machine. Default 0.92
#    overpay:      Maximun payment over balance. Default 10 coins
#    jp_chance:    Chance of Jackpot. Default 0.001
#    jp_increment: Increment of Jackpot fund on every run. Default 0.07 coins
#    jp_initial:   Initial value of Jackpot. Default 10 coins
#    jp_minimun:   Minimum price of Jackpot. Default 50 coins
#    jp_symbol:    Symbol for Jackpot. Default undef
#    jp_name:      Name for jackpot. Default jp
#    symbols:      Symbols by reel. Default 6
#    reels:        Reels of machine. Default 3
#    jokers:       Quantity of Jokers. Default 0.
#    win_from:     Quantity of equals result to win. Default: reels
sub  new(;$){
  if( scalar( @_ ) > 2 ){
    my $class = shift;
    my %opts = ();
    while( my $o = shift ){
      $opts{$o} = shift;
    }
    return $class->new( \%opts );
  }
  my ( $class, $opts ) = @_;
  $opts = { } unless $opts;
  $opts->{payout} = 0.92        unless exists $opts->{payout};
  $opts->{overpay} = 10         unless exists $opts->{overpay};
  $opts->{jp_chance} = 0.001    unless exists $opts->{jp_chance} || exists $opts->{jp_symbol};
  $opts->{jp_increment} = 0.07  unless exists $opts->{jp_increment};
  $opts->{jp_initial} = 10      unless exists $opts->{jp_initial};
  $opts->{jp_minimun} = 50      unless exists $opts->{jp_minimun};
  $opts->{jp_name} = 'jp'       unless exists $opts->{jp_name};
  $opts->{symbols} = 6          unless exists $opts->{symbols};
  $opts->{reels} = 3            unless exists $opts->{reels};
  $opts->{jokers} = 0           unless exists $opts->{jokers};
  $opts->{win_from} = $opts->{reels}
                                unless exists $opts->{win_from};
  die "Jokers must be less than or equal than reels" if $opts->{jokers} > $opts->{reels};
  die "Can't define jp_chance and jp_symbol at same time" if exists $opts->{jp_chance} && exists $opts->{jp_symbol};

  my  $self =  bless $opts,  $class;
  $self->_set_jp_symbol_chance if exists $opts->{jp_symbol};
  return  $self;
}

# Get/Sets payout of machine
sub  payout(;$){
  my $self = shift;
  $self->{payout} = shift if( scalar(@_) == 1 );
  return $self->{payout};
}

# Get/Sets overpay of machine
sub  overpay(;$){
  my $self = shift;
  $self->{overpay} = shift if( scalar(@_) == 1 );
  return $self->{overpay};
}

# Get/Sets quantity of reels of machine
sub  reels(;$){
  my $self = shift;
  if( scalar(@_) == 1 ){
    $self->_reset();
    $self->{reels} = shift;
  }
  return $self->{reels};
}

# Get/Sets quantity of Jokers
sub  jokers(;$){
  my $self = shift;
  if( scalar(@_) == 1 ){
    my $j = shift;
    die "Jokers must be less than or equal than reels" if $j > $self->reels();
    $self->{jokers} = $j;
    $self->_reset;
  }
  return $self->{jokers};
}

# Get/Sets quantity of symbols of every reel
sub  symbols(;$){
  my $self = shift;
  if( scalar(@_) == 1 ){
    $self->_reset();
    $self->{symbols} = shift;
  }
  return $self->{symbols};
}

# Get/Sets quantity of needed equals result
sub  win_from(;$){
  my $self = shift;
  if( scalar(@_) == 1 ){
    $self->_reset();
    $self->{win_from} = shift;
  }
  return $self->{win_from};
}

# Get/Sets Jackpot increment
sub  jp_increment(;$){
  my $self = shift;
  if( scalar(@_) == 1 ){
    $self->{jp_increment} = shift;
  }
  return $self->{jp_increment};
}

# Get/Sets Jackpot chance
sub  jp_chance(;$){
  my $self = shift;
  if( scalar(@_) == 1 ){
    die "Can't define chance, because the Jackpot are defined by Symbol" if exists $self->{jp_symbol};
    $self->{jp_chance} = shift;
  }
  return $self->{jp_symbol_chance} if( exists $self->{jp_symbol} );
  return $self->{jp_chance};
}

sub  _set_jp_symbol_chance(){
  my $self = shift;
  $self->{jp_symbol_chance} = 1 / 
      ( $self->{symbols} ** ( $self->{reels} - $self->{jokers} ) * 
      ( $self->{symbols} + 1 ) ** $self->{jokers} ) ;
}
# Get/Sets Jackpot chance
sub  jp_symbol(;$){
  my $self = shift;
  if( scalar(@_) == 1 ){
    die "Can't define symbol, because the Jackpot are defined by Chance" if exists $self->{jp_chance};
    $self->{jp_symbol} = shift;
    $self->_set_jp_symbol_chance;
  }
  return $self->{jp_symbol};
}


# Get/Sets Jackpot initial
sub  jp_initial(;$){
  my $self = shift;
  if( scalar(@_) == 1 ){
    $self->{jp_initial} = shift;
  }
  return $self->{jp_initial};
}

# Add payment for simple result
# $slog->add_payment_simple($description, $revenue, @definition )
# @definition is a array of equal counts of symbols
sub  add_payment_simple($$@){
  shift->_add_payment( WIN_SIMPLE, shift, shift, @_ );
}

# Add payment for result with jokers
# $slog->add_payment_with_jokers($description, $revenue, @definition )
# @definition is a array of equal counts of symbols. The last position is Joker count.
sub  add_payment_with_jokers($$@){
  shift->_add_payment( WIN_WITH_JOKER, shift, shift, @_ );
}

# Add payment for all jokers
# $slog->add_payment_all_jokers($description, $revenue )
sub  add_payment_all_jokers($$){
  shift->_add_payment( WIN_ALL_JOKERS, shift, shift );
}

# Add payment for jackpot
# $slog->add_payment_jackpot($description, $revenue, $jackpot_symbol )
sub  add_payment_jackpot($$$){
  shift->_add_payment( WIN_JACKPOT, shift, shift, shift );
}

# Add payment for special result
# $slog->add_payment_special($description, $revenue, @symbols )
sub  add_payment_special($$@){
  shift->_add_payment( WIN_SPECIAL, shift, shift, @_ );
}

# Add result to pay table
# $slot->add_payment( $type, $description, $revenue, @definition )
sub  _add_payment($$$@){
  my  $self     = shift;
  my  $type     = shift;
  my  $desc     = shift;
  my  $revenue  = shift;
  my  @result   = @_;

  die "Payment type $type incorrect"  
      if grep { $type != $_ } WIN_SIMPLE, WIN_WITH_JOKER, WIN_ALL_JOKERS, WIN_JACKPOT, WIN_SPECIAL ;

  $self->{paytable} = [] unless exists $self->{paytable};
  if( $type == WIN_SIMPLE || $type == WIN_WITH_JOKER ){
    die "Result can't contain Jokers" if grep{ $_ == JOKER } @result;
    my $count = 0; 
    foreach(@result){ $count += $_ };
    if( $type == WIN_SIMPLE ){
      @result = sort{ $b <=> $a } @result;
    } else {
      my $j = $result[-1];
      @result = sort{ $b <=> $a } @result[0..-1];
      push @result, $j;
    }

    die "Too much results ($count), must be less or equal than reels" if( $count > $self->reels );
    die "Too much jokers (" . $result[-1] . "), must be less or equal than " . $self->jokers 
                                           if $type == WIN_WITH_JOKER && $result[-1] > $self->jokers ;
    push @{$self->{paytable}}, { type => $type, revenue => $revenue, description => $desc, result => \@result };
  } elsif( $type == WIN_ALL_JOKERS ){
    push @{$self->{paytable}}, { type => $type, revenue => $revenue, description => $desc };
  } elsif( $type == WIN_JACKPOT ){
    die "Symbol ". $result[0] ." incorrect" if $result[0] > $self->symbols;
    push @{$self->{paytable}}, { type => $type, revenue => $revenue, description => $desc, jackpot => $result[0] };
  } elsif( $type == WIN_SPECIAL ){
    die "Must indiate a symbol for each reel" unless scalar(@result) == $self->reels;
    @result = sort @result;
    push @{$self->{paytable}}, { type => $type, revenue => $revenue, description => $desc, result => \@result };
  } else {
    die "Type $type unimplemented"
  }
}



# Get array of symbols for reel
sub  symbols_by_reel(;$){
  my $self = shift;
  if( !defined $self->{_array_max} ){
    my @a = $self->_generate_max();
    $self->{_array_max} = \@a;
  }
  if( scalar(@_ ) > 0 ){
    return  $self->{_array_max}->[shift];
  } elsif( wantarray ){
    return  @{$self->{_array_max}};
  } else {
    return $self->{_array_max};
  }
}

# Was the reel a joker?
sub   reel_has_joker($){
  my $self = shift;
  return $self->jokers >= $self->reels - shift;
}

# Iterator for all results
sub  all_results(\&){
  my  @array = ( );
  my  $self = shift;
  my  $ret  = shift;
  my  $antiloop = $self->symbols() ** $self->reels();
  my  $count = 0;
  while( $self->_next( \@array ) ){
    &$ret( @array );
  }
}

# Say all results
sub  print_all_results(;$){
  my  $self = shift;
  my  $verbose = shift;
  my  %w = ();
  my  $count = 0;
  my  $goods = 0;
  my  $has_jp = 0;
  $self->all_results( sub{ 
      my  @result = $self->get_result( @_ );
      my  $win = shift( @result );
      $has_jp = 1 if $win == WIN_JACKPOT;
      $count ++;
      my $d;
      my $numbers = join '.', @result;
      if( $numbers ){
        $d = WIN_DESCRIPTION->{$win} . " ($numbers)";
        $win = $win . ".$numbers";
      } else {
        $d = WIN_DESCRIPTION->{$win};
      }
      $w{$win} = 0 unless defined $w{$win};
      $w{$win} ++;
      print join( ', ', @_ ) . " => $win - " . $d . "\n" if $verbose ; 
    } );

  my  $wres    = scalar(keys(%w)) - 1 - $has_jp;
  die "No winners in this configuration" if $wres == 0;
  my  $coins   = int( 0.5 + $count * $self->payout / $wres );

  foreach( sort( keys( %w ) ) ){
    my  @w = split(/\./, $_);
    my  $r = shift(@w);
    my  $revenue = ( $_ eq 0 || $r == WIN_JACKPOT ? 0 : int( $coins / $w{$_} ) );
    my  $d = WIN_DESCRIPTION->{$r} . " " . join('.', @w );
    printf( "%-28s: %8d rolls (%6.2f%%): %7d coins per win\n", $d , $w{$_}, 
        100.0 * $w{$_} / $count,
        $revenue );
    $goods += $revenue * $w{$_};
  }
  printf "%-28s: %8d rolls\n", "Total", $count ;
  printf "%-28s: %8d coins\n", "Revenue", $goods ;
  printf "%-28s: %8d coins\n", "Jackpot", $count * ( $self->jp_increment + $self->jp_initial * $self->jp_chance );
  printf "%-28s: %6.2f (parameter is %6.2f)\n", "Real payout %", $goods / $count * 100.0, $self->payout * 100;
  printf "%-28s: %6.2f + %6.2f\n", "Jackpot payout %", $self->jp_increment * 100.0, 
        $self->jp_chance * $self->jp_initial * 100.0;
  printf "%-28s: %6.2f\n", "Total payout %", 
    $goods / $count * 100.0 +
    $self->jp_chance * $self->jp_initial * 100.0 +
    $self->jp_increment * 100.0;
}

# Return result of given symbols
# Result is a array
#   $result[0] is a win type:
#           LOSE (0)
#           WIN_SIMPLE (1):     Win something
#           WIN_WITH_JOKER (2): Win with al least one Joker
#           WIN_ALL_JOKERS(3)  : All of symbols are Jokers
#   $result[1..n]
#           numbers of equal symbos (ordered)
#   if WIN_WITH_JOKER is found, the last position of result ($result[-1]) is Joker quantity
#
sub  get_result(@){
  my  $self = shift;
  my  $reels = $self->reels();
  my  $current_reel = 0;
  my  $symbols = $self->symbols();
  my  $win_from = $self->win_from();
  my  $jp_symbol = $self->jp_symbol();
  my  $jokers    = 0;
  my  $has_symbol = 0;
  my  $has_selected = 0;

  die "Number of results must be equal to reels ($reels)" if $reels != scalar(@_);
  my  $counter = $self->_count_symbols( @_ );
  if( exists $counter->{SlotMachine::JOKER} ){
    $jokers = $counter->{SlotMachine::JOKER};
    delete $counter->{SlotMachine::JOKER};
  }

  # Delete unuseful results ...
  my  $tempj = $jokers;
  foreach( sort{ $counter->{$b} <=> $counter->{$a} } keys %{$counter} ){
    if( $counter->{$_} + $tempj < $win_from ){
      delete $counter->{$_};
    } elsif( $counter->{$_} >= $win_from ){
      $has_selected = 1;
      next;
    } else {
      $tempj -= $win_from - $counter->{$_};
      $has_selected = 1;
    }
  }

  return 0 if !$has_selected && $jokers < $win_from;

  if( $jp_symbol && ( ( exists $counter->{$jp_symbol} && $counter->{$jp_symbol} == $reels ) || 
                      ( $jp_symbol == JOKER && $jokers == $reels ) ) ){
    return  WIN_JACKPOT, ( $jp_symbol == JOKER ? $jokers : $counter->{$jp_symbol} );
  } elsif( $jokers && !$has_selected ){
    return  WIN_ALL_JOKERS, $jokers;
  } elsif( $jokers ){
    return  WIN_WITH_JOKER, sort( { $b <=> $a } values %{$counter} ), $jokers;
  } elsif( keys %{$counter} ){
    return  WIN_SIMPLE, sort { $b <=> $a } values %{$counter};
  } else {
    die "Error of result";
  }
}


sub  _reset(){
  my $self   = shift;
  delete  $self->{_array_max};
  return  1;
}


sub  _next(\@){
  my $self   = shift;
  my $array  = shift;

  if( scalar(@{$array}) == 0 ){
    for( 1..$self->reels ){
      push @{$array}, 1;
    }
    return  1;
  }

  my $reel   = $self->reels() - 1; 
  while( 1 ){
    my $max = $self->symbols_by_reel($reel);
    if( $max <= $array->[$reel] ){
      $array->[$reel] = 1;
      return 0 if( $reel == 0 );
      $reel --;
    } else {
      $array->[$reel] ++;
      $array->[$reel] = JOKER if( $self->reel_has_joker( $reel ) && $max == $array->[$reel] );
      last;
    }
  }
  return 1;
}

sub  _generate_max(){
  my  $self = shift();
  my  @array = ();

  my  $reels = $self->reels();
  my  $symbols = $self->symbols();
  my  $jokers = $self->jokers();
  for( 1..$reels - $jokers ){
    push  @array, $symbols;
  }
  for( 1..$jokers ){
    push  @array, $symbols + 1;
  }
  return  @array;
}

sub  _count_symbols(@){
  my $self = shift;
  my $counter = {};
  while( my $result = shift ){
    if( $counter->{$result} ){
      $counter->{$result} ++;
    } else {
      $counter->{$result} = 1;
    }
  }
  return  $counter;
}

1;
