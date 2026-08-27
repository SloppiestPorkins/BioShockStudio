class CeilingPathNode extends PathNode
	native
	config(AI)
	hidecategories(DrawScale3D,DisplayAdvanced,Lighting,LightColor,Force);

var bool bSpawnFloorPoint;
var const FloorPoint ConnectedFloorPoint;

defaultproperties
{
	bSpawnFloorPoint=true
	bAutoGenerateFlyingPathNodes=false
	FindBaseDirection=(X=0.0000000,Y=0.0000000,Z=1.0000000)
	bTestForWater=false
	Texture=Texture'ShockAI.Bioshock_Editor_Textures.S_Pathnode_Ceiling'
}