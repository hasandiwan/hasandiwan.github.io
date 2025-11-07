#!perl
use diagnostics;
use strict;
use warnings;

use Date::Manip;
use Digest::SHA1 qw/sha1_hex/;
use Env qw(HOME);
use File::Copy;
use File::Temp;
use LWP::Simple;
use URI;
use vars qw/$tmpname/;

my $dm = new Date::Manip::Date;
open(my $html, '>', "$HOME/public_html/papers/index.html") or die "$0: $!\n";
print $html '<html><head><title>Papers Hosted here</title></head><body><center><h2><u>Papers hosted here</u></h2></center> <br/><table><thead><tr><th>Link</th><th>Date added</th></tr></thead><tbody>';
opendir(my $dh, "$HOME/public_html/papers");
chdir "$HOME/public_html/papers";
if (URI->new($ARGV[0])->scheme) {
    my @remotepath = split /\//, URI->new($ARGV[0])->path;
    my @remotefile = split /\./, $remotepath[-1];
    push @remotefile, "index.html" unless @remotefile;
    $tmpname = File::Temp->new(SUFFIX=> $remotefile[1], DIR => "$HOME/public_html/papers");
    getstore($ARGV[0], $tmpname);
}

foreach my $file (readdir($dh)) {
    next if $file eq '.' or $file eq '..' or $file eq 'index.html';
    my $position = rindex $file, '.';
    my $ext = substr $file, $position;
    open my $pdf, "<$HOME/public_html/papers/$file" or die "$!";
    my $cdate_ss = stat($pdf);
    my $cdate_ms = $cdate_ss/1000.0;
    $dm -> parse($cdate_ms);
    my $cdate = $dm->printf('%B%e, %Y %H:%M');
    my $filecontent = '';
    $filecontent .= "$_\n" foreach(<$pdf>);
    close $pdf;
    my $new_name = sha1_hex($filecontent).$ext;
    print $html "<tr><td><a href=\"https://hasan.d8u.us/papers/$new_name\" target=\"_new\">$new_name</a></td><td>$cdate <script>moment.tz.guess()</script></td></tr>";
    unless (-e $new_name) {
        File::Copy::move($file, $new_name);
        chmod 0644, $new_name;
        unlink $file;
    }
    CORE::say "$file => $new_name";
}

print $html '</table><div class=\"footer\">Generated on'.UnixDate(ParseDate('now'), ' %B%e, %Y @ %H:%M:%S %Z').'</div><script src="//cdn.jsdelivr.net/npm/moment-timezone@0.5.43/builds/moment-timezone-with-data.min.js" integrity="sha512-KCI+fR3bUbOcU0ZC3UcaPwCLuO5LEkukaWBYddmhLPXgpAPWJ8j6pJLmTI6t9CMYczE4YCrWZQ/wrZz/JsyC+A==" crossorigin="anonymous"></script></body></html>';
`git reset --mixed && git add "$HOME/public_html/papers/index.html" && git commit -m "add new paper" && git push`;
close $html;

