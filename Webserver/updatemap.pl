#!/usr/bin/perl -w
use strict;
use CGI qw(:standard);

#This is a prototype web map editor
#not particularly secure, but should work.
#takes data sent from client, updates index file, and map data for 
#client sector
#id needs to revert to 0 if invalid
#index file should include key (unencrypted), network, grid ID, IP, filename, last updated timestamp ?
#when getting data -
# 1: check key matches network/grid id key and ip - maybe re-multiply key by IP/grid internally as 2nd security check? or just compare?
# 2: if all good write out map file otherwise ignore data or throw an error in response.

#need way to register new networks (networks that are not using defaults auto-add?  but how do we deal with key?)
# mode register perhaps with parms being network/key/id ?

# mode=write or read or blank, read/blank displays only. Default.
# job=something to write, nothing to display only. Default.


my $mode=param('mode');
my $network=param('network');
my $ID=param('ID');
my $key=param('key');
my $MapData=param('MapData');
my $ownpage='http://' . "$ENV{SERVER_NAME}$ENV{SCRIPT_NAME}"; #cgi script running
my $actualpage=$ENV{HTTP_REFERER}; #referer(); 
my $IP=$ENV{REMOTE_ADDR};
my $tdata=" ";
my $page="text";
my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime(time);

# print our header.
print header();
print '<html>';

if (!$mode) { $mode = "read"; }
if (!$MapData) { $mode = "read"; }


print "<b>Debugging 0 info:</b><br><pre>
[$IP] via [$actualpage]. 
Mode requested: [$mode]. 
Docroot: [$ENV{DOCUMENT_ROOT}] 
Pathinfo: [$ENV{PATH_INFO}]
Path translated: [$ENV{PATH_TRANSLATED}]
Server: [$ENV{SERVER_NAME}] 
Script: [$ENV{SCRIPT_NAME}]  
Cgi request: [$ENV{QUERY_STRING}]
My Script: [$ownpage]</pre>";

###########
#need to get out the server port and bond it with the actual IP we got
#split line 1 by , and :, then $ip . $port for steam connect address?
#my $server_address="0.0.0.0";

#remove end of line OS garbage
#$setup_data =~ s/\r|\n//g;
               
#my $net_name=$_[0];
#sample data
#Ramblers Frontier C | Mars Sector | 0.0.0.0:27015 | Ramblers Frontier - Mars Sector. Corporate HQ of the Frontier Trade Network,,,,,,,,,
#Type,Name,X,Y,Z,Size,Speed,VectorX,VectorY,VectorZ

###########



#Lazy way to check file, append a nul to file. This creates if not existing
open(TDATA, ">>$page")  or die "File Error $!";
	print TDATA "";
close(TDATA);

my $timestamp = sprintf("%4d-%02d-%02d %02d:%02d:%02d ",$year+1900,$mon+1,$mday,$hour,$min,$sec);

print $timestamp;

#debugging only here actual data should be confirmed and written to appropriate map index file.

#generate debug output (not used by map just for checking output)
if ($mode eq "update") { 
open(TDATA, ">$page")  or die "File Error $!"; 
        my ($servername, $mapname, $ipport, $description, $mapping)=split(/\|/,$MapData,5); #seperate first 4 fields by | deliminer assign everything else to $mapping#
        my ($localip,$port)=split(/:/,$ipport,2);
        my $steamconnect=join(':',$IP,$port);
        $steamconnect=~ s/ //g; #remove whitepaces
	print TDATA "Last Update: $timestamp\nGameserver: [$steamconnect] \nKey [$key]\nNetwork: $network \nRequests Grid: $ID \nServername: $servername \nMapname: $mapname \nIPPORT: $ipport \nDescription: $description\n";
	#print TDATA "\nData Dump: \n$MapData\n";
	print TDATA "\nMap Dump: \n$mapping\n";
	print TDATA "\n";
 close(TDATA); 
 
 my $livefile="Live.csv";
 open(TDATA, ">$livefile")  or die "File Error $!"; 
	print TDATA $MapData;
	print TDATA "\n";
 close(TDATA); 
 
 }

#what we should be doing here is checking index file grid $ID to see if $key matches THEN updating the appropriate map csv file
#if it is a new server in the group and key is valid attempt to allocate desired Grid id, otherwise (fail) ?  or should i tell pushmap back to update their ID?
#may be better to generate an orphan map index to allow admins to manually assign a grid id?
#the index for $ID should append the $steamconnect info to $key (which itself is generated off physical ip not what pushmap tells us)
#so that even if someone sniffs the key and tries to update THEIR map using it, it will just be ignored as invalid -
#in this way if the key gets accidentally leaked it can't be used to trash an existing servers map; or rogue/idiot admins cant both update the same map sector
#we will also need an additional way to prevent a leaked key being used to fill all the vacant sectors too.. :/
#how about a different key to register a sector from a webpage ? This then gives them the server key to use?

#default universe size 10x10 ? allows up to 100 servers.
#so using my old game RPG engine logic to navigate a cube -
#going DOWN = +100, going up=  -100, going backwards = -10, going forwards = +10, going left = -1, right = +1
#data validation if > 1000, if <0, (ignore) AND we also need to stop people trying to fly off into nulspace eg if someone at the right most side (10/20/30/40/50/60/70/80/90/100) tries to go right (ignore)
#if someone at the back (1-10) tries to go backwards (ignore)  if someone at the front (91-100) tries to go forwards (ignore) if someone on the left (01/11/21/31/41/51/61/71/81/91) (ignore)

print '<p>Messages<br><hr><textarea rows="50" cols="120">';
open(TDATA, $page) or die "File Error $!";
while (<TDATA>) {
	$tdata=$_;
	print "$tdata";
 }
close(TDATA);
print '</textarea></p><hr>End.';

# end of script end the html
print end_html;


#############
#Sub Routines
#############