class BotBehaviorActionInterface extends BioshockCharacterAction
	native
	collapsecategories
	hidecategories(Object,InternalParameters);

var private SecurityBot MyBot;

function initAction(AI_Resource R, AI_Goal Goal)
{
	super(AI_CharacterAction).initAction(R, Goal);
	MyBot = SecurityBot(m_Pawn);
	assert(__NFUN_119__(MyBot, none));
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function Cleanup()
{
	super(AI_CharacterAction).Cleanup();
	return;
	@NULL
}

function OnSecurityBeaconApplied(Actor Damager, ShockPawn SecurityBeaconedTarget)
{
	return;
}

function OnAttackSpecifiedTarget(ShockPawn Target, bool ForceNewTarget)
{
	return;
}

function OnControllerDamaged(ShockPawn Damager, float TotalDamageDealt)
{
	return;
}

function OnControllerDealtDamage(ShockPawn Damagee, float TotalDamageDealt)
{
	return;
}

function OnIntentionallyDamaged(ShockPawn Damager, float TotalDamageDealt)
{
	return;
}

function OnBumpedOtherBot(SecurityBot OtherBot)
{
	return;
}

function OnKilledOtherPawn(ShockPawn Killee)
{
	return;
}
