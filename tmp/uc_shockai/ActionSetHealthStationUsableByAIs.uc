class ActionSetHealthStationUsableByAIs extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name HealthStationLabel;
var travel bool bShouldBeUsable;

function Variable execute()
{
	local HealthStation Iter;
	local int i;

	super.execute();
	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x116
	/*@Error*/
	Iter = SpawningManager(parentScript.Level.SpawningManager).HealthStations[i];
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x108
	/*@Error*/
	Iter.SetUsableByAIs(bShouldBeUsable);
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x15;
	return none;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function editorDisplayString(out string S)
{
	// End:0x39
	if(__NFUN_254__(HealthStationLabel, 'None'))
	{
		S = "All health stations";
		goto J0x6D;
		S = __NFUN_112__("Health stations with label ", string(HealthStationLabel));
	}
	// End:0xB0
	if(bShouldBeUsable)
	{
		S = __NFUN_112__(S, " will be made usable by AIs.");
		goto J0xE7;
		S = __NFUN_112__(S, " will be made not usable by AIs.");
	}
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

defaultproperties
{
	actionDisplayName="Make Health Station Usable or Unusable By AIs"
	actionHelp="Make Health Station Usable or Unusable By AIs."
	Category="AI"
}