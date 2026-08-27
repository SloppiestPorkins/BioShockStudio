class ActionAssignNextGathererBooty extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var edfindable travel Booty NextGathererBooty;
var travel name NextGathererBootyLabel;
var travel name GathererLabel;

function Variable execute()
{
	local int NumGatherersWithLabel;
	local Actor Booty;
	local Gatherer Iter;

	super.execute();
	// End:0x2F
	if(__NFUN_119__(NextGathererBooty, none))
	{
		Booty = NextGathererBooty;
		goto J0x6C;
		// End:0x6C
		if(__NFUN_255__(NextGathererBootyLabel, 'None'))
		{
		}
		Booty = findByLabel(Class'Engine.Actor', NextGathererBootyLabel);
		// End:0xF6
		if(__NFUN_130__(__NFUN_119__(Booty, none), __NFUN_255__(GathererLabel, 'None')))
		{
		}
		J0x6C:

		// End:0xF5
		foreach parentScript.allActorLabel(Class'ShockAI.Gatherer', Iter, GathererLabel)
		{
			Iter.SetCurrentResource(Booty);
			__NFUN_163__(NumGatherersWithLabel);						
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x190
			/*@Error*/
			log('AI', 2, __NFUN_112__(__NFUN_112__(__NFUN_112__(string(Name), " found more than 1 Gatherer with Label: "), string(GathererLabel)), " to assign a vent to, this could yield bad results!"));
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
	// End:0x161
	if(__NFUN_255__(GathererLabel, 'None'))
	{
		// End:0x95
		if(__NFUN_119__(NextGathererBooty, none))
		{
			S = __NFUN_112__(__NFUN_112__(__NFUN_112__("Assign Gatherer with Label ", propertyDisplayString('ProtectorLabel')), " to use the Booty "), string(NextGathererBooty.Name));
			goto J0x15E;
			// End:0x119
			if(__NFUN_255__(NextGathererBootyLabel, 'None'))
			{
				S = __NFUN_112__(__NFUN_112__(__NFUN_112__("Assign Gatherer with Label ", propertyDisplayString('ProtectorLabel')), " to use the Booty with label "), string(NextGathererBootyLabel));
			}
			goto J0x15E;
			S = "NextGathererBooty and NextGathererBootyLabel are not set!";
		}
		goto J0x186;
		S = "GathererLabel is not set!";
		J0x15E:

		return;
		@NULL
	}
	CommanderAction
	CommanderAction
	@NULL
}

defaultproperties
{
	actionDisplayName="Assign Booty to Gatherer"
	actionHelp="Assign the next Booty to a Gatherer"
	Category="AI"
}