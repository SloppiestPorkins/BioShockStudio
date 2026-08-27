class ActionFactTimesAsserted extends ActionFact
	editinlinenew
	collapsecategories
	hidecategories(Object);

function Variable execute()
{
	super.execute();
	MatchPattern(FactIndices);
	// End:0x89
	if(__NFUN_151__(FactIndices.Length, 0))
	{
		returnVar.Value = float(GetFactDatabase().FactStore[FactIndices[0]].TimesAsserted);
		FactIndices.Length = 0;
		goto J0xA5;
		returnVar.Value = 0.0000000;
		return returnVar;
		return;
		@NULL
		Item
		Item
	}
	@NULL
}

function editorDisplayString(out string S)
{
	local string FactDesc;

	GetFactDisplayString(FactDesc);
	S = __NFUN_168__(__NFUN_168__("Number of times fact", FactDesc), "was asserted since last retract");
	return;
	@NULL
	Item
	Item
}

defaultproperties
{
	actionDisplayName="Fact assertion count since last retract"
	actionHelp="Get how many times a fact was asserted since last retract"
	returnType=Class'Scripting.Variable'
}