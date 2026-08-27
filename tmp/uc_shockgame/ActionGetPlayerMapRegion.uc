class ActionGetPlayerMapRegion extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

enum MapRegionGranularity
{
	DRT_MapUIRegion,                // 0
	DRT_MapHUDRegion                // 1
};

var travel ActionGetPlayerMapRegion.MapRegionGranularity DesiredRegionType;

function Variable execute()
{
	local PlayerController PC;
	local int IndexOfMapUIRegion;
	local name UIRegion, HUDRegion;
	local Variable returnVar;

	super.execute();
	PC = parentScript.Level.GetLocalPlayerController();
	UIRegion = PC.Pawn.Region.Zone.MapUIRegion;
	// End:0xC2
	if(__NFUN_154__(int(DesiredRegionType), int(0)))
	{
		returnVar = newTemporaryVariable(Class'Scripting.VariableName', string(UIRegion));
		goto J0x1A4;
		IndexOfMapUIRegion = Class'ShockGame.MessagePlayerChangedMapUIRegion'.static.GetIndexOfMapUIRegion(PC.Level, UIRegion);
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x169
		/*@Error*/
		HUDRegion = PC.Pawn.Level.MapUIRegions[IndexOfMapUIRegion].HUDRegion;
	}
	goto J0x17C;
	HUDRegion = 'None';
	returnVar = newTemporaryVariable(Class'Scripting.VariableName', string(HUDRegion));
	return returnVar;
	return;
	@NULL
	Item
	Item
	@NULL
}

function editorDisplayString(out string S)
{
	// End:0x45
	if(__NFUN_154__(int(DesiredRegionType), int(0)))
	{
		S = "Get the MapUI region of the Player";
		goto J0x74;
		S = "Get the MapHUD region of the Player";
	}
	return;
	@NULL
	Item
	J0x74:

	Item
}

defaultproperties
{
	actionDisplayName="Get player's MapUI or MapHUD region"
	actionHelp="Get player's MapUI or MapHUD region"
	returnType=Class'Scripting.VariableName'
	Category="Player"
}