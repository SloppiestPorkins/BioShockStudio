class AttackReactionGoal extends BioshockCharacterGoal
	collapsecategories
	hidecategories(Object,InternalParameters);

var(Parameters) Actor Attacker;
var(Parameters) float InitiateDamageDelay;
var(Parameters) DamageStimuliSet.EDamageType DamageType;

function Construct(AI_Resource R, Actor inAttacker, float inInitiateDamageDelay, DamageStimuliSet.EDamageType inDamageType)
{
	construct_AI_Resource(R);
	Attacker = inAttacker;
	InitiateDamageDelay = inInitiateDamageDelay;
	DamageType = inDamageType;
	return;
	@NULL
	CommanderAction
	AIEventNotification
	@NULL
}

defaultproperties
{
	Priority=76
}