class ActionAssignNextProtectorVent extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var edfindable travel GathererVent NextProtectorVent;
var travel name ProtectorLabel;

function Variable execute()
{
	local Protector Iter;
	local int NumProtectorsWithLabel;

	super.execute();
	// End:0x94
	if(__NFUN_130__(__NFUN_119__(NextProtectorVent, none), __NFUN_255__(ProtectorLabel, 'None')))
	{
		// End:0x93
		foreach parentScript.allActorLabel(Class'ShockAI.Protector', Iter, ProtectorLabel)
		{
			Iter.SetNextGathererVent(NextProtectorVent);
			__NFUN_163__(NumProtectorsWithLabel);						
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x12F
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
	// End:0xBA
	if(__NFUN_255__(ProtectorLabel, 'None'))
	{
		// End:0x8D
		if(__NFUN_119__(NextProtectorVent, none))
		{
			S = __NFUN_112__(__NFUN_112__(__NFUN_112__("Assign Protector with Label ", string(ProtectorLabel)), " to use the vent "), string(NextProtectorVent.Name));
			goto J0xB7;
			S = "NextProtector Vent is not set!";
		}
		goto J0xE0;
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
	actionDisplayName="Assign Vent to Protector"
	actionHelp="Assign the next Vent to a Protector"
	Category="AI"
}