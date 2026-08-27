class ActionHideOrShowActor extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name ActorLabel;
var travel bool HideActor;

function Variable execute()
{
	local Actor A;

	super.execute();
	// End:0x61
	foreach parentScript.allActorLabel(Class'Engine.Actor', A, ActorLabel)
	{
		A.SetHidden(HideActor);				
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
	// End:0x21
	if(HideActor)
	{
		S = "Hide ";
		goto J0x32;
		S = "Show ";
	}
	S = __NFUN_112__(S, propertyDisplayString('ActorLabel'));
	return;
	@NULL
	Variable
	Variable
	@NULL
}

defaultproperties
{
	HideActor=true
	actionDisplayName="Hide or UnHide an actor"
	actionHelp="Hides or unhides an actor"
	Category="Actor"
}