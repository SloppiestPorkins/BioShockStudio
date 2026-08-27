class SpawnBioAmmoAdjustment extends SpawnAdjustment
	config(Difficulty);

var private const config Class<Item> BioAmmoClass;

function GetSpawnParameters(out Class<Item> ItemClass, out int StackSize)
{
	super.GetSpawnParameters(ItemClass, StackSize);
	ItemClass = BioAmmoClass;
	return;
	@NULL
	Item
	DifficultyAdjustment
	@NULL
}

defaultproperties
{
	BioAmmoClass=Class'ShockGame.ShockDesignerClasses.BioAmmoHypo'
	MinSpawnRate=(Low=30.0000000,Normal=100.0000000,High=280.0000000,Extreme=280.0000000)
	MaxSpawnRate=(Low=60.0000000,Normal=140.0000000,High=320.0000000,Extreme=320.0000000)
	MinStackSize=1
	MaxStackSize=1
}