class ShockedGoal extends BioshockCharacterGoal
	collapsecategories
	hidecategories(Object,InternalParameters);

var(Parameters) bool bGoRagdollFirst;

function Construct(AI_Resource R, bool inGoRagdollFirst)
{
	construct_AI_Resource(R);
	bGoRagdollFirst = inGoRagdollFirst;
	return;
	@NULL
	CommanderAction
	AIEventNotification
	@NULL
}

function FallDown(Vector HitLocation, Vector HitNormal, Vector HitImpulseDirection, float HitMomentumImparted, name HitLowBone, name HitHighBone, DamageStimuliSet DamageStimuli)
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x6E
	/*@Error*/
	ShockedAction(achievingAction).FallDown(HitLocation, HitNormal, HitImpulseDirection, HitMomentumImparted, HitLowBone, HitHighBone, DamageStimuli);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

defaultproperties
{
	Priority=92
}