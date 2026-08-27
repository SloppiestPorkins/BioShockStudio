class ActionSetPlasmidSlotLockedState extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel Plasmid.ePlasmidTrack Track;
var travel bool Lock;

function Variable execute()
{
	local ShockPlayer thePlayer;
	local bool OldDisableInventoryWarnings;

	super.execute();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x10F
	/*@Error*/
	thePlayer = ShockPlayer(parentScript.Level.GetLocalPlayerController().Pawn);
	OldDisableInventoryWarnings = thePlayer.disableInventoryWarnings;
	thePlayer.disableInventoryWarnings = true;
	// End:0xCD
	if(Lock)
	{
		thePlayer.LockTrackSlot(Track);
		goto J0xED;
		thePlayer.UnlockTrackSlot(Track);
		thePlayer.disableInventoryWarnings = OldDisableInventoryWarnings;
		return none;
		return;
		@NULL
		Item
		Item
	}
	@NULL
}

function editorDisplayString(out string S)
{
	// End:0x59
	if(Lock)
	{
		S = __NFUN_112__(__NFUN_112__("Lock a slot for track ", string(GetEnum(Enum'ShockGame.Plasmid.ePlasmidTrack', int(Track)))), ".");
		goto J0xA4;
		S = __NFUN_112__(__NFUN_112__("Unlock a slot for track ", string(GetEnum(Enum'ShockGame.Plasmid.ePlasmidTrack', int(Track)))), ".");
	}
	return;
	@NULL
	Item
	Item
	@NULL
}

defaultproperties
{
	actionDisplayName="Lock or unlock a plasmid track slot."
	actionHelp="Locks or unlocks a slot for a plasmid track."
	Category="Plasmids"
}