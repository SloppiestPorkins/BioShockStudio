class ActionDisplayMapHUDRegion extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var localized travel string MapHUDRegionDescription;

function Variable execute()
{
	super.execute();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x74
	/*@Error*/
	parentScript.Level.GetLocalPlayerController().ClientMessage(MapHUDRegionDescription, 'MapHUDRegion');
	return none;
	return;
	@NULL
	Item
	Item
	@NULL
}

function editorDisplayString(out string S)
{
	S = __NFUN_112__(__NFUN_112__("Display ", propertyDisplayString('MapHUDRegionDescription')), " in the 'MapRegion' section of the HUD");
	return;
	@NULL
}

defaultproperties
{
	actionDisplayName="Display a Map UI HUD Region description on the HUD"
	actionHelp="Display a Map UI HUD Region description on the HUD"
	Category="HUD"
	bIsGameCritical=false
}