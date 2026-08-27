class ActionChangePawnPhysics extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name Target;
var travel bool DisablePhysics;
var travel bool EnableRootMotionWhenPhysicsDisabled;

function Variable execute()
{
	local Pawn targetPawn;
	local Actor.EPhysics newPhysics;

	super.execute();
	// End:0x42
	if(DisablePhysics)
	{
		// End:0x33
		if(EnableRootMotionWhenPhysicsDisabled)
		{
			newPhysics = 3;
			goto J0x3F;
			newPhysics = 0;
			goto J0x4E;
			newPhysics = 4;
		}
		// End:0x9D
		foreach parentScript.dynamicActorLabel(Class'Engine.Pawn', targetPawn, Target)
		{
		}/* !MISMATCHING REMOVE, tried If got Type:ForEach Position:0x036! */
		targetPawn.__NFUN_3970__(newPhysics);				
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
	local string ChangeString;

	// End:0x6B
	if(DisablePhysics)
	{
		// End:0x41
		if(EnableRootMotionWhenPhysicsDisabled)
		{
			ChangeString = "Disable With Root Motion";
			goto J0x68;
			ChangeString = "Disable Without Root Motion";
		}
		goto J0x7D;
		ChangeString = "Enable";
		S = __NFUN_112__(__NFUN_112__(ChangeString, " the Unreal physics on "), string(Target));
	}
	return;
	@NULL
	Variable
	Variable
	@NULL
}

defaultproperties
{
	actionDisplayName="Enable/Disable Pawn Physics"
	actionHelp="Turn normal movement physics (like falling) on or off for a Pawn."
	Category="Physics"
}