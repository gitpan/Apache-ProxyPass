package Apache::ProxyPass;

$VERSION='0.04';

use strict;
use LWP::UserAgent ();
use Apache::Constants ':common';

my %Config = (
	'ProxyPass_filename'=>''
);

my %cfg=undef;

sub handler {
    my $r = shift;
    my($key,$val);
    my $uri=$r->uri;
    #get configuration
    my $attr = { };
    while(($key, $val) = each %Config) {
      $val = $r->dir_config($key) || $val;
      $key =~ s/^ProxyPass_//;
      $attr->{$key} = $val;
    }
    my $list=$attr->{list};
    if (!defined(%cfg)) {
      warn "reading in proxy configuration\n";
      open(IN,$attr->{filename});
      while(<IN>) {
        split;
	if (defined($_[0]) && defined($_[1]) && ($_[0] ne "") && ($_[1] ne "")) {
          $cfg{$_[0]} = $_[1];
          }
        }
     }
    my $from;
    foreach $from (keys %cfg) {
      if ($uri =~ /^$from/) {
        $uri=~s!^$from!$cfg{$from}!;
	last;
        }   
      }
    my $request = new HTTP::Request $r->method, $uri;
    my(%headers_in) = $r->headers_in;
    while(($key,$val) = each %headers_in) {
	$request->header($key,$val);
    }

    my $res = (new LWP::UserAgent)->request($request);
    $r->content_type($res->header('Content-type'));
    #feed reponse back into our request_rec*
    $r->status($res->code);
    $r->status_line(join " ", $res->code, $res->message);
    $res->scan(sub {
	$r->header_out(@_);
    });

    $r->send_http_header();
    print $res->content;
    return OK;
}

1;

__END__


=head1 NAME

Apache::ProxyPass - implement ProxyPass in perl

=head1 SYNOPSIS

 #httpd.conf or some such
  PerlSetVar ProxyPass_filename /xxx/proxy.conf

<Location /foo>
  SetHandler perl-script
  PerlHandler Apache::ProxyPass
</Location>

#proxy.conf looks like

/foo/apache http://www.apache.org
/foo/perl http://www.perl.com


=head1 DESCRIPTION

Implement the apache mod_proxy module in perl.  Based on Apache::ProxyPassThru

=head1 AUTHOR

Michael Smith <mjs@iii.co.uk>

