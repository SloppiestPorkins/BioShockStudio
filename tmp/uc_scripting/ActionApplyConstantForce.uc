class ActionApplyConstantForce extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name Target;
var travel Vector Force;
var travel float Duration;
var travel float Delay;
var travel name BoneName;

function Variable execute()
{
	local Actor targetActor;

	super.execute();
	// End:0xBB
	if(__NFUN_132__(__NFUN_132__(__NFUN_218__(Force, Force), __NFUN_181__(Duration, Duration)), __NFUN_181__(Delay, Delay)))
	{
		log('Scripting', 3, "ActionApplyConstantForce: Invalid floating point values in Force, Duration or Delay.");
		return none;
		// End:0x12C
		foreach parentScript.dynamicActorLabel(Class'Engine.Actor', targetActor, Target)
		{
		}/* !MISMATCHING REMOVE, tried If got Type:ForEach Position:0x09F! */
		targetActor.HavokImpartCOMForce(Force, Duration, Delay, BoneName);				
		return none;
		return;
		@NULL
		Variable
		Variable
		@NULL
	}/* !MISMATCHING REMOVE, tried ForEach got Type:If Position:0x006! */
}

function editorDisplayString(out string S)
{
	S = __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("Apply a force of ", string(Force)), " on "), string(Target)), " for "), string(Duration)), " seconds after waiting "), string(Delay)), " seconds.");
	return;
	@NULL
	Variable
	Variable
	@NULL
}

defaultproperties
{
	actionDisplayName="Apply Constant Force"
	actionHelp="Apply a force to an actor for a specified duration."
	Category="Actor"
}