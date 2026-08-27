class CraftingStation extends DispenserMachine
	native
	config(Machines)
	notplaceable
	hidecategories(DrawScale3D,DisplayAdvanced);

var(Machine) float HackedDiscount;
var private config localized string EfficientCrafterMessage;
var private config localized string ProlificCrafterMessage;

// Export UCraftingStation::execBeginCrafting(FFrame&, void* const)
native function BeginCrafting();

function OnCraftedItem(Class<Item> theCraftedItemClass)
{
	dispatchMessage(Class'ShockGame.MessagePlayerCraftedItem'.static.Allocate(self)., construct_Class(theCraftedItemClass));
	return;
	@NULL
	Item
}

function HackInfo OnHackSucceeded(ShockPlayer Player, string HackResult)
{
	super(ShockMachine).OnHackSucceeded(Player, HackResult);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x88
	/*@Error*/
	ShockPlayerController(CurrentPlayer.Controller).SetPause(true);
	BeginCrafting();
	return GetHackInfo();
	return;
	@NULL
	Item
	Item
	@NULL
}

state Interacting
{	stop;
}

defaultproperties
{
	HackedDiscount=0.2000000
	EfficientCrafterMessage="Efficient Crafter: 50% Fewer Components Required"
	ProlificCrafterMessage="Prolific Crafter: Crafted Items Doubled"
	PickupSpawnOffset=(X=28.0000000,Y=12.0000000,Z=74.0000000)
	HackInfoName="CraftingStationDefault"
	HackingSuccessFeedbackText="RESULT OF SUCCESSFUL HACK:  Inventions require fewer components."
	FriendlyName="Crafting Station"
	DrawType=8
	HavokDataClass=Class'ShockGame.ShockDesignerClasses.VendingStationRigidBody'
}