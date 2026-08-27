class ActionGiveItemsToPlayer extends ActionShockInventory
	editinlinenew
	collapsecategories
	hidecategories(Object);

function Variable execute()
{
	local ShockPlayer thePlayer;
	local bool OldDisableInventoryWarnings;
	local ItemStack theStack;

	super(Action).execute();
	thePlayer = ShockPlayer(parentScript.Level.GetLocalPlayerController().Pawn);
	// End:0x102
	if(__NFUN_132__(__NFUN_114__(ItemClass, none), __NFUN_152__(StackSize, 0)))
	{
		AssertWithDescription(false, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("Script '", string(parentScript)), "' attempted to give "), string(StackSize)), " '"), string(ItemClass)), "' to the player.  Please correct this script action."));
		return none;
		OldDisableInventoryWarnings = thePlayer.disableInventoryWarnings;
		thePlayer.disableInventoryWarnings = true;
		theStack = Class'ShockGame.ItemStack'.static.Allocate(self).;
	}
	Construct_Void();
	theStack.__NFUN_199__();
	theStack.ItemClass = ItemClass;
	theStack.StackSize = StackSize;
	parentScript.AddPersistentContext('Scripted');
	thePlayer.AddStackToInventory(theStack);
	parentScript.RemovePersistentContext('Scripted');
	theStack.__NFUN_198__();
	thePlayer.disableInventoryWarnings = OldDisableInventoryWarnings;
	return none;
	return;
	@NULL
	Item
	Item
	@NULL
}

function editorDisplayString(out string S)
{
	S = __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("Give ", string(StackSize)), " <"), string(ItemClass)), "> to the player");
	return;
	@NULL
	Item
	Item
}

defaultproperties
{
	actionDisplayName="Give Items to the Player"
	actionHelp="Adds some items to the player's inventory"
}