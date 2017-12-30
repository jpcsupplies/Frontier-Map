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


print "<b>Debugging info:</b><br><pre>
[$IP] via [$actualpage]. 
Mode requested: [$mode]. 
Docroot: [$ENV{DOCUMENT_ROOT}] 
Pathinfo: [$ENV{PATH_INFO}]
Path translated: [$ENV{PATH_TRANSLATED}]
Server: [$ENV{SERVER_NAME}] 
Script: [$ENV{SCRIPT_NAME}]  
Cgi request: [$ENV{QUERY_STRING}]
My Script: [$ownpage]</pre>";


#Lazy way to check file, append a nul to file. This creates if not existing
open(TDATA, ">>$page")  or die "File Error $!";
	print TDATA "";
close(TDATA);

my $timestamp = sprintf("%4d-%02d-%02d %02d:%02d:%02d ",$year+1900,$mon+1,$mday,$hour,$min,$sec);

print $timestamp;

#debugging only actual data should be confirmed and written to appropriate data file.
if ($mode eq "update") { 
open(TDATA, ">$page")  or die "File Error $!"; 
	print TDATA "Last Update: $timestamp\nSource: [$IP] \nKey [$key]\nNetwork: $network: Requests Grid $ID Data Dump: \n$MapData\n";
	print TDATA "\n";
 close(TDATA); 
 
 my $livefile="Live.csv";
 open(TDATA, ">$livefile")  or die "File Error $!"; 
	print TDATA $MapData;
	print TDATA "\n";
 close(TDATA); 
 
 }


#text
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