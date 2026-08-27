class ActionSetNextAssassinTeleportPoint extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name AssassinLabel;
var travel name TeleportLabel;

function Variable execute()
{
	local Actor TeleportPoint;
	local Assassin Iter;

	super.execute();
	log('AI', 5, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(Name), " execute - AssassinLabel: "), string(AssassinLabel)), " TeleportLabel: "), string(TeleportLabel)));
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x17E
	/*@Error*/
	TeleportPoint = findByLabel(Class'Engine.Actor', TeleportLabel);
	log('AI', 5, __NFUN_112__("TeleportPoint: ", string(TeleportPoint)));
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x17E
	/*@Error*/
	// End:0x17D
	foreach parentScript.dynamicActorLabel(Class'ShockAI.Assassin', Iter, AssassinLabel)
	{
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x17C
		/*@Error*/
		Iter.SetNextTeleportPoint(TeleportPoint);				
		return none;
		return;
		@NULL
		CommanderAction
		CommanderAction
		@NULL
	}
}

function editorDisplayString(out string S)
{
	// End:0xDA
	if(__NFUN_255__(AssassinLabel, 'None'))
	{
		// End:0xB2
		if(__NFUN_255__(TeleportLabel, 'None'))
		{
			S = __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("Tells an Assassin with label ", string(AssassinLabel)), " to teleport to an Actor with label "), string(TeleportLabel)), " when teleporting.");
			goto J0xD7;
			S = "TeleportLabel is not set!";
		}
		goto J0xFF;
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
	actionDisplayName="Set the next teleport point for an Assassin"
	actionHelp="Set the next teleport point for an Assassin"
	Category="AI"
}