class ActionSetGrenadierSuicideState extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name GrenadierLabel;
var travel Grenadier.ESpecialCommitSuicideState SpecialCommitSuicideState;

function Variable execute()
{
	local Grenadier IterGrenadier;

	super.execute();
	// End:0x88
	if(__NFUN_255__(GrenadierLabel, 'None'))
	{
		// End:0x84
		foreach parentScript.Level.dynamicActorLabel(Class'ShockAI.Grenadier', IterGrenadier, GrenadierLabel)
		{
			IterGrenadier.SetSpecialCommitSuicideState(SpecialCommitSuicideState);						
			goto J0xF0;
			log('AI', 2, __NFUN_112__(__NFUN_112__(__NFUN_112__(string(Name), " in script: "), string(parentScript.Name)), " - No GrenadierLabel specified."));
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
	S = __NFUN_112__(__NFUN_112__(__NFUN_112__("Grenadiers with label ", string(GrenadierLabel)), " will commit suicide using the state "), string(GetEnum(Enum'ShockAI.Grenadier.ESpecialCommitSuicideState', int(SpecialCommitSuicideState))));
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

defaultproperties
{
	actionDisplayName="Grenadiers Suicide Specially"
	actionHelp="Tell a Grenadier or group of Grenadiers to use their suicide attack in a special way"
	Category="AI"
}