class SpawnMedHypoAdjustment extends SpawnAdjustment
	config(Difficulty);

var private const config Class<Item> MedHypoClass;

function GetSpawnParameters(out Class<Item> ItemClass, out int StackSize)
{
	super.GetSpawnParameters(ItemClass, StackSize);
	ItemClass = MedHypoClass;
	return;
	@NULL
	Item
	DifficultyAdjustment
	@NULL
}

defaultproperties
{
	MedHypoClass=Class'ShockGame.ShockDesignerClasses.MedHypo'
	MinSpawnRate=(Low=30.0000000,Normal=100.0000000,High=280.0000000,Extreme=280.0000000)
	MaxSpawnRate=(Low=60.0000000,Normal=140.0000000,High=320.0000000,Extreme=320.0000000)
	MinStackSize=1
	MaxStackSize=1
}