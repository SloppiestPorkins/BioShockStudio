class ActionAssassinTeleport extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name AssassinLabel;
var travel name TeleportLabel;
var travel name TeleportRotationLabel;
var travel bool bUseTeleportOutEffects;
var travel bool bSkipEtherTime;

function Variable execute()
{
	local Actor TeleportPoint, TeleportRotationTarget;
	local Assassin Iter;

	super.execute();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x143
	/*@Error*/
	TeleportPoint = findByLabel(Class'Engine.Actor', TeleportLabel);
	// End:0x9D
	if(__NFUN_255__(TeleportRotationLabel, 'None'))
	{
		TeleportRotationTarget = findByLabel(Class'Engine.Actor', TeleportRotationLabel);
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x143
		/*@Error*/
		// End:0x142
		foreach parentScript.allActorLabel(Class'ShockAI.Assassin', Iter, AssassinLabel)
		{
		}/* !MISMATCHING REMOVE, tried If got Type:ForEach Position:0x080! */
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x141
		/*@Error*/
		Iter.TeleportTo(TeleportPoint, TeleportRotationTarget, bUseTeleportOutEffects, bSkipEtherTime);				
		return none;
		return;
		@NULL
		CommanderAction
		CommanderAction
		@NULL
	}/* !MISMATCHING REMOVE, tried ForEach got Type:If Position:0x048! */
}

function editorDisplayString(out string S)
{
	// End:0xC8
	if(__NFUN_255__(AssassinLabel, 'None'))
	{
		// End:0xA0
		if(__NFUN_255__(TeleportLabel, 'None'))
		{
			S = __NFUN_112__(__NFUN_112__(__NFUN_112__("Tells an Assassin with label ", string(AssassinLabel)), " to teleport NOW to an Actor with label "), string(TeleportLabel));
			goto J0xC5;
			S = "TeleportLabel is not set!";
		}
		goto J0xED;
		S = "AssassinLabel is not set!";
	}
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

defaultproperties
{
	actionDisplayName="Teleport now Assassin!"
	actionHelp="Tell an Assassin to teleport right now!"
	Category="AI"
}