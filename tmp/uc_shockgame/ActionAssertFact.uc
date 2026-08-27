class ActionAssertFact extends ActionFact
	editinlinenew
	collapsecategories
	hidecategories(Object);

function Variable execute()
{
	local FactDatabase FactDatabase;
	local FactPattern Pattern;

	super.execute();
	FactDatabase = ShockGameDriver(parentScript.Level.GetGameDriver()).GetFactDatabase();
	ConvertToFactPattern(Pattern);
	FactDatabase.AssertFact(Pattern, true, false);
	return none;
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
	S = __NFUN_168__(__NFUN_168__("Assert fact", FactDesc), "is true");
	return;
	@NULL
	Item
	Item
}

defaultproperties
{
	actionDisplayName="Assert a Fact"
	actionHelp="Set the value of a fact to be true in the facts database"
}