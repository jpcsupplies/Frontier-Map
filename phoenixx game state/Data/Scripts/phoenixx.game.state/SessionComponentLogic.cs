namespace phoenixx.game.state
{
    using Sandbox.ModAPI;
    using System.Collections.Generic;
    using System.IO;
    using VRage.Game;
    using VRage.Game.Components;
    using VRage.Game.ModAPI;
    using VRage.ModAPI;
    using VRageMath;

    [MySessionComponentDescriptor(MyUpdateOrder.NoUpdate)]
    public class SessionComponentLogic : MySessionComponentBase
    {
        private const string GameStateDataFilename = "GameStateData.csv";

        public override void SaveData()
        {
            if (MyAPIGateway.Session.OnlineMode.Equals(MyOnlineModeEnum.OFFLINE) || MyAPIGateway.Multiplayer.IsServer)
            {
                TextWriter writer = MyAPIGateway.Utilities.WriteFileInGlobalStorage(GameStateDataFilename);
                // TODO: blocks,size,speed(m/s),direction
                //MyAPIGateway.Utilities.ConfigDedicated.WorldName, MyAPIGateway.Utilities.ConfigDedicated.ServerDescription, MyAPIGateway.Utilities.ConfigDedicated.ServerName
                if (MyAPIGateway.Multiplayer.IsServer && !MyAPIGateway.Session.OnlineMode.Equals(MyOnlineModeEnum.OFFLINE))
                {
                    string SWorld = MyAPIGateway.Utilities.ConfigDedicated.WorldName;
                    string SDescription = MyAPIGateway.Utilities.ConfigDedicated.ServerDescription;
                    string SName = MyAPIGateway.Utilities.ConfigDedicated.ServerName;
                    string Sconnect = MyAPIGateway.Utilities.ConfigDedicated.IP + ':' + MyAPIGateway.Utilities.ConfigDedicated.ServerPort;

                    writer.WriteLine($"{SName} | {SWorld} | {Sconnect} | {SDescription},,,,,,,,,");
                } else { writer.WriteLine("Server Name | Server World | 0.0.0.0:00000 | This is an offline map,,,,,,,,,"); }
                writer.WriteLine("Type,Name,X,Y,Z,Size,Speed,VectorX,VectorY,VectorZ");

                List<IMyPlayer> players = new List<IMyPlayer>();
                MyAPIGateway.Players.GetPlayers(players, p => p != null);
                foreach (IMyPlayer player in players)
                {
                    Vector3D position = player.GetPosition();
                    Vector3 vector = player.Character?.Physics?.LinearVelocity ?? Vector3.Zero;
                    // player official height is 1.8m.
                    writer.WriteLine($"Player,\"{player.DisplayName}\",{position.X},{position.Y},{position.Z},1.8,{vector.Length()},{vector.X},{vector.Y},{vector.Z}");
                }



                var allShips = new HashSet<IMyEntity>();
                MyAPIGateway.Entities.GetEntities(allShips, e => e is IMyCubeGrid);
                foreach (IMyEntity entity in allShips)
                {
                    IMyCubeGrid grid = entity as IMyCubeGrid;
                    if (grid != null)
                    {
                        Vector3D position = grid.GetPosition();
                        //string typeName = grid.IsStatic ? "Station" : "Ship"; 
                        string typeName = (grid.GridSizeEnum == MyCubeSize.Large ? "Large" : "Small") +(grid.IsStatic ? "Station" : "Ship"); 
                        // approximate the dimensions average, in the grid size.
                        float size = (grid.LocalAABB.Height + grid.LocalAABB.Width + grid.LocalAABB.Depth) / 3f * grid.GridSize;
                        Vector3 vector = grid.Physics?.LinearVelocity ?? Vector3.Zero;
                        writer.WriteLine($"{typeName},\"{grid.DisplayName}\",{position.X},{position.Y},{position.Z},{size},{vector.Length()},{vector.X},{vector.Y},{vector.Z}");
                    }
                }

                var currentVoxelList = new List<IMyVoxelBase>();
                MyAPIGateway.Session.VoxelMaps.GetInstances(currentVoxelList);

                foreach (IMyVoxelBase voxel in currentVoxelList)
                {
                    Sandbox.Game.Entities.MyPlanet planet = voxel as Sandbox.Game.Entities.MyPlanet;
                    if (planet != null)
                    {
                        Vector3D position = planet.WorldMatrix.Translation; // center
                        writer.WriteLine($"Planet,\"{planet.StorageName}\",{position.X},{position.Y},{position.Z},{planet.AverageRadius * 2},0,0,0,0");
                    }

                    IMyVoxelMap asteroid = voxel as IMyVoxelMap;
                    if (asteroid != null)
                    {
                        Vector3D position = new BoundingBoxD(asteroid.PositionLeftBottomCorner, asteroid.PositionLeftBottomCorner + asteroid.Storage.Size).Center;
                        // asteroid volumes are cubic, so one side is sufficient.
                        // the size will be the approximate diameter, assuming the space used is sperical.
                        writer.WriteLine($"Asteroid,\"{asteroid.StorageName}\",{position.X},{position.Y},{position.Z},{asteroid.Storage.Size.X},0,0,0,0");
                    }
                }

                writer.Flush();
                writer.Close();
            }
        }
    }
}