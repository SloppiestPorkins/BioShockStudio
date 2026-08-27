class ActionSetNextAssassinTeleportInRunDestination extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name AssassinLabel;
var travel name RunDestinationLabel;

function Variable execute()
{
	local Actor RunDestination;
	local Assassin Iter;

	super.execute();
	log('AI', 5, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(Name), " execute - AssassinLabel: "), string(AssassinLabel)), " RunDestinationLabel: "), string(RunDestinationLabel)));
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x186
	/*@Error*/
	RunDestination = findByLabel(Class'Engine.Actor', RunDestinationLabel);
	log('AI', 5, __NFUN_112__("Run Destination: ", string(RunDestination)));
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x186
	/*@Error*/
	// End:0x185
	foreach parentScript.dynamicActorLabel(Class'ShockAI.Assassin', Iter, AssassinLabel)
	{
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x184
		/*@Error*/
		Iter.SetNextTeleportInRunDestination(RunDestination);				
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
		// End:0xAC
		if(__NFUN_255__(RunDestinationLabel, 'None'))
		{
			S = __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("Tells an Assassin with label ", string(AssassinLabel)), " to teleport in and run to an Actor with label "), string(RunDestinationLabel)), ".");
			goto J0xD7;
			S = "RunDestinationLabel is not set!";
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
	actionDisplayName="Set the next teleport in run destination for an Assassin"
	actionHelp="Set the next teleport in run destination for an Assassin"
	Category="AI"
}