#!/usr/local/bin/perl -I.

=pod
this is a sample AIS "login" program, which
handles the login buttons sent out by the "add" program.
=cut

# look for "SK" in CGI data
$rawdata = join '', $ENV{QUERY_STRING}, <STDIN>;
($SK) = ($rawdata =~ m/SK=([^&]+)/);

print STDERR "have SK and it is <$SK>\n";

use DirDB; # a concurrent-write-safe database :)
tie %SSO,'DirDB','data/SSO_keys'; 
tie %Ses,'DirDB','data/Sessions'; 

my $SessionCookie = join '',time,(map {("A".."Z")[rand 26]} (0..25)), $$;

my $email;

unless ($email = $SSO{$SK}){
	print <<EOF and exit;
Content-Type: text/html

<body bgcolor=ffffff>

Sorry, but the AIS login button you have clicked refers to
a single sign-on capability key that either does not exist or
has been deleted. <p>

<form method=POST action="/cgi/ais/add">
What is a good e-mail address for you?
<input type=text name="email">
<input type=submit value="send me a new log-in button">
</form>

</body>


EOF

};

$Ses{$SessionCookie} = $email;


open(MAIL,"|sendmail -t -i -f 'AIS-bounce-recipient\@$ENV{SERVER_NAME}'");
print MAIL <<EOF;
To: <$email>
From: AIS-autoresponder\@$ENV{SERVER_NAME}
X-Abuse-To: (tracert $ENV{HTTP_ADDR})\@abuse.net
Subject: AIS LOGIN receipt for $email

You have logged in to the $ENV{SERVER_NAME} AIS service
 from IP address $ENV{REMOTE_ADDR}
 using a $ENV{HTTP_USER_AGENT} web browser.

EOF

print <<EOF;
Set-Cookie: AIS_Session=$SessionCookie; path=/cgi/ais/;
Content-Type: text/html

<body bgcolor=ffffff>

Welcome (back)! You are connecting from $ENV{REMOTE_ADDR}<p>

A message recording this AIS log-in has been e-mailed to &lt;$email&gt;<p>

Unless you have disabled cookies, you now are authenticable via the
AIS service at $ENV{SERVER_NAME}.

Please use your browser's BACK and RELOAD features to return to the page
you are trying to access, if any.<p>

</body>

EOF

__END__


