#!/usr/bin/perl -w
use strict;
use CGI qw(:standard);

#This is a prototype web map editor
#not particularly secure, but should work.

# mode=write or read or blank, read/blank displays only. Default.
# job=something to write, nothing to display only. Default.
# player=player
# allience=alliance
# tile=item for that tile|level|owner|Alliance|comment
#eg P|0|Bob|Bobs alliance|bob is bobish
#or C|2|Bob|Bobs alliance|no defenders!
#	N=for nothing/unknown, Default


# WebGL render variiables
my $mode=param('mode');
my $render=param('render');
my $header="header.txt";
my $footer="footer.txt";
my $dumpfilen='GameStateData.csv';
my $xCam=param('xCam'); #desired camera position
my $yCam=param('yCam');
my $zCam=param('zCam');
my $xOff=0; my $yOff=0; my $zOff=0; #offset for sector
my $sSize=1500000/2; #sector size 1500000-2000000
my $scalefactor=20; #how much to shrink world data down eg/10
my $httpOptions='';
my $nav=param('nav');
my $hexcode="0x5b969";
#{SName} | {SWorld} | {Sconnect} | {SDescription},,,,,,,,,"


#for security checks etc 
my $ownpage='http://' . "$ENV{SERVER_NAME}$ENV{SCRIPT_NAME}"; #cgi script running
my $actualpage=$ENV{HTTP_REFERER}; #referer(); 
my $IP=$ENV{REMOTE_ADDR};   ## we need to use this to reconcile with a given server in the sector list file as well as a security code?

# data dump variables
my $plane=param('plane');
my $increment=param('increment');
my $scale=param('scale');
my $flat=param('flat');

# Older test Map variables
my $mapfile='map.INI';
my $xt=param('x'); my $yt=param('y');
my $tileitem=param('tile');
my $level=param('level');
my $player=param('owner');
my $alliance=param('alliance');
my $comment=param('comment');
my $html=param('html');
my $state=param('state');
my $overx=param('overx');
my $overy=param('overy');



# print our header.
print header();
print '<html>';
print '<head><title>Sector Map</title><style>canvas { width: 80%; height: 80% }</style></head>  <body>';

#set defaults
if (!$actualpage) { $actualpage=$ownpage; }
if (!$mode) { $mode = "read"; }
if (!$render) { $render = "read"; }
if (!$level) { $level="0"; }
if (!$tileitem) { $tileitem="N"; }
if (!$player) { $player="Unknown/None"; }
if (!$alliance) { $alliance="Unknown/None"; }
if (!$comment) { $comment="None"; }
if (!$plane) { $plane='0'; }
if ($increment eq 'yes') { if ($plane>=100) { $plane='0'; } else { $plane++; } }
if (!$scale) { $scale=1000000; } 
if (!$flat) { $flat='no'; } 
if (!$xCam) { $xCam=0; }
if (!$yCam) { $yCam=0; }
if (!$zCam) { $zCam=0; }
if ($nav eq 'left') { $xCam+=1; }
if ($nav eq 'right') { $xCam-=1; }
if ($nav eq 'up') { $yCam-=1; }
if ($nav eq 'down') { $yCam+=1; }
if ($nav eq 'near') { $zCam-=1; }
if ($nav eq 'away') { $zCam+=1; }
if ($nav eq 'reset') { $xCam=0; $yCam=0; $zCam=0; }

if ($render ne "webGL") { print '<b>Perl Map Tool</b>'; readtheme($header); }

if ($render eq "test") {
	&load($mapfile,$xt,$yt,$tileitem,$level,$player,$alliance,$comment); 
	&render($mapfile, $mode, $xt, $yt, $tileitem, $level, $player, $alliance, $comment ) ;
}
if ($render eq "dump") { readdump($dumpfilen,$plane,$scale,$flat); }

$httpOptions="&zCam=$zCam&yCam=$yCam&xCam=$xCam";  #!!! NEEDED TO REMEMBER CAMERA/SECTOR FOCUS POINT!

if ($render eq "read") { 
	print '<iframe src="map.pl?render=webGL'.$httpOptions.'" style="width: 100%; height: 100%" name="internal" marginwidth="0" marginheight="0" frameborder="0" vspace="0" hspace="0"></iframe>'; 
	

} 

if ($render eq "webGL") { 
# stuff in here is meant to scan over a loop reading in multiple files

#step 1 draw out the entire 10x10 sector boundries - current is set green
#step 2 read in the master file to fill in the points of interest (clickabble tags would be nice)
#step 3 currently selected sector has is details() read and stored for the info panel to display - this is found by searching master file for the x,y,z of current and 
#loading that file

# three.js/webgl graphics header
	initwebGL(); 	
		
# set our focused sector		
	$xOff+=$xCam;	
	$yOff+=$yCam;	
	$zOff+=$zCam;	
	
my $masterx=$xOff;
my $mastery=$yOff;
my $masterz=$zOff;

	#generate 3d array 10x10x10 cube  0=-5 / 10=5
	my $sx=0; my $sy=0; my $sz=0;
	my $endx=$xOff+4; my $endy=$yOff+4; my $endz=$zOff+4;
	for $sz ($zOff..$endz) {
		for $sy ($yOff..$endy) {
			for $sx ($xOff..$endx) {
					if ($xOff==0 && $yOff==0 && $zOff==0) { $hexcode="0x5b969"; } else {  $hexcode="0xfffff"; }
					#$xOff=$sx-5; $yOff=$sy-5; $zOff=$sz-5;
					#sector($sx*$sSize,$sy*$sSize,$sz*$sSize,$sSize,$hexcode); 
					
			}
		}
	}
	#$hexcode="0xfffff";
	#sector(-5*$sSize,-5*$sSize,-5*$sSize,$sSize*10,$hexcode);
	$xOff=$masterx; $yOff=$mastery; $zOff=$masterz;

	
	# also need to pull the sector info here to populate the nav window? or build some hash table and do a lookup
	# on the target sector coords while drawing them
	if ($xOff==0 && $yOff==0 && $zOff==0) { $hexcode="0x5b969"; } else {  $hexcode="0xfffff"; }
		
	sector($xOff*$sSize,$yOff*$sSize,$zOff*$sSize,$sSize,$hexcode); 
	showsector($dumpfilen,$xOff*$sSize,$yOff*$sSize,$zOff*$sSize); 
	
	$xOff-=1;
	
	if ($xOff==0 && $yOff==0 && $zOff==0) { $hexcode="0x5b969"; } else {  $hexcode="0xfffff"; }
	
	sector($xOff*$sSize,$yOff*$sSize,$zOff*$sSize,$sSize,$hexcode); 
	showsector('GameStateData1.csv',$xOff*$sSize,$yOff*$sSize,$zOff*$sSize); 
	
	$xOff+=1;
	
	if ($xOff==0 && $yOff==0 && $zOff==0) { $hexcode="0x5b969"; } else {  $hexcode="0xfffff"; }
	
	sector($xOff*$sSize,$yOff*$sSize,$zOff*$sSize,$sSize,$hexcode); 
	showsector('GameStateData3.csv',$xOff*$sSize,$yOff*$sSize,$zOff*$sSize); 
	
	 $xOff+=1; #$yOff+=1;
	
	if ($xOff==0 && $yOff==0 && $zOff==0) { $hexcode="0x5b969"; } else {  $hexcode="0xfffff"; }
	
	sector($xOff*$sSize,$yOff*$sSize,$zOff*$sSize,$sSize,$hexcode); 
	showsector('GameStateData2.csv',$xOff*$sSize,$yOff*$sSize,$zOff*$sSize); 
	
	 $xOff+=1; #$zOff-=1; #$yOff-=1;
	#
	if ($xOff==0 && $yOff==0 && $zOff==0) { $hexcode="0x5b969"; } else {  $hexcode="0xfffff"; }
	
	sector($xOff*$sSize,$yOff*$sSize,$zOff*$sSize,$sSize,$hexcode); 
	showsector('GameStateData4.csv',$xOff*$sSize,$yOff*$sSize,$zOff*$sSize); 
	
	$xOff+=1;
	if ($xOff==0 && $yOff==0 && $zOff==0) { $hexcode="0x5b969"; } else {  $hexcode="0xfffff"; }
	
	sector($xOff*$sSize,$yOff*$sSize,$zOff*$sSize,$sSize,$hexcode); 
	showsector('GameStateData5.csv',$xOff*$sSize,$yOff*$sSize,$zOff*$sSize); 
	
		$xOff+=1;
	if ($xOff==0 && $yOff==0 && $zOff==0) { $hexcode="0x5b969"; } else {  $hexcode="0xfffff"; }
	
	sector($xOff*$sSize,$yOff*$sSize,$zOff*$sSize,$sSize,$hexcode); 
	showsector('Live.csv',$xOff*$sSize,$yOff*$sSize,$zOff*$sSize); 
	
	
	addcameracontrol(); }
if ($render ne "webGL") { 
#generate navigation menu

	# we should have sector id here: $xCam;	$yCam;	$zCam;	

print '
<td width=300>
<p><font color="Blue" size=+2><strong>Astrogation Control</strong></font></p>
<center>
<a href="map.pl?render=read&nav=away'.$httpOptions.'" ><img src="away.gif" title="Move In"></a><a href="map.pl?render=read&nav=up'.$httpOptions.'"><img src="up.gif" title="Move Up"></a><br>
<a href="map.pl?render=read&nav=left'.$httpOptions.'"><img src="left.gif" title="Move Left"></a><a href="map.pl?render=read&nav=reset'.$httpOptions.'"> <img src="reset.gif" title="Reset Position"></a><a href="map.pl?render=read&nav=right'.$httpOptions.'"><img src="right.gif" title="Move Right"></a><br>
<a href="map.pl?render=read&nav=near'.$httpOptions.'"><img src="near.gif" title="Move Out"></a><a href="map.pl?render=read&nav=down'.$httpOptions.'"><img src="down.gif" title="Move Down"></a><br>';

print '<font color="red">'."Target Sector:  X $xCam Y $yCam Z $zCam" .'</center><br></font><font color="white"> <b>Key</b><br><font color="Yellow">Yellow:</font> Station<br><font color="Red">Red:</font> Large Grid Ship<br><font color="Orange">Orange:</font> Smallish Ship<br><font color="Blue">Blue:</font> Planet/Moon<br><font color="Grey">Grey:</font> Asteroid<br><font color="Pink">Pinkish/Purple:</font> Character<br><font color="Green">Green:</font> Focused Sector</font></font></td>';
readtheme($footer); 
}

	
if ($render eq "read"){	
	detail('GameStateData.csv');
	detail('GameStateData1.csv');
	detail('GameStateData2.csv');
	detail('GameStateData3.csv');
	detail('GameStateData4.csv');	
	detail('GameStateData5.csv');
	detail('Live.csv');
}

#Debug info uncomment as needed
#print "<br><b>Debugging info:</b><br>
#[$IP] via [$actualpage]. 
#<br><b>Mode requested:</b> [$mode]. <br>
#<b>Docroot: </b>[$ENV{DOCUMENT_ROOT}] <b>Pathinfo:</b> [$ENV{PATH_INFO}]
#<b>Path translated:</b> [$ENV{PATH_TRANSLATED}]<br>
#<b>Server:</b> [$ENV{SERVER_NAME}] <b>Script: </b>[$ENV{SCRIPT_NAME}]  <br>
#<b>Cgi request: </b>[$ENV{QUERY_STRING}]<br><b>My Script:</b> [$ownpage]";
#print "<br>Extra debug info: $tileitem<br>";

# &error(1)
# end of script end the html
print end_html;


#############
#Sub Routines
#############

###########
# read header or footer or other theme related file and insert into page
##########
sub readtheme {
	my $page=$_[0];
	my $tdata=" ";

	#Lazy way to check file, append a nul to file. This creates if not existing
	open(TDATA, ">>$page")  or die "File Error $!";
		print TDATA "";
	close(TDATA);

	#read file
	open(TDATA, $page) or die "File Error $!";
	while (<TDATA>) {
		$tdata=$_;
		print "$tdata";
 	}
	close(TDATA);
}


sub initwebGL {

#initialise WebGL in three.js
print '

      <script src="js/three.min.js"></script>
      <script src="js/TrackballControls.js"></script>
      <script>
        var scene = new THREE.Scene();
              
        //create camera POV VIEW_ANGLE, ASPECT(width/height), NEAR, FAR
        var camera = new THREE.PerspectiveCamera(50,window.innerWidth/window.innerHeight, 1,10000000);
     
        var renderer = new THREE.WebGLRenderer();
                
	renderer.setSize(window.innerWidth, window.innerHeight);
	document.body.appendChild(renderer.domElement);';
}	

#draws thw cube around the sector
sub sector {
my $x=0; my $y=0; my $z=0; my $w=0;
if (!$_[0]) { $x=0; } else {  $x=$_[0]; }
if (!$_[1]) { $y=0; } else {  $y=$_[1]; }
if (!$_[2]) { $z=0; } else {  $z=$_[2]; }
if (!$_[3]) { $w=$sSize; } else {  $w=$_[3]; } # this figure halved is world size limit? as world size contains -100 + 0 + 100 = 200
my $hexcode=$_[4];


# this will be used to mark out claimed regions or to generate multiple sectors on screen
print '	//create 3d cube  x,y,z,segmented faces, segmented faces, segmented faces eg 10
	var geometry = new THREE.BoxGeometry('."$w, $w, $w,".' 1, -1, 1);
	
	//MeshBasicMaterial whats it made of eg MeshBasicMaterial color 0x5b969 0xfffff etc
	var material = new THREE.MeshBasicMaterial({color: '.$hexcode.', wireframe: true});

	
	//geometry / object
	var cube = new THREE.Mesh(geometry, material);
	cube.position.set('."$x, $y, $z".');
	
	//add object to scene
	scene.add(cube);
	
	

';

}


sub addplanet {
# addplanet($sizeclass, $x, $y, $z);
# this will need a size, position and color variable

my $size=$_[0];
if (!$size) { $size=10; } else { $size+=2; }
if (!$_[1]) { $_[1]=-2; } 
if (!$_[2]) { $_[2]=0; }
if (!$_[3]) { $_[3]=0; }

print '	var spheregeometry = new THREE.SphereGeometry('."$size".', 15, 15);
	var spherematerial = new THREE.MeshBasicMaterial({wireframe: true, color: 0xf3fff});';

print '	var sphere = new THREE.Mesh(spheregeometry, spherematerial);';

print "
sphere.position.x = $_[1];
sphere.position.y = $_[2];
sphere.position.z = $_[3];
sphere.updateMatrix();
sphere.matrixAutoUpdate = false;";

#print "sphere.position.set($_[1],$_[2],$_[3]);";
 
print 'scene.add(sphere);';
}

###############
# Adds point of interest asteroid, ship, player etc
#	//now random crap yellow=FFF00 grey = #959696  greenish=0x5b969 darkish grey 5b5c5b
#	//green #46ff3c orangish #ff8c19  white ffffff  decent blue 0xf3fff bloody red c91700
#	//purplish pink #cc39af
###############
sub addobject {
#addobject("Ship/Station/Player/Asteroid", $sizeclass, $x, $y, $z);
#this will require color, size, position and/or type and/or direction
my $typeclass=$_[0];
my $sizeclass=$_[1];
my $colorcode="0xffffff"; 

if (!$_[2]) { $_[2]=50; } #x
if (!$_[3]) { $_[3]=50; } #y
if (!$_[4]) { $_[4]=50; } #z

my $x=int($_[2]+0.5);
my $y=int($_[3]+0.5);
my $z=int($_[4]+0.5);

#move objects outside of cube to nearest wall
#if ($x>250000) { $x=250000; }
#if ($y>250000) { $y=250000; }
#if ($z>250000) { $z=250000; }
#if ($x<-250000) { $x=-250000; }
#if ($y<-250000) { $y=-250000; }
#if ($z<-250000) { $z=-250000; }

if (!$typeclass) { $typeclass="Random"; } #make something up (demo mode)
if (!$sizeclass) { $sizeclass=1; } #size

if ($typeclass eq "LargeShip") { $colorcode="0xc91700"; } #red
if ($typeclass eq "Station") { $colorcode="0xFFF00"; } #yellow
if ($typeclass eq "Player") { $colorcode="0xcc39af"; } # purple/pink
if ($typeclass eq "Asteroid") { $colorcode="0x5b5c5b"; } # grey
if ($typeclass eq "SmallShip") { $colorcode="0xff8c19"; } #orange

if ($typeclass eq "Station") {  
	print "	var geometry = new THREE.CylinderGeometry($sizeclass,$sizeclass, $sizeclass*2);"; 
	#print "	var geometry = new THREE.OctahedronGeometry($sizeclass, 0);"; 
	#print ' var textureLoader=new THREE.TextureLoader();';
	#print ' var texture = textureLoader.load("blob.gif");';
	#print '	var material = new THREE.MeshPhongMaterial({map: texture, transparent: true, opacity: 1, color: '."$colorcode".'}); 
	#	var mesh = new THREE.Mesh( geometry, material );';		
	print '	var material = new THREE.MeshBasicMaterial({wireframe: true, color: '."$colorcode".'}); 
		var mesh = new THREE.Mesh( geometry, material );';	
} 
else { 
	if ($typeclass eq "LargeShip" || $typeclass eq "SmallShip") {  
		print "	var geometry = new THREE.TetrahedronGeometry($sizeclass, 0);"; 
		print '	var material = new THREE.MeshBasicMaterial({wireframe: true, color: '."$colorcode".'}); 
			var mesh = new THREE.Mesh( geometry, material );'; 
	} else 	{ 
		print "	var geometry = new THREE.SphereGeometry($sizeclass, 4, 4);"; 
		print '	var material = new THREE.MeshBasicMaterial({wireframe: true, color: '."$colorcode".'}); 
			var mesh = new THREE.Mesh( geometry, material );'; 
		} 
     }

	
if ($typeclass eq "Random") {
print '	mesh.position.x = ( Math.random() - 0.5 ) * 1000;
	mesh.position.y = ( Math.random() - 0.5 ) * 1000;
	mesh.position.z = ( Math.random() - 0.5 ) * 1000;';
	} else {
print  "mesh.position.x = $x;
	mesh.position.y = $y;
	mesh.position.z = $z;";
	}

print '	mesh.updateMatrix();
	mesh.matrixAutoUpdate = false;
	scene.add( mesh );
	';
}

###############
# this links the controls and camera position, and starts display of map
###############
sub addcameracontrol {


print '
	//controls?
	controls = new THREE.TrackballControls( camera );
	controls.rotateSpeed = 1.0;
	controls.zoomSpeed = 0.8;
	controls.panSpeed = 0.7;

	controls.noZoom = false;
	controls.noPan = false;

	controls.staticMoving = true;
	controls.dynamicDampingFactor = 0.3;
	//controls.keys = [ 65, 83, 68 ];
	
	//make sure camera is outside of scene effectively our scale
	
	camera.position.x = 0;
	camera.position.y = 0;
	camera.position.z = 4800000;
	//camera.setViewOffset (1, 1, 0, 2, 1, 1 );
	
	//render loop
	function render() {
   		requestAnimationFrame(render);
   		//rotate it
   		//cube.rotation.x += 0.01;
		//cube.rotation.y += 0.01;
		//cube.rotation.z += 0.01;
		
		//sphere.rotation.y += 0.03;
		//mesh.rotation.y += 0.03;
		controls.update();
   		renderer.render(scene, camera);
	}
	
	//actually put it on screen
	render();
      </script>
      ';
}
######################
# Somehow Generate a list of all the sectors details sorted by x y z
# Data format $x | $y | $z | server | map | ip/id | Long Description ||
# line 1 = Server Name | Server World | 0.0.0.0:00000 | This is an offline map,,,,,,,,,
# desired parameters = x y z,   current parameters = filename
###################### 
sub detail {

my $dumpfile="$_[0]"; #filename fed from main program#
my $cur_line="";
my @temp;
#my @details;
my $objecttype=''; #Player/Station/Ship/Planet/Asteroid
my $objectname=''; #grid or filename or nickname
#my $x=0; my $y=0; my $z=0;  #location in 3d space 0,0,0 = middle of cube
my $objectsize=''; 
my $objectspeed='';
my $smallgrids=0;
my $planets=0;
my $asteroids=0;
my $largeships=0;
my $characters=0;
my $stations=0;
my $line=0;
my $servername='';
my $worldname='';
my $serverip='';
my $serverdetail='';

	#load our map file dump entire thing in memory
	open(TDATA, $dumpfile) or die "File Error $!";
		my @raw_data=<TDATA>;
	close(TDATA);

#print 'Data loaded ';
	#roll through file and load in map array, this only loads what is in file so no errors hopefully.
	foreach $cur_line (@raw_data)
	{

		#chomp($cur_line); 
		#do a super chomp to kill any end of line rubbish
    		$cur_line =~ s/\r|\n//g;

		@temp=split(/,/,$cur_line); #seperate by , deliminer#
               
              	$objecttype=$temp[0];
              	$objectname=$temp[1]; 
              	$objectsize=$temp[5];
              	$objectspeed=$temp[6];
              	        	
              	if ($line == 0) { 
      			my @details=split/\|/,$temp[0];
			$servername=$details[0];
			$worldname=$details[1];
			$serverip=$details[2];
			$serverdetail=$details[3];
			$serverdetail=~ s/,,,,,,,,,//; #remove all trailing commas
			
		  }              	
                     	
              	#insert known objects into the array
		if ($objecttype eq 'SmallShip') { $smallgrids++; } #small grid ship
		if ($objecttype eq 'Planet') {  $planets++; } #Planet				
		if ($objecttype eq 'Asteroid') {  $asteroids++; } #asteroid
		if ($objecttype eq 'LargeShip') {  $largeships++; } #large grid ship
		if ($objecttype eq 'Player') { $characters++ } # Character/Player
		if ($objecttype eq 'Station') { $stations++; } # Station
		$line++;
	}

print '<br> ';
	
print '<b>Sector Summary:</b> <br>';
print "<b>Region:</b> $servername. <b>Sector:</b> $worldname. <p><b>Description:</b> $serverdetail. <strong><a href=\"steam://connect/$serverip\">[ [ Plot Course ] ]</a></strong>";

#steam://connect/221.121.159.238:27270
print '</p><b>Intelligence report:</b><br>
<img src="orangex.gif"> Detected Small Ships '.$smallgrids.'<br>';  		#small grid ship
print '<img src="planetbl.gif"> Detected Planets '.$planets.'<br>'; 		#Planet				
print '<img src="roid.gif"> Known Asteroids '.$asteroids.'<br>';  		#asteroid
print '<img src="redx.gif"> Detected Large Ships '.$largeships.'<br>';  	#large grid ship
print '<img src="char.gif"> Active Operators '.$characters.'<br>';  		# Character/Player
print '<img src="blob.gif"> Detected Stations '.$stations.'<br><hr>';  		# Station


 }

######################
# Load our data into the webGL sector map and display it
######################
sub showsector { 

	# generate three.js init
	# load data
	# detect type and generate three.js objects
	# trigger render loop

	my $dumpfile="$_[0]"; #filename fed from main program#
	my $xOffset=0; my $yOffset=0; my $zOffset=0;
	my $cur_line="";
	my @temp;
	my $objecttype=''; #Player/Station/Ship/Planet/Asteroid
	my $objectname=''; #grid or filename or nickname
	my $x=0; my $y=0; my $z=0;  #location in 3d space 0,0,0 = middle of cube
	my $objectsize=''; 
	my $objectspeed='';
	my $vX=0; my $vY=0; my $vZ=0;
 	my $sizeclass=0;
 	

	if ($_[1]!=0) { $xOffset=$_[1]; } 
	if ($_[2]!=0) { $yOffset=$_[2]; } 
	if ($_[3]!=0) { $zOffset=$_[3]; } 

	#load our  file dump entire thing in memory
	open(TDATA, $dumpfile) or die "File Error $!";
		my @raw_data=<TDATA>;
	close(TDATA);
	#print 'Data loaded ';
	
	#roll through file and generate code for points of interest
	foreach $cur_line (@raw_data)
	{
		#chomp($cur_line); 
		#do a super chomp to kill any end of line rubbish
   		$cur_line =~ s/\r|\n//g;
    		$cur_line =~ s/\r|\n//g;
    		$cur_line =~ s/\r|\n//g;

		@temp=split(/,/,$cur_line); #seperate by , deliminer#
		
                #format Type,Name,X,Y,Z,Size,Speed,VectorX,VectorY,VectorZ
              	$objecttype=$temp[0];
              	$objectname=$temp[1];     	
             	$x=($temp[2]/$scalefactor)+$xOffset; $y=($temp[3]/$scalefactor)+$yOffset; $z=($temp[4]/$scalefactor)+$zOffset;
             	$objectsize=$temp[5];
              	$objectspeed=$temp[6];
              	$vX=$temp[7]; $vY=$temp[8]; $vZ=$temp[9];
             	
             	# size reference: 	Planets ~> 19000 
             	#			Asteroids 64-128-256-512 
             	#			Large Ships 0.75 - 8 -(30+)  -160 -  245  
             	#			stations 12- 264 
             	#			player 1.8 
             	#			small ships 0.75 - 1.08-  1.25 - 2.25 - 2.41- 2.91- 3- 3.16 - 4.3-(10 or less) max 35
             	
             	#large grid ship red
             	if ($objecttype eq 'LargeShip') { 
             		
             		if ($objectsize>=1) { $sizeclass=2; }
             		if ($objectsize>=10) { $sizeclass=4; } #tiny
             		if ($objectsize>=50) { $sizeclass=8; } #trader
             		if ($objectsize>=80) { $sizeclass=11; } #transport
             		if ($objectsize>=100) { $sizeclass=16; } 
             		if ($objectsize>=150) { $sizeclass=19; } #battleship
             		if ($objectsize>=200) { $sizeclass=24; } 
             		if ($objectsize>=240) { $sizeclass=30; } #thats no moon big scary red dot
             		    		
             		addobject("LargeShip", $sizeclass, $x, $y, $z);
             	} 
             	
             	#smallgrid ship orange
             	if ($objecttype eq 'SmallShip') { 
             		#print "// !debug $objectsize";
             		if ($objectsize<1) { $sizeclass=1; }
             		if ($objectsize>=1) { $sizeclass=1; }
             		if ($objectsize>=10) { $sizeclass=3; } #tiny orange dots
             		if ($objectsize>=50) { $sizeclass=4; } #trader
             		if ($objectsize>=80) { $sizeclass=5; } #transport
             		if ($objectsize>=100) { $sizeclass=7; } 
             		if ($objectsize>=150) { $sizeclass=8; } #battleship
             		if ($objectsize>=200) { $sizeclass=9; } 
             		if ($objectsize>=240) { $sizeclass=10; } #thats no moon big scary dot
             		    		
             		addobject("SmallShip", $sizeclass, $x, $y, $z);
             	} 
             	
             	#station yellow
             	if ($objecttype eq 'Station') { 
             		if ($objectsize>=1) { $sizeclass=2; }
             		if ($objectsize>=25) { $sizeclass=3; }
             		if ($objectsize>=50) { $sizeclass=6; } 
             		if ($objectsize>=100) { $sizeclass=12; } 
             		if ($objectsize>=200) { $sizeclass=25; } 
             		if ($objectsize>=400) { $sizeclass=40; } 
             		    		
             		addobject("Station", $sizeclass, $x, $y, $z);
             	
             	 } # Station
             	
             	#Planet blue dot
             	if ($objecttype eq 'Planet') { $sizeclass=$objectsize/($scalefactor*2.04); addplanet($sizeclass, $x, $y, $z); } 	#/20.3 @ scale factor 10 is correct
             	
             	#asteroid
             	if ($objecttype eq 'Asteroid') { 
             		
             		if ($objectsize<=127) { $sizeclass=11; } 
             		if ($objectsize>=128) { $sizeclass=14; }
             		if ($objectsize>=256) { $sizeclass=24; }
             		if ($objectsize>=512) { $sizeclass=48; } 
             		if ($objectsize>=700) { $sizeclass=68; } 
             		addobject("Asteroid", $sizeclass, $x, $y, $z);
             	 } 
             	
            	if ($objecttype eq 'Player') { addobject("Player", 10, $x, $y, $z); } # Character/Player
            	          
	}

}



###################
#process a DS dump file - this is intended on getting form data from a DS to integrate it into the map file.
#Currently it is just attempting to read the specified csv file and load into a comma delimited array
#format Type,Name,X,Y,Z,Size,Speed,VectorX,VectorY,VectorZ
#assume a 10000km x 10000km x 10000km world
#align positions to fit a 100x100 grid 0=50  -10000=0 10000=100 etc. 
###################
sub readdump {
my $dumpfile="$_[0]"; #filename fed from main program#
my $cur_line="";
my @temp;
my @map;
my $objecttype=''; #Player/Station/Ship/Planet/Asteroid
my $objectname=''; #grid or filename or nickname
my $x=0; my $y=0; my $z=0;  #location in 3d space 0,0,0 = middle of cube
my $objectsize=''; 
my $objectspeed='';
my $vX=0; my $vY=0; my $vZ=0;
my $plane="$_[1]"; 
my $scale=$_[2];  # Distance to examine in detail ie. how much distance across is represented in the map
my $flat=$_[3]; # shall we collapse the Z scale into 2D
my $checked=' ';
my $emptyspace=1000000;
my $smallgrids=0;
my $planets=0;
my $asteroids=0;
my $largeships=0;
my $characters=0;
my $stations=0;




if ($flat eq 'yes') { $checked='checked="checked"'; } 

print " $dumpfile";

	#generate 3d array 100x100x100 cube
	my $ax=0; my $ay=0; my $az=0;
	for $az (0..100) {
		for $ay (0..100) {
			for $ax (0..100) {
				if (!$map[$ax][$ay][$az]) { $map[$ax][$ay][$az]="N"; }#\|fill empty fields
			}
		}
	}
	
#print ' Array built ';

	#load our map file dump entire thing in memory
	open(TDATA, $dumpfile) or die "File Error $!";
		my @raw_data=<TDATA>;
	close(TDATA);
	
#print 'Data loaded ';
	#roll through file and load in map array, this only loads what is in file so no errors hopefully.
	foreach $cur_line (@raw_data)
	{
		#chomp($cur_line); 
		#do a super chomp to kill any end of line rubbish
   		$cur_line =~ s/\r|\n//g;
    		$cur_line =~ s/\r|\n//g;
    		$cur_line =~ s/\r|\n//g;

		@temp=split(/,/,$cur_line); #seperate by , deliminer#
               
              	$objecttype=$temp[0];
              	$objectname=$temp[1]; 
              	#translate coords into 100x100 point of reference
             	$x=int((($temp[2]+$scale)/($scale/50))+0.5); $y=int((($temp[3]+$scale)/($scale/50))+0.5); $z=int((($temp[4]+$scale)/($scale/50))+0.5);
             	#bounds correction for oddly distant objects move them to applicable edge of map
             	if($x>100) { $x=100; } if($x<0) { $x=0; }
             	if($y>100) { $y=100; } if($y<0) { $y=0; }
             	if(($z<0) || ($flat eq "yes")) { $z=0; } else { if($z>100) { $z=100; } }
              	$objectsize=$temp[5];
              	$objectspeed=$temp[6];
              	$vX=$temp[7]; $vY=$temp[8]; $vZ=$temp[9];
 

 		#print "$objecttype $objectname $x $y $z <br>";
 		#round up or down int(x+0.5) print int ( 1.1 + 0.5 ) ;          
              	
              	#insert known objects into the array
                #if ($objecttype eq 'N') { $map[$x][$y][$z]='<img src="black.gif">'; } #empty space Nothing here
		if ($objecttype eq 'SmallShip') { $map[$x][$y][$z]='<img src="orangex.gif">'; $smallgrids++; } #small grid ship
		if ($objecttype eq 'Planet') { $map[$x][$y][$z]='<img src="planetbl.gif">'; $planets++; } #Planet				
		if ($objecttype eq 'Asteroid') { $map[$x][$y][$z]='<img src="roid.gif">'; $asteroids++; } #asteroid
		if ($objecttype eq 'LargeShip') { $map[$x][$y][$z]='<img src="redx.gif">'; $largeships++; } #large grid ship
		if ($objecttype eq 'Player') { $map[$x][$y][$z]='<img src="char.gif">'; $characters++ } # Character/Player
		if ($objecttype eq 'Station') { $map[$x][$y][$z]='<img src="blob.gif">'; $stations++; } # Station
		
                #print "<A href=\"?x=$x\&y=$y\&tile=$type\&level=$level\&owner=$owner\&alliance=".
		#		"$alliance\&state=$state\&comment=$comment\">$tile</a>";
		#print "\n<br>";
		
		
		#foreach (@temp) {
		#	print "$_ <br>" ;
		#}	 
		
	}

#print 'locations stored ';
	
	#Draw out array
	$ax=0; $ay=0; if ($flat eq 'yes') { $az=0; } else { $az=$plane; }
	
	print "<br>"; 
	#for $az (0..100) {
		for $ay (0..100) {
			for $ax (0..100) {
				if ($map[$ax][$ay][$az] eq 'N') { print '<img src="black.gif">'; } else { print $map[$ax][$ay][$az]; }
			}
			print "<br>";
		}
	#}
	#print " DONE load of plain $plane <br>";

print '<br><form action="' . $ENV{SCRIPT_NAME} .'" method="post">';
print 'Z Plane: <INPUT TYPE="text" NAME="plane" VALUE="' . $plane . '"SIZE=3>
Scale(Metres): <INPUT TYPE="text" NAME="scale" VALUE="' . $scale . '"SIZE=10>
Flatten Z into 2D<input type="checkbox" name="flat" value="yes" '. $checked.'>
<input type="Hidden" name="render" value="dump">
<input type="reset" name="Reset" value="Revert">
<INPUT type="submit" value="Update">

</FORM>

<form action="' . $ENV{SCRIPT_NAME} .'" method="post">
<input type="Hidden" name="increment" value="yes">
<input type="Hidden" name="render" value="dump">
<INPUT TYPE="Hidden" NAME="plane" VALUE="' . $plane . '">
<INPUT TYPE="Hidden" NAME="scale" VALUE="' . $scale . '">
<INPUT type="submit" value="Increment"></form>
</FORM>
';
#<input type="checkbox" name="vehicle" value="Car" checked="checked"> I have a car<br>
$emptyspace-=($smallgrids+$planets+$asteroids+$largeships+$characters+$stations);
print 'key: <br>';
print '<img src="black.gif"> Empty Space '.$emptyspace.'<br>';  			#empty space Nothing here
print '<img src="orangex.gif"> Small Grid Craft '.$smallgrids.'<br>';  	#small grid ship
print '<img src="planetbl.gif"> Planet '.$planets.'<br>'; 		#Planet				
print '<img src="roid.gif"> Asteroid '.$asteroids.'<br>';  		#asteroid
print '<img src="redx.gif"> Large Ship '.$largeships.'<br>';  		#large grid ship
print '<img src="char.gif"> Character '.$characters.'<br>';  		# Character/Player
print '<img src="blob.gif"> Station '.$stations.'<br><hr>';  		# Station


}


############
# Below here is leftovers from the original map script
############

#######
#errors
#######
sub error { 
if($_[0] == 1) { print '<h2>Error! Unauthorised User</h2>'; } # no mode param
    elsif ($_[0] == 2) { print '<h2>Error! invalid homepage specfied</h2>'; } # no page param
    elsif ($_[0] == 3) { print '<h2>Error! incorrect user specified</h2>'; } # no/wrong user
    else{ print '<h2>Error! unknown error!!</h2>'; } # no error at all?
}

##################
#check if selected
##################
sub select {
my $test=$_[0];
my $test2=$_[1];
#print " [Debug $test vs $test2]";
if ($test eq $test2) { return "SELECTED"; }
}

###################
#load map coord info
###################
sub load {
my $page="$_[0]";
my $x="$_[1]";
my $y="$_[2]";
my $tile=$_[3];
my $level=$_[4];
my $owner=$_[5];
my $alliance=$_[6];
my $comments=$_[7];
#my $tdata=" ";


#print $tile;
# tile=type|level|owner|Alliance|comment

#if ($x) { if ($y) { } }

#need to add option here for punching coords

print "<hr>Location: $x,$y. Type: $tile. Level: $level Player: $owner <br>Alliance: $alliance Comments: $comments<hr>";
#print '<form method="get" action="' . $ENV{SCRIPT_NAME} .'">';
print '<br><form action="' . $ENV{SCRIPT_NAME} .'" method="post">';
#if ($tile eq "P") { $level = "P"; }
print '
x<INPUT TYPE="text" NAME="x" VALUE="' . $x . '"SIZE=3>
y<INPUT TYPE="text" NAME="y" VALUE="' . $y . '"SIZE=3>
<SELECT NAME="tile">
<OPTION VALUE="N" ' . &select($tile,"N") .'>Nothing
<OPTION VALUE="F" ' . &select($tile,"F") .'>Place Holder F
<OPTION VALUE="S" ' . &select($tile,"S") .'>Station
<OPTION VALUE="A" ' . &select($tile,"A") .'>Asteroid
<OPTION VALUE="I" ' . &select($tile,"I") .'>Small Ship
<OPTION VALUE="L" ' . &select($tile,"L") .'>Large Ship
<OPTION VALUE="C" ' . &select($tile,"C") .'>Character
<OPTION VALUE="P" ' . &select($tile,"P") .'>Planet
</SELECT>
<SELECT NAME="Level">
<OPTION VALUE="P" ' . &select($level,"P") .'> 
<OPTION VALUE="0" ' . &select($level,"0") .'>Unknown
<OPTION VALUE="1" ' . &select($level,"1") .'>Level 1
<OPTION VALUE="2" ' . &select($level,"2") .'>Level 2
<OPTION VALUE="3" ' . &select($level,"3") .'>Level 3
<OPTION VALUE="4" ' . &select($level,"4") .'>Level 4
<OPTION VALUE="4" ' . &select($level,"5") .'>Level 5
<OPTION VALUE="6" ' . &select($level,"6") .'>Level 6
<OPTION VALUE="7" ' . &select($level,"7") .'>Level 7
<OPTION VALUE="8" ' . &select($level,"8") .'>Level 8
<OPTION VALUE="9" ' . &select($level,"9") .'>Level 9
<OPTION VALUE="10" '. &select($level,"10").'>Level 10
</SELECT>
<br>
Player: <INPUT TYPE="text" NAME="owner" VALUE="'.$owner.'"SIZE=25>
Alliance: <INPUT TYPE="text" NAME="alliance" VALUE="' . $alliance .'"SIZE=25>
Comments: <INPUT TYPE="text" NAME="comment" VALUE="'.$comment.'"SIZE=25>';
print "<input TYPE=\"Hidden\" NAME=\"state\" VALUE=\"$state\"> ";

print '<input type="Hidden" name="mode" value="update"><input type="Hidden" name="render" value="test">';
print '<input type="reset" name="Reset" value="Revert">
<INPUT type="submit" value="Update"></form>
</FORM>
';

#text
#open(TDATA, $page) or die "File Error $!";
#while (<TDATA>) {
#	$tdata=$_;
#	print "$tdata";
# }
#close(TDATA);

}

###################
#read/render/create map 
###################
sub render { 
my $page='';
my @temp;
my @map; my @maprow;
my $overview="0";
#([0..499],[0..499]);
my $x=0; #0-499
my $y=0; #0-499
my $cur_line="";
my $runmode="$_[1]"; my $type="$_[2]";
my $level="$_[5]"; my $owner="$_[6]";
my $alliance="$_[7]";my $comment="$_[8]";
#499x499 array
my $arrayxstart="0"; my $arrayystart="0";
my $arrayxend="499"; my $arrayyend="499";
my $overcountx="0";
my $overcounty="0";
my $quickcount="0"; my $quickcount2="0";
my $tile="N";

#print "<p><b> pre render</b> 1: [$mapfile], 2: [$runmode], 3: [$xt], 4: [$yt], 5: [$tileitem], 5: [$level], 6: [$player], 7: #[$alliance], 8: [$comment]";

#print "<br><b>Debug: $mode $mapfile,$xt,$yt,$tileitem,$level,$player,$alliance,$comment</b>";

$page="$_[0]"; #filename fed from main program#

# 1 load file, create if it doesn't exist.
# 2 for loop, check each spot, insert N if undef, insert update if update
# 3 if update, write file
# 4 display map
# 5 done!

	## 1: load file into array, create if not exist
	#print '<br>' . "\n";
#print "\nBuilding Array.. ";
	#Lazy way to check file, append a nul to file. This creates if not existing
	open(TDATA, ">>$page")  or die "File Error $!";;
		print TDATA "";
	close(TDATA);

	#load our map file dump entire thing in memory
	open(TDATA, $page) or die "File Error $!";
		my @raw_data=<TDATA>;
	close(TDATA);

	#roll through file and load in map array, this only loads what is in file so no errors hopefully.
	$x=0; $y=0;
	foreach $cur_line (@raw_data)
	{
		#chomp($cur_line); 
		#do a super chomp to kill any end of line rubbish
   		$cur_line =~ s/\r|\n//g;
    		$cur_line =~ s/\r|\n//g;
    		$cur_line =~ s/\r|\n//g;

		@temp=split(/,/,$cur_line); #seperate by , deliminer#
               
		foreach (@temp) {
			$map[$x][$y]=$_;                          
			$x++
		}	  
		$x=0; $y++;
	}

	## 2: for loop, check each spot, insert N if undef, insert update if update
	## (this will also fill undefined map spots)
	## 3: we need to write file.  this is integrated here
	if ($runmode eq "update") { open(TDATA, ">$page")  or die "File Error $!"; }
#print " ..Filling Array\n<br>";
	$x=0; $y=0;
	for $y ($arrayystart..$arrayyend) {
		for $x ($arrayxstart..$arrayxend) {
			if (!$map[$x][$y]) { $map[$x][$y]="N"; }#\|fill empty fields otherwise leave as is
			if ($runmode eq "update") { 
				if (($x eq $xt) && ($y eq $yt)) { 
					$map[$x][$y]=$tileitem . '|' . $level . '|' . $owner . 
					'|' . $alliance . '|' .$comment;  
				}
			print TDATA "$map[$x][$y],";
			}
		}
	print TDATA "\n";
	} 
	if ($runmode eq "update") { close(TDATA); }

if (!$state) { $state="space"; }
print '<p><form action="' . $ENV{SCRIPT_NAME} .'" method="post">' .
'<SELECT NAME="state">
<OPTION VALUE="overview" ' . &select($state,"overview") .'>overview(1=10x10)
<OPTION VALUE="all" ' . &select($state,"all") .'>Entire world(slow!)
<OPTION VALUE="saxony" ' . &select($state,"saxony") .'>Saxony
<OPTION VALUE="space" ' . &select($state,"space") .'>space
<OPTION VALUE="northmarch" ' . &select($state,"northmarch") .'>northmarch
<OPTION VALUE="bohemia" ' . &select($state,"bohemia") .'>bohemia
<OPTION VALUE="lower" ' . &select($state,"lower") .'>lower lorraine
<OPTION VALUE="upper" ' . &select($state,"upper") .'>upper lorraine
<OPTION VALUE="burgundy" ' . &select($state,"burgundy") .'>burgundy
<OPTION VALUE="franconia" ' . &select($state,"franconia") .'>franconia
<OPTION VALUE="swabia" ' . &select($state,"swabia") .'>swabia
<OPTION VALUE="lombardy" ' . &select($state,"lombardy") .'>lombardy
<OPTION VALUE="thuringia" ' . &select($state,"thuringia") .'>thuringia
<OPTION VALUE="bavaria" ' . &select($state,"bavaria") .'>bavaria
<OPTION VALUE="tuscony" ' . &select($state,"tuscony") .'>tuscony
<OPTION VALUE="moravia" ' . &select($state,"moravia") .'>moravia
<OPTION VALUE="carintha" ' . &select($state,"carintha") .'>carintha
<OPTION VALUE="romagna" ' . &select($state,"romagna") .'>romagna
</SELECT>
<input type="Hidden" name="render" value="test">
<INPUT type="submit" value="Show"></center></form>
</FORM></p>
';

	## 4: Display map
	for ($state) {
		/all/ and do {$arrayystart=0; $arrayyend=499; $arrayxstart=0; $arrayxend=499; last;};
		/overview/ and do {$arrayystart=0; $arrayyend=50; $arrayxstart=0; $arrayxend=50; last;};
		/saxony/ and do {$arrayystart=0; $arrayyend=124; $arrayxstart=125; $arrayxend=250; last;};
		/space/ and do {$arrayystart=0; $arrayyend=100; $arrayxstart=0; $arrayxend=100; last;};
		/northmarch/ and do {$arrayystart=0; $arrayyend=124; $arrayxstart=251; $arrayxend=374; last;};
		/bohemia/ and do {$arrayystart=0; $arrayyend=124; $arrayxstart=375; $arrayxend=499; last;};
		/lower/ and do {$arrayystart=125; $arrayyend=249; $arrayxstart=0; $arrayxend=124; last;};
		/upper/ and do {$arrayystart=250; $arrayyend=374; $arrayxstart=0; $arrayxend=124; last;};
		/burgundy/ and do {$arrayystart=375; $arrayyend=499; $arrayxstart=0; $arrayxend=124; last;};
		/franconia/ and do {$arrayystart=125; $arrayyend=249; $arrayxstart=125; $arrayxend=250; last;};
		/swabia/ and do {$arrayystart=250; $arrayyend=374; $arrayxstart=125; $arrayxend=250; last;};
		/lombardy/ and do {$arrayystart=375; $arrayyend=499; $arrayxstart=125; $arrayxend=250; last;};
		/thuringia/ and do {$arrayystart=125; $arrayyend=249; $arrayxstart=251; $arrayxend=374; last;};
		/bavaria/ and do {$arrayystart=250; $arrayyend=374; $arrayxstart=251; $arrayxend=374; last;};
		/tuscony/ and do {$arrayystart=375; $arrayyend=499; $arrayxstart=251; $arrayxend=374; last;};
		/moravia/ and do {$arrayystart=125; $arrayyend=249; $arrayxstart=375; $arrayxend=499; last;};
		/carintha/ and do {$arrayystart=250; $arrayyend=374; $arrayxstart=375; $arrayxend=499; last;};
		/romagna/ and do {$arrayystart=375; $arrayyend=499; $arrayxstart=375; $arrayxend=499; last;};
		 #$state="overview";
	}
print "$state (x=$arrayxstart to $arrayxend. y=$arrayystart to $arrayyend.)\n <br>";
	$y=0; $x=0;
print "array dump \n<br>";
#print "Elements " .@maprow ."\n<br>";
	if ($state eq "overview") {
		print "10x10 overview goes here! \n";
		#this needs to check if a type "P" exists and display a # for them
		#if a particular alliance is selected and found in the 10x10 zone display A
		#it should also break up the overview into states with headings
		#if an item is clicked then display the 10x10 grid this represents with state heading
		$type='0'; $overcountx='0'; $overcounty='0';
		for $y ($arrayystart..$arrayyend) {    
			for $x ($arrayxstart..$arrayxend) { print $overcountx;
				if ($overcountx>=9) { $maprow[$overview]=$type; $overview++; $type="0"; $overcountx=0; }
				if ($overcounty>=9) { 
					foreach (@maprow) {
#theres a bug here i get 500 elements not 50, if i limit it using overview=0 below i get no data. odd
#clue - the line below should add to my array but doesn't, only rows add up
#if ($quickcount2<=499) { 
						#print "<A href=\"?overx=$quickcount2\&overy=$y\">$maprow[$quickcount]</a>"; 
#}

						$quickcount++;
						$quickcount2=$quickcount2+10; 
					}	  
					$quickcount='0'; $quickcount2='0'; $overview='0';
					$overcounty='0'; $overcountx='0'; print "\n<br>";
				}
				@temp=split(/\|/,$map[$x][$y]);
				if ($temp[0] eq "P") { $type++;  }
				$overcountx++; 
			}
			$x=0;
		#	$overview='0';

			$overcounty++
		}
	} else {
		if ($overy) { $arrayystart=$overy; $arrayyend=$overy+10; }
		if ($overx) { $arrayxstart=$overx; $arrayxend=$overx+10; }
		for $y ($arrayystart..$arrayyend) { 
			for $x ($arrayxstart..$arrayxend) { 
				@temp=split(/\|/,$map[$x][$y]);
				$type=$temp[0]; $level=$temp[1]; $owner=$temp[2]; 
				if (!$type) { $type="?"; }
				if ($type eq 'N') { $tile='<img src="black.gif">'; } #empty space Nothing here
				if ($type eq 'I') { $tile='<img src="orangex.gif">'; } #small grid ship
				if ($type eq 'P') { $tile='<img src="planetbl.gif">'; } #Planet				
				if ($type eq 'A') { $tile='<img src="roid.gif">'; } #asteroid
				if ($type eq 'L') { $tile='<img src="redx.gif">'; } #large grid ship
				if ($type eq 'C') { $tile='<img src="char.gif">'; } # Character/Player
				if ($type eq 'S') { $tile='<img src="blob.gif">'; } # Station
				#else { $tile=$type; }
				$alliance=$temp[3]; $comment=$temp[4];
				print "<A href=\"?x=$x\&y=$y\&tile=$type\&level=$level\&owner=$owner\&render=test\&alliance=".
				"$alliance\&state=$state\&comment=$comment\">$tile</a>";
			}
		print "\n<br>";
		}


	}
print 'end dump<br>';
	print '<!/PRE>';
}