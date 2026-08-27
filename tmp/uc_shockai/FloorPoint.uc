class FloorPoint extends PathNode
	native
	config(AI)
	hidecategories(DrawScale3D,DisplayAdvanced,Lighting,LightColor,Force);

var const NavigationPoint ConnectedCeilingPoint;

defaultproperties
{
	bAutoGenerateFlyingPathNodes=false
}