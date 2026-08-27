class UnconsciousAction extends FallDownReactionAction
	config(AI)
	collapsecategories
	hidecategories(Object,InternalParameters);

var private config Range UnconsciousTimeRange;

function float selectionHeuristic(AI_Goal Goal)
{
	// End:0x2A
	if(__NFUN_114__(Goal.Class, default.satisfiesGoal))
	{
		return 1.0000000;
		return 0.0000000;
		return;
		@NULL
	}
	CommanderAction
	Class'ShockAI.CommanderAction'
}

function NotifyFinishedGettingUp()
{
	ShockAI().AddHealth(ShockAI().GetMaxHealth());
	Gatherer(m_Pawn).OnFinishedUnconscious();
	return;
	@NULL
	CommanderAction
}

function DelayOnGround()
{
	local float DelayOnGroundTime;

	DelayOnGroundTime = RandRange(UnconsciousTimeRange.Min, UnconsciousTimeRange.Max);
	__NFUN_256__(DelayOnGroundTime);
	return;
	@NULL
	EcologyAI
	EcologyFighterCommanderAction
	@NULL
}

defaultproperties
{
	UnconsciousTimeRange=(Min=5.0000000,Max=5.0000000)
	satisfiesGoal=Class'ShockAI.UnconsciousGoal'
}