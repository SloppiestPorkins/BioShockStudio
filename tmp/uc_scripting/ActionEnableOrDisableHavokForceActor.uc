class ActionEnableOrDisableHavokForceActor extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name Target;
var travel bool enabled;

function Variable execute()
{
	local HavokForceActor targetActor;

	super.execute();
	// End:0x61
	foreach parentScript.allActorLabel(Class'Engine.HavokForceActor', targetActor, Target)
	{
		targetActor.SetEnabled(enabled);				
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
	// End:0x45
	if(enabled)
	{
		S = __NFUN_112__(__NFUN_112__("Enable HavokForceActor ", string(Target)), ".");
		goto J0x7B;
		S = __NFUN_112__(__NFUN_112__("Disable HavokForceActor ", string(Target)), ".");
	}
	return;
	@NULL
	Variable
	Variable
	@NULL
}

defaultproperties
{
	enabled=true
	actionDisplayName="Enable or Disable HavokForceActor"
	actionHelp="Enable or disable a HavokForceActor.  When a HavokForceActor is disabled it will never apply any forces, even if triggered."
	Category="Physics"
}