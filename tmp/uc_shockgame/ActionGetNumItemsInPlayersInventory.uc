class ActionGetNumItemsInPlayersInventory extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel Class<Item> ItemClass;
var transient VariableFloat returnVar;

function Variable execute()
{
	// End:0x47
	if(__NFUN_114__(returnVar, none))
	{
		returnVar = Class'Scripting.VariableFloat'.static.Allocate(self,,, 134217728).;
		Construct_Void();
		// End:0xC2
		if(__NFUN_114__(ItemClass, Class'ShockGame.Credits'))
		{
		}
		returnVar.Value = float(ShockPlayer(parentScript.Level.GetLocalPlayerController().Pawn).GetCredits());
		goto J0x1A7;
		// End:0x13D
		if(__NFUN_114__(ItemClass, Class'ShockGame.ADAM'))
		{
			returnVar.Value = float(ShockPlayer(parentScript.Level.GetLocalPlayerController().Pawn).GetADAM());
		}
		goto J0x1A7;
		returnVar.Value = float(ShockPlayer(parentScript.Level.GetLocalPlayerController().Pawn).GetNumberOfItems(ItemClass));
		return returnVar;
		return;
		@NULL
	}
	Item
	Item
	@NULL
}

function editorDisplayString(out string S)
{
	S = __NFUN_112__(__NFUN_112__("Get the number of <", string(ItemClass)), "> in the players inventory");
	return;
	@NULL
	Item
}

defaultproperties
{
	actionDisplayName="Get Number of Items in Inventory"
	actionHelp="Returns the number of items in the players inventory"
	returnType=Class'Scripting.Variable'
	Category="Inventory"
}