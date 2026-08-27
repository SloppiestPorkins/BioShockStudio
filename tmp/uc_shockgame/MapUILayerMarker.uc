class MapUILayerMarker extends Actor
	native
	config
	placeable
	hidecategories(DrawScale3D,DisplayAdvanced);

var array<name> RegionNames;
var name LayerName;
var name ScaleMarkerName;

defaultproperties
{
	LayerName="Layer0Marker"
}