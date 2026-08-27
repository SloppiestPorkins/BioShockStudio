class ActionRetractFact extends ActionFact
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
	FactDatabase.RetractFact(Pattern);
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
	S = __NFUN_168__("Retract fact", FactDesc);
	return;
	@NULL
	Item
	Item
}

defaultproperties
{
	actionDisplayName="Retract a Fact"
	actionHelp="Set the value of a fact to be false in the facts database"
}