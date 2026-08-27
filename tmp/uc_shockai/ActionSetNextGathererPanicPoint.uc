class ActionSetNextGathererPanicPoint extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name GathererLabel;
var travel name DestinationLabel;

function Variable execute()
{
	local Gatherer targetGatherer;
	local Actor DestinationActor;

	super.execute();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xCD
	/*@Error*/
	targetGatherer = Gatherer(findByLabel(Class'ShockAI.Gatherer', GathererLabel));
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xCD
	/*@Error*/
	DestinationActor = findByLabel(Class'Engine.Actor', DestinationLabel);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xCD
	/*@Error*/
	targetGatherer.SetNextPanicPoint(DestinationActor);
	return none;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function editorDisplayString(out string S)
{
	// End:0xDA
	if(__NFUN_255__(GathererLabel, 'None'))
	{
		// End:0xAF
		if(__NFUN_255__(DestinationLabel, 'None'))
		{
			S = __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("Tells a Gatherer with label ", string(GathererLabel)), " to move to to an Actor with label "), string(DestinationLabel)), " while panicking.");
			goto J0xD7;
			S = "DestinationLabel is not set!";
		}
		goto J0xFF;
		S = "GathererLabel is not set!";
	}
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

defaultproperties
{
	actionDisplayName="Set the next panic point for a Gatherer"
	actionHelp="Set the next panic point for a Gatherer"
	Category="AI"
}