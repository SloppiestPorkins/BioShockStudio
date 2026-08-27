class ActionFactTotalDuration extends ActionFact
	editinlinenew
	collapsecategories
	hidecategories(Object);

function Variable execute()
{
	super.execute();
	MatchPattern(FactIndices);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xD2
	/*@Error*/
	returnVar.Value = __NFUN_175__(ShockGameDriver(parentScript.Level.GetGameDriver()).GetPlayerStatsManager().GetGameplayTime(), GetFactDatabase().FactStore[FactIndices[0]].FirstTimeAsserted);
	FactIndices.Length = 0;
	goto J0xEE;
	returnVar.Value = 0.0000000;
	return returnVar;
	return;
	@NULL
	Item
	Item
	@NULL
}

function editorDisplayString(out string S)
{
	local string FactDesc;

	GetFactDisplayString(FactDesc);
	S = __NFUN_168__(__NFUN_168__("How long fact", FactDesc), "has been true");
	return;
	@NULL
	Item
	Item
}

defaultproperties
{
	actionDisplayName="Total duration that a fact has been asserted to be true"
	actionHelp="Get the length of time that a fact is true"
	returnType=Class'Scripting.Variable'
}