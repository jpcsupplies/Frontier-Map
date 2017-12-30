# Frontier-Map
Tool for live online updates of your world on a galaxy map.

HIGHLY EXPERIMENTAL WORK IN PROGRESS.  USE AT OWN RISK.


How to use:

On your game server run the following mod: 

http://steamcommunity.com/sharedfiles/filedetails/?id=1220073387

or

the script in phoenixx game state folder from here


This will create a file in your Maps storage folder called GameStateData.csv with a map positon summary every time the server saves.


Place the following file into the same folder (typically the maps Storage folder):

https://github.com/jpcsupplies/Frontier-Map/blob/master/GameServerSTORAGE/PushMap.exe

or

https://github.com/jpcsupplies/Frontier-Map/blob/master/GameServerSTORAGE/PushMap.pl (If you have perl installed)


You may need to run as administrator depending on your security settings, or attempt to run as a dirty windows service. Make sure the runs in folder is the same as where the GameStateData.csv file is being created, and has access to GameStateData.csv and GameSetup.csv (or just the storage folder whatever is easiest)


On first run it should create a file called: 

GameSetup.csv

This contains 3 necessary settings and 1 optional setting:

Your Server Network Name,Requested Grid ID # (will be used to allocate its position on map),passkey(used to authenticate source of data - should match key on server),update time in minutes(default 5 mins),(optional)location of galaxy map cgi script if not specified it will use whatever my current test server is.


Example:

OGN,2,myreallysecretpassword,http://myreallyawesomeserver.com/map/updatemap.pl


This lists your server network as "OGN"

uses the passkey "myreallysecretpassword"

and pushes its updates to updatemap.pl, a cgi script running on myreallyawesomeserver.com


On your webserver:

grab all the files located in https://github.com/jpcsupplies/Frontier-Map/tree/master/Webserver
and place them on a perl compatible webserver.  Set permission 755 on map.pl and updatemap.pl


Use index.html as you launch portal to access the various testing modes of map.pl.


Or use your own map rendering cgi script.



