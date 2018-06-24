#!/usr/bin/perl
# Tool to upload map data from a space engineers dedicated server to a web based galactic map
# and to process any map related tasks the galactic map server responds back with
# Default behavior, upload game state from current folder every 5 minutes
# This script needs to be ran from the same directory as gamestate is saved to.
# Typical location of GameStateData.csv
# eg C:\ProgramData\SpaceEngineersDedicated\Your Map Name\Storage

use strict;
use LWP::UserAgent;
use HTTP::Request::Common;
use Scalar::Util qw(looks_like_number);



my $URLtoPostTo = "http://phoenixx.wox.org/map/updatemap.pl"; # Specify the default URL of the CGI page to post to.
my $dumpfile="GameStateData.csv"; # Specify default name of gamestate file
my $adminsettings="GameSetup.csv"; # Your current settings
my $setup_data="";
my $net_name="";
my $grid_id="";  	 
my $raw_key="";
my $update_timer=""; 
my $startup="1";
my ($commandline) = @ARGV;
my $updatemode="";
my $ok='1';


#  The tools "webbrowser" name, 
my $BrowserName = "Frontier Gateway";


# Command line options

if ($commandline eq "/help") { 
	print "\n$BrowserName map update tool\n\nCommand line options:\n /help = display this screen\n /register = request a new Galaxy region network be created\n /reset = request your current sector be reregistered(eg name change/ip change/new passkey etc)\n\n No command line starts the update agent as normal.";
	print "\n\nPlease make sure your settings in GameSetup.csv file are correct -\nand you have a valid GameStateData.csv file from the steam mod. \n\nFile layout of GameSetup.csv is as follows:\n"; 
	print " Network Name,Grid ID number, passkey, update timer in minutes, Optional CGI URL if not ours\n";
	print "\nExample: A 5 minute update interval, to sector 10 of the DeadSpace Region, passcode gibblets - \n DeadSpace,10,gibblets,5";
	print "\n\nPlease note: GRID id should be unique for each server map; it represents a location\non a cube representing all the sectors. \n/Register option will only work if no existing sector already exists. \n";
	print "/Reset option may require a different passkey";
	

}
else {
	
	print "Beginning $BrowserName agent\n";

	Init_files();

	print ".Reading $adminsettings configuration\n";
	check_setup();

	if ($commandline eq "/register") { 
		print "\nRegister Region requested.\n";
		$updatemode="register";
		sendmap(); 
		
	}
	else { 
		if ($commandline eq "/reset") { 
			print "Reset Credentials requested.\n"; 
			$updatemode="reset";
			sendmap();
		} 
		else { 
			#We start normal operation here # Main program processing loop
			my $sleeptime=60*$update_timer;
			$updatemode="update"; # set to normal update mode
			print "\nSystem Initialised.. Triggering First Galaxy Update\n"; sendmap();
			print "\nSystem Operational. Updating every $update_timer Minutes. Press Ctrl-C to terminate.\n";


			#designed to run /persistently/ until terminated by kill or ctrl-c
	

			while ($ok) {
				sleep $sleeptime;  	#wait number of minutes until next update
				Init_files();		#check the datafiles 
				check_setup();		#make sure the setup didn't change
				sendmap();		#update the universe map
			}
		}
	}
}

################
# Sub routines #
################


sub Init_files {
	#Lazy way to check files, append a nul to file. This creates if not existing
	if ($startup) { print ".Checking/Creating $adminsettings file\n"; }
	open(TDATA, ">>$adminsettings")  or die "File Error $!";;
		print TDATA "";
	close(TDATA);

	if ($startup) { print ".Checking/Creating $dumpfile file\n"; }
	open(TDATA, ">>$dumpfile")  or die "File Error $!";;
		print TDATA "";
	close(TDATA);
	if ($startup) { $startup = "0"; }
}


sub check_setup(){

	#load our setup file into memory

	open(TDATA, $adminsettings) or die "File Error $!";
		$setup_data=<TDATA>;
	close(TDATA);

	if (!$setup_data) { 
		print ".No Configuration in $adminsettings file - creating default placeholders\n";
		print "Please note you should edit '$adminsettings'  to correctly configure your Space sector.\n"; 
		print "This tool needs to be ran from your maps STORAGE folder and/or where \n";
		print "the $dumpfile is being created.\n";
		$setup_data='Netw0rk_Name,Requested Grid ID #,passkey,update time in minutes'; 
		open(TDATA, ">>$adminsettings")  or die "File Error $!";
			print TDATA $setup_data;
		close(TDATA);
	}

	#GameSetup.csv
	#Network Name,Requested Grid ID #, passkey, update timer, Optional URL if not ours


	#remove end of line OS garbage
	$setup_data =~ s/\r|\n//g;

	my @temp=split(/,/,$setup_data); #seperate by , deliminer#
               
 	$net_name=$temp[0];
 	$grid_id= $temp[1];  	if (looks_like_number($grid_id))  {} else { $grid_id=0; } 
 	$raw_key= $temp[2];
 	$update_timer=$temp[3]; 	if (looks_like_number($update_timer))  {} else { $update_timer=5; }
	if ($temp[4]) { $URLtoPostTo = $temp[4]; }
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


	#here we generate a non-reversable reproducable passkey to check on the server this mapdata is legitimate
	#this also allows us to conceal the passkey server side at a late time
	#chr() ord() 	#print "Raw: $raw_key\n";

	my $encode=$net_name . $raw_key;
	my @ascii_codes = unpack("C*", $encode);
	#print "\nEncode: $encode\n"; #print "Code: @ascii_codes\n";

	my $key=scalar(@ascii_codes); #print "keycount: $key\n";
	$key*=1.1415; #print "Scramblekey: $key\n";

	my $code_count=0; my $final_key=""; my $key_filter="";
	foreach my $loop (@ascii_codes) {

		#lets scramble it 
		$key_filter= $ascii_codes[$code_count]*=$key; 

		#lets drop the decimal, and reduce it to a semi random integer number of managable size further scrambling it
		$key_filter=~ s/\.//; $key_filter*=0.000128; $key_filter=int($key_filter); 

		#lets build our irreversable key off it
		$final_key=$final_key . $key_filter; # $ascii_codes[$code_count];
		$code_count++;
	}

	#print "Final Key: $final_key\n"; #print "Ascii style: @ascii_codes\n";
	#my $word = pack("C*", @ascii_codes);
	#$word = pack("C*", 115, 97, 109, 112, 108, 101);   # same
	#print "$word\n";


	# Prepare our data bundle with the map data and any special info
	#   the left of the => symbol and the value on the right.

	my %Fields = (
   		"network" => $net_name,
   		"ID" => $grid_id,
   		"MapData" => $raw_data,
   		"mode" => $updatemode,
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
	if ($Page->is_success) { print "Success. "; }
	else { print $Page->message . "\n"; }
	#if ($Page->is_success) { print $Page->content; }
	#else { print $Page->message; }

	#Anything the galaxy needs us to do?
	print " Work Queued?.. ";
	my $reply = $Page->content; #print $reply;
	if (!$reply) { print "No.\n"; }
	else { 	print "Yes.. \n"; 
	
		#here we detect if we need to register, update location, network or spawn a ship etc
       		my ($task, $details)=split(/\|/,$reply,2); 
		if ($task eq "fail") {
			$ok='';
			print "\n\nRequest Failed - ";
			
			my ($reason, $network, $sectorID, $steamconnect, $servername, $mapname)=split(/\|/,$details,6);
			print "$reason\nPlease check settings\n\nRegion: $network Network, Sector/Grid ID: $sectorID\nSector: $servername - $mapname\nJump Address: $steamconnect\n";
		}
		if ($task eq "register") { 
			print "\nRegister request accepted - Please note following details: \n$details";
		}
		if ($task eq "reset") {
			my ($network, $sectorID, $steamconnect)=split(/\|/,$details,3);
			print "\nReset request accepted - This instance authorised to update:\n $network Region, Sector/Grid ID: $sectorID at $steamconnect\n\n";
		}
	}

}

# end of script

