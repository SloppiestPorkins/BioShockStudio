class ActionApplyImpulse extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name Target;
var travel Vector Velocity;
var travel name BoneName;

function Variable execute()
{
	local Actor targetActor;

	super.execute();
	// End:0x73
	if(__NFUN_218__(Velocity, Velocity))
	{
		log('Scripting', 3, "ActionApplyImpulse: Invalid floating point values in Velocity.");
		return none;
		// End:0x12B
		foreach parentScript.dynamicActorLabel(Class'Engine.Actor', targetActor, Target)
		{
		}/* !MISMATCHING REMOVE, tried If got Type:ForEach Position:0x067! */
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x101
		/*@Error*/
		targetActor.HavokSetLinearVelocityAll(Velocity);
		goto J0x12A;
		targetActor.HavokSetLinearVelocity(Velocity, BoneName);				
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
	S = __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("Apply a velocity of ", string(Velocity)), " on "), string(Target)), ".");
	return;
	@NULL
	Variable
	Variable
}

defaultproperties
{
	actionDisplayName="Apply Impulse"
	actionHelp="Apply an impulse to an actor."
	Category="Actor"
}