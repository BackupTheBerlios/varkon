{################################
## based on XML::Writer by David Megginson <david@megginson.com>
##
     my @ElementStack;
     my %Entity = ('&' => '&amp;',
		   '<' => '&lt;',
		   '>' => '&gt;',
		   '"' => '&quot;');

     sub doctype {
	 my ($t1, $t2, $t3) = @_;
	 print qq(<!DOCTYPE $t1 PUBLIC "$t2" "$t3">\n);
     }

     sub text {
	 my ($data) = @_;
	 $data =~ s/([&<>])/$Entity{$1}/sgx;
	 print $data;
     }

     sub element {
	 my ($tag, $data, @attr) = @_;
	 startTag($tag, @attr);
	 text($data);
	 endTag();
     }

     sub startTag {
	 my ($tag, @attr) = @_;
	 push @ElementStack, $tag;
	 print "<$tag";
	 print "\n" if @attr;
	 _showAttributes(@attr);
	 print ">";
     }

     sub emptyTag {
	 my ($tag, @attr) = @_;
	 print "<$tag";
	 _showAttributes(@attr);
	 print "\n />";
     }

     sub endTag {
	 my ($tag) = @_;
	 my $cur = pop @ElementStack;
	 if (!defined $cur) {
	     croak("End tag \"$tag\" does not close any open element");
	 } elsif ($tag and $cur ne $tag) {
	     croak("Attempt to end element \"$cur\" with \"$tag\" tag");
	 }
	 print "</$cur>";
     }

     sub _showAttributes {
	 while (@_) {
	     my ($k,$v) = splice @_, 0, 2;
	     $v =~ s/([&<>"])/$Entity{$1}/sgx;
	     print qq( $k="$v");
	 }
     }
}
