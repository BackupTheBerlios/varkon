#!/usr/bin/perl -w

use 5.6.1;
use strict;
use Fatal qw(open);

BEGIN {
  require "./minixml.pl";
}

sub run {
  my ($cmd) = @_;
  system($cmd) == 0 or die "system $cmd failed: $?";
}

sub modtime {
  my ($f) = @_;
  my @s = stat $f;
  $s[9] || 0;
}

sub page {
  my ($file, $x) = @_;
  
  open my $fh, ">tmp$$";
  select $fh;

  doctype 'HTML', '-//W3C//DTD HTML 4.01//EN',
    'http://www.w3.org/TR/html4/strict.dtd';
  startTag 'html';
  startTag 'head';

  $x->();

  endTag 'body';
  endTag 'html';
  print "\n";
  close $fh;
  
  #run "tidy -config tidy.conf -utf8 -xml tmp$$";
  rename "tmp$$", $file or die "rename: $!";
}

sub hskip {
  my $reps = $_[0] || 1;
  print '&nbsp;' while --$reps >= 0;
}

sub vskip {
  my $reps = $_[0] || 1;
  print '<p>&nbsp;</p>' while --$reps >= 0
}

sub body {
  my ($pad) = @_;

  $pad ||= 0;

  startTag ('body',
	    'bgcolor', "#FFFFFF",
	    'topmargin', 0,
	    'bottommargin', 0,
	    'leftmargin', 0,
	    'rightmargin', 0,
	    'marginheight', $pad,
	    'marginwidth', $pad);
}

sub br { emptyTag 'br' }

sub img {
  my ($src, $alt, @rest) = @_;
  emptyTag 'img', src=>$src, alt=>$alt, @rest;
}

sub startLi {
  startTag 'li';
  startTag 'p';
}

sub endLi {
  endTag 'p';
  endTag 'li';
}

sub columns {
  startTag 'table', border => 0, cellspacing => 0, cellpadding => 0;
  startTag 'tr';

  for my $c (@_) {
    startTag 'td';
    $c->();
    endTag 'td';
  }

  endTag 'tr';
  endTag 'table';
}

##########################################################
package MenuTree;

sub new { bless $_[1], $_[0]; }

sub file {
  my ($o, $item) = @_;

  for (my $x=0; $x < @$o; ++$x) {
    my $cur = $o->[$x];

    if (@$cur == 3) {
      my $ans = file($cur->[2], $item);
      return $ans
	if $ans;
    }

    next if $cur->[0] ne $item;
    return $cur->[1];
  }
  undef
}

package main;

##########################################################

our $topmenu = MenuTree
  ->new([
	 ['Varkon'            => 'index.html'],
	 ['FAQ'               => 'faq.html'],
	 ['Mailing Lists'     => 'lists.html'],
	]);

my %Chapter;

sub menupage {
  my ($menu, $curitem, $x) = @_;

  my $file = $menu->file($curitem);
  my $print = $file;
  $print =~ s/\.html$/-pr.html/;

  my $is_chapter;

  page $file, sub {
    element 'title', $curitem;
    endTag 'head';
    body;

    startTag 'table', 'border', 0, cellspacing => 0, cellpadding => 3;
    startTag 'tr';

    startTag 'td', 'valign', 'top', 'bgcolor', '#ccffcc';

    br;

    # this is a gross hack
    for my $item (@$menu) {
      startTag 'p';

      my $sub = $item->[2];
      my $in_sub = MenuTree::file($sub, $curitem)
	if $sub;

      if ($item->[0] eq $curitem) {
	text $item->[0];
      } else {
	element 'a', $item->[0], 'href', $item->[1];
      }

      $is_chapter = 1
	if (@$item == 3 and $item->[0] eq $curitem);

      if (@$item == 3 and ($item->[0] eq $curitem or $in_sub)) {
	push @{ $Chapter{ $menu->file($item->[0]) } }, $x;
	
	startTag 'table';
	for my $s (@{$item->[2]}) {
	  startTag 'tr';
	  startTag 'td';
	  hskip 2;
	  endTag 'td';
	  startTag 'td';
	  if ($s->[0] eq $curitem) {
	    text $s->[0];
	  } else {
	    element 'a', $s->[0], 'href', $s->[1];
	  }
	  endTag 'td';
	  endTag 'tr';
	}
	endTag 'table';
      }
      endTag 'p';
    }

    vskip 2;
    
    element 'a', '[Print]', href => $print;
    if ($is_chapter) {
      my $ch = $file;
      $ch =~ s/\.html$/-ch.html/;
      text ' ';
      element 'a', '[Chapter]', href => $ch;
    }

    vskip 1;
    startTag 'p';
    text 'Hosted by:';
    br;
    startTag 'a', 'href', 'http://developer.berlios.de/projects/varkon';
    emptyTag 'img', 'src', 'http://developer.berlios.de/images/logo_fokus.gif',
      'alt', 'GMD FOKUS', 'border', 0, 'height', 73, 'width', 66;
    endTag 'a';
    endTag 'p';
    
    endTag 'td';
    
    startTag 'td', 'valign', 'top', 'bgcolor', '#ffcccc';
    hskip;
    endTag 'td';

    startTag 'td', 'valign', 'top';
    
    $x->();
    
    endTag 'td';
    
    endTag 'tr';
    endTag 'table';
    vskip 4;

    element 'p', 'Last modified @DATE@.';
  };

  page $print, sub {
    element 'title', $curitem;
    endTag 'head';
    body 10;
    $x->();
    vskip 1;
    
    element 'p', 'Last modified @DATE@.';
  };
};

menupage $topmenu, 'Varkon', sub {
  element 'h1', 'Varkon';
  startTag 'p';
  text 'Varkon is a ';
  element 'a', 'GNU/LGPL',
    href => 'http://www.gnu.org/licenses/licenses.html';
  text ' CAD system available from ';
  element 'a', 'Microform AB',
    href => 'http://www.microform.se';
  text ' in Sweden.  ';
  text "Varkon differs from other CAD systems in that
it is uniquely suitable for programming.";
  endTag 'p';

  element 'p', 'This site is for the users of Varkon
independent of any single company or project.';

  element 'h2', 'Versions';

  element 'p', 'Varkon 1.x is a mature product.  
Microform is now mainly concerned with customer support and consulting.';

  startTag 'p';
  element 'a', 'Prof Johan Kjellander',
    href => 'http://www.microform.se/johan.htm';
  text ' and some PhD-students are
working on working on Varkon version 2.
While Varkon 1.x is not a solid modeler and can unfortunately not
"subtract" or limit surfaces, this is one of the features
expected in Version 2.';
  endTag 'p';
};

menupage $topmenu, 'FAQ', sub {
  element 'h1', 'FAQ';

  startTag 'ul';
  startTag 'li';
  text "Q. It seems like varkon doesn't support partial refs.  For example:";
  startTag 'pre';
  text 'REF r1, r2;
r1 := #2#4;
r2 := r1#2#5;   ! meaning r2 := #2#4#2#5;';
  endTag 'pre';

  element 'p', 'A. You are right. Convert them to strings, add them and convert them back.';
  element 'pre', 'r2:=rval(rstr(r1)+"#2#5");';
  element 'p', '(Johan)';
  endTag 'li';

  startTag 'li';
  element 'p', 'Q. What is the best way to keep constants around
which i can use across more than one module?  For example, i have:';
  element 'pre', 'CONSTANT FLOAT ceiling_height=2.95;
CONSTANT FLOAT wall_thickness=0.15;
CONSTANT FLOAT floor_thickness=0.24;';

  element 'p', 'A. The scope of a constant is one module.
Sometimes we use putdat() and getdat()
to keep global data. (Johan)';

  endTag 'li';

  endTag 'ul';
};

menupage $topmenu, 'Mailing Lists', sub {
  element 'h1', 'Mailing Lists';

  my $list = sub {
    my ($name, $desc, $vol) = @_;

    startTag 'li';
    startTag 'p';
    element 'b', $name;
    text ' - ';
    element 'a', 'Subscribe', 'href', "https://lists.berlios.de/mailman/listinfo/$name";
    text ' / ';
    element 'a', 'Archives', 'href', "https://lists.berlios.de/pipermail/$name";
    endTag 'p';

    startTag 'p';
    text $desc;

    br;

    startTag 'i';
    text $vol;
    endTag 'i';
    endTag 'p';

    endTag 'li';
  };

  startTag 'ul';

  $list->('varkon-discuss',
	  'General discussion about the current and future Varkon.',
'Can be high volume on occation.');

  endTag 'ul';
};


for my $file (keys %Chapter) {
  my $ch = $file;
  $ch =~ s/\.html$/-ch.html/;

  page $ch, sub {
    element 'title', $file;
    endTag 'head';
    body 10;

    for my $x (@{$Chapter{$file}}) {
     $x->();
    }

    vskip 1;

    element 'p', 'Last modified @DATE@.';
  };
}

__END__
