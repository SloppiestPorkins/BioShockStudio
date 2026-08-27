class ActionFreezeHavokActor extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name Target;
var travel bool Freeze;
var travel bool ActivateWhenUnfreezing;

function Variable execute()
{
	local Actor targetActor;

	super.execute();
	// End:0x10B
	foreach parentScript.dynamicActorLabel(Class'Engine.Actor', targetActor, Target)
	{
		// End:0xAB
		if(targetActor.__NFUN_303__('ReactiveActor'))
		{
			ReactiveActor(targetActor).ChangeMobility(__NFUN_129__(Freeze));
			targetActor.HavokActivate(ActivateWhenUnfreezing);
			goto J0x10A;
			// End:0xD2
			if(Freeze)
			{
				targetActor.HavokFreeze();
				goto J0x10A;
				targetActor.HavokUnfreeze();
				targetActor.HavokActivate(ActivateWhenUnfreezing);
			}						
			return none;
			return;
			@NULL
			Variable
			Variable
		}
		@NULL
	}
}

function editorDisplayString(out string S)
{
	// End:0x35
	if(Freeze)
	{
		S = __NFUN_112__(__NFUN_112__("Freeze ", string(Target)), ".");
		goto J0x5C;
		S = __NFUN_112__(__NFUN_112__("Unfreeze ", string(Target)), ".");
	}
	return;
	@NULL
	Variable
	Variable
	@NULL
}

defaultproperties
{
	Freeze=true
	ActivateWhenUnfreezing=true
	actionDisplayName="Freeze Actor"
	actionHelp="Freezes a Havok Actor in place.  This only works for Actors that exist in Havok.  This is intended to keep physics objects in place so they don't move, it will not put an AI into the frozen state."
	Category="Physics"
}