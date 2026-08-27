class ActionTriggerHavokForceActor extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name Target;

function Variable execute()
{
	local HavokForceActor targetActor;

	super.execute();
	// End:0x57
	foreach parentScript.allActorLabel(Class'Engine.HavokForceActor', targetActor, Target)
	{
		targetActor.TriggerForce();				
		return none;
		return;
		@NULL
		Variable
		Variable
		@NULL
	}
}

function editorDisplayString(out string S)
{
	S = __NFUN_112__(__NFUN_112__("Trigger HavokForceActor ", string(Target)), ".");
	return;
	@NULL
	Variable
}

defaultproperties
{
	actionDisplayName="Trigger HavokForceActor"
	actionHelp="Trigger a HavokForceActor.  If the HavokForceActor is disabled this will not work."
	Category="Physics"
}