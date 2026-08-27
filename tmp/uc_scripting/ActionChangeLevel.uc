class ActionChangeLevel extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel string MapName;
var travel string StartLocationLabel;
var travel bool bShowLoadingMessage;
var travel bool persist;

function Variable latentExecute()
{
	local string AdditionalOptions;
	local PlayerController PC;

	super.latentExecute();
	PC = parentScript.Level.GetLocalPlayerController();
	// End:0x63
	if(__NFUN_129__(PC.Pawn.IsAlive()))
	{
		return none;
		// End:0xC8
		if(parentScript.Level.Game.IsSecuritySystemActive())
		{
		}
		parentScript.Level.Game.StopSecurityAlarmForLevelChange();
		// End:0xF0
		if(__NFUN_123__(StartLocationLabel, ""))
		{
			AdditionalOptions = __NFUN_112__("#", StartLocationLabel);
			// End:0x11C
			if(__NFUN_129__(bShowLoadingMessage))
			{
				AdditionalOptions = __NFUN_112__(AdditionalOptions, "?quiet");
			}
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x147
			/*@Error*/
			AdditionalOptions = __NFUN_112__(AdditionalOptions, "?TRAVEL");
			parentScript.Level.ServerTravel(__NFUN_112__(MapName, AdditionalOptions));
		}
		return none;
		return;
		@NULL
	}
	MessageTriggerVolume
	Variable
	@NULL
}

function editorDisplayString(out string S)
{
	S = __NFUN_112__("Change level to map ", propertyDisplayString('MapName'));
	return;
	@NULL
}

defaultproperties
{
	persist=true
	actionDisplayName="Change Level"
	actionHelp="Loads a new map"
	Category="Level"
}