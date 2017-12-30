#!/usr/bin/perl
# Script to emulate a browser for posting to a 
#   CGI program with method="POST".
use strict;
use LWP::UserAgent;
use HTTP::Request::Common;
use Scalar::Util qw(looks_like_number);

# Specify the URL of the page to post to.
my $URLtoPostTo = "http://phoenixx.wox.org/map/updatemap.pl";

#default behavior, upload game state from current folder every 5 minutes
#may need to pull this from the file - location of save state GameStateData.csv
#eg C:\ProgramData\SpaceEngineersDedicated\Ramblers Frontier\Storage
my $dumpfile="GameStateData.csv";
my $adminsettings="GameSetup.csv";

#  a browser name, 
my $BrowserName = "Frontier Gateway";

print "Beginning $BrowserName agent\n";


#Lazy way to check files, append a nul to file. This creates if not existing
print ".Checking/Creating $adminsettings file\n";
open(TDATA, ">>$adminsettings")  or die "File Error $!";;
	print TDATA "";
close(TDATA);

print ".Checking/Creating $dumpfile file\n";
open(TDATA, ">>$dumpfile")  or die "File Error $!";;
	print TDATA "";
close(TDATA);


#load our setup file into memory
print ".Reading $adminsettings configuration\n";
open(TDATA, $adminsettings) or die "File Error $!";
	my $setup_data=<TDATA>;
close(TDATA);

if (!$setup_data) { 
print ".No Configuration in $adminsettings file - creating default placeholders\n
Please note you should edit '$adminsettings'  to correctly configure your Space sector. 
This tool needs to be ran from your maps STORAGE folder and/or where 
the $dumpfile is being created.\n";
$setup_data='Network Name,Requested Grid ID #,passkey,update time in minutes'; 
open(TDATA, ">>$adminsettings")  or die "File Error $!";;
	print TDATA $setup_data;
close(TDATA);
}



#GameSetup.csv
#Network Name,Requested Grid ID #, passkey, update timer, Optional URL if not ours

#remove end of line OS garbage
$setup_data =~ s/\r|\n//g;

my @temp=split(/,/,$setup_data); #seperate by , deliminer#
               
my $net_name=$temp[0];
my $grid_id= $temp[1];  	if (looks_like_number($grid_id))  {} else { $grid_id=0; } 
my $raw_key= $temp[2];
my $update_timer=$temp[3]; 	if (looks_like_number($update_timer))  {} else { $update_timer=5; }
if ($temp[4]) { $URLtoPostTo = $temp[4]; }
my $sleeptime=60*$update_timer;
print "\nSystem Initialised.. Triggering First Galaxy Update\n"; sendmap();
print "\nSystem Operational. Updating every $update_timer Minutes. Press Ctrl-C to terminate.\n";

#work gets done here:

while (1) {
	sleep $sleeptime;
	sendmap();
}




# send all the data in here
sub sendmap {
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime(time);
	my $timestamp = sprintf("%4d-%02d-%02d %02d:%02d:%02d ",$year+1900,$mon+1,$mday,$hour,$min,$sec);
	$timestamp = sprintf("%4d-%02d-%02d %02d:%02d:%02d ",$year+1900,$mon+1,$mday,$hour,$min,$sec);
    	print "$timestamp- Update.. ";

#load our map file dump entire thing in memory location
my $tdata=""; my $raw_data="";
open(TDATA, $dumpfile) or die "File Error $!";
	while (<TDATA>) {
		$tdata=$_;
		$raw_data = $raw_data . $tdata;
		
 	}
close(TDATA);


#here we generate a passkey to check on the server this mapdata is legitimate
#chr() ord()
#print "Raw: $raw_key\n";

my $encode=$net_name . $raw_key;
my @ascii_codes = unpack("C*", $encode);
#print "Code: @ascii_codes\n";

my $key=scalar(@ascii_codes);
#print "Count: $key\n";

my $code_count=0; my $final_key="";
foreach my $loop (@ascii_codes) {
$ascii_codes[$code_count]*=$key;
$final_key=$final_key.$ascii_codes[$code_count];
$code_count++;
}

#print "$final_key\n";
#print "@ascii_codes\n";

my $word = pack("C*", @ascii_codes);
#$word = pack("C*", 115, 97, 109, 112, 108, 101);   # same
#print "$word\n";


# Prepare our data bundle with the map data and any special info
#   the left of the => symbol and the value on the right.
my %Fields = (
   "network" => $net_name,
   "ID" => $grid_id,
   "MapData" => $raw_data,
   "mode" => "update",
   "key" => $final_key,
);
# As seen above, "@" must be \@ escaped when quoted.


#finalise map update and send it to the galaxy map server

# Create the browser that will post the information.
my $Browser = new LWP::UserAgent;

# Insert the browser name, if specified.
if($BrowserName) { $Browser->agent($BrowserName); }

# Post the information to the CGI program.
my $Page = $Browser->request(POST $URLtoPostTo,\%Fields);

# Print the returned page (or an error message).
#print "Content-type: text/html\n\n";
if ($Page->is_success) { print "Success. \n"; }
else { print $Page->message; }
#if ($Page->is_success) { print $Page->content; }
#else { print $Page->message; }

}

# end of script

