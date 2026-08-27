class ActionFactDuration extends ActionFact
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
	returnVar.Value = __NFUN_175__(ShockGameDriver(parentScript.Level.GetGameDriver()).GetPlayerStatsManager().GetGameplayTime(), GetFactDatabase().FactStore[FactIndices[0]].LastTimeAsserted);
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
	S = __NFUN_168__(__NFUN_168__("How long since fact", FactDesc), "was last asserted");
	return;
	@NULL
	Item
	Item
}

defaultproperties
{
	actionDisplayName="Time since the fact was last asserted"
	actionHelp="Get the length of time since a fact was last asserted"
	returnType=Class'Scripting.Variable'
}