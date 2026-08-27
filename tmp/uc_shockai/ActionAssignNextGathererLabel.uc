class ActionAssignNextGathererLabel extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name ProtectorLabel;
var travel name GathererLabel;

function Variable execute()
{
	local Protector Iter;
	local int NumProtectorsWithLabel;

	super.execute();
	// End:0x9C
	if(__NFUN_130__(__NFUN_255__(GathererLabel, 'None'), __NFUN_255__(ProtectorLabel, 'None')))
	{
		// End:0x9B
		foreach parentScript.allActorLabel(Class'ShockAI.Protector', Iter, ProtectorLabel)
		{
			Iter.SetNextGathererLabel(GathererLabel);
			__NFUN_163__(NumProtectorsWithLabel);						
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x137
			/*@Error*/
			log('AI', 2, __NFUN_112__(__NFUN_112__(__NFUN_112__(string(Name), " found more than 1 Protector with Label: "), string(ProtectorLabel)), " to assign a vent to, this could yield bad results!"));
		}
	}
	return none;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function editorDisplayString(out string S)
{
	// End:0xC3
	if(__NFUN_255__(ProtectorLabel, 'None'))
	{
		// End:0x9B
		if(__NFUN_255__(GathererLabel, 'None'))
		{
			S = __NFUN_112__(__NFUN_112__(__NFUN_112__("Assign Protector with Label ", string(ProtectorLabel)), " to spawn a gatherer with the label "), string(GathererLabel));
			goto J0xC0;
			S = "GathererLabel is not set!";
		}
		goto J0xE9;
		S = "ProtectorLabel is not set!";
	}
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

defaultproperties
{
	actionDisplayName="Assign Gatherer Label to the Protector's next spawned Gatherer"
	actionHelp="Assign a Gatherer Label to the Protector's next spawned Gatherer"
	Category="AI"
}