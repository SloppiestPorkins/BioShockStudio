class DispenserMachine extends ShockMachine
	abstract
	native
	config(Machines)
	notplaceable
	hidecategories(DrawScale3D,DisplayAdvanced);

var(Machine) private Vector PickupSpawnOffset;
var private int SpawnedItemCount;
var(Machine) private int MaxSpawnedItemCount;

defaultproperties
{
	MaxSpawnedItemCount=25
}