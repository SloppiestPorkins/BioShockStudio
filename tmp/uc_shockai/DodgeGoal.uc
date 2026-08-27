class DodgeGoal extends BioshockCharacterGoal
	native
	collapsecategories
	hidecategories(Object,InternalParameters);

var(Parameters) private bool bDoesTargetHaveMeleeWeaponEquipped;

function Construct(AI_Resource R, bool inDoesTargetHaveMeleeWeaponEquipped)
{
	construct_AI_Resource(R);
	bDoesTargetHaveMeleeWeaponEquipped = inDoesTargetHaveMeleeWeaponEquipped;
	return;
	@NULL
	CommanderAction
	AIEventNotification
	@NULL
}

defaultproperties
{
	Priority=80
}