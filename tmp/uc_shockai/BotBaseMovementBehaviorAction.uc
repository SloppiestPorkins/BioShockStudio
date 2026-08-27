class BotBaseMovementBehaviorAction extends BioshockCharacterAction
	native
	collapsecategories
	hidecategories(Object,InternalParameters);

function OnMoveStarted()
{
	m_Pawn.TriggerEffectEvent('BeganAccelerating');
	return;
	@NULL
}

function OnMoveEnded()
{
	m_Pawn.TriggerEffectEvent('BeganDecelerating');
	return;
	@NULL
}

function OnBumpedOtherBot(SecurityBot OtherBot)
{
	return;
}
