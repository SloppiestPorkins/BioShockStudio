class ActionRagdoll extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name AILabel;
var travel bool bRelativeToAIRotation;
var travel Vector HitImpulseDirection;
var travel float HitMomentumImparted;

function Variable execute()
{
	local ShockAI Target;
	local Vector RotatedImpulse;

	super.execute();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x11F
	/*@Error*/
	// End:0x11E
	foreach parentScript.Level.dynamicActorLabel(Class'ShockAI.ShockAI', Target, AILabel)
	{
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x11D
		/*@Error*/
		// End:0xAE
		if(bRelativeToAIRotation)
		{
			RotatedImpulse = __NFUN_276__(HitImpulseDirection, Target.Rotation);
			goto J0xC1;
			RotatedImpulse = HitImpulseDirection;
			Target.Fall(Target.Location, __NFUN_226__(RotatedImpulse), RotatedImpulse, HitMomentumImparted, 'None', 'None');
		}				
		return none;
		return;
		@NULL
		CommanderAction
		CommanderAction
		@NULL
	}
}

function editorDisplayString(out string S)
{
	S = __NFUN_168__(__NFUN_168__("Make", string(AILabel)), "go into ragdoll");
	return;
	@NULL
	CommanderAction
}

defaultproperties
{
	actionDisplayName="Make an AI go into ragdoll"
	actionHelp="Make an AI go into ragdoll after (optionally) applying force to it"
	Category="AI"
}