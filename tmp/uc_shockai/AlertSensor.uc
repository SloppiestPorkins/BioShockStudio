class AlertSensor extends AI_Sensor implements IInterestedActorDestroyed, IInterestedPawnDied
	native;

var private ShockPawn CurrentThreat;
var private ShockAI SourceAI;
var private Actor ThreatAnchor;
var private bool bOnlyTestPlayer;
var private Range AlertedDistanceRange;

function Begin()
{
	super.Begin();
	assert(__NFUN_119__(sensorAction.m_Pawn, none));
	sensorAction.m_Pawn.Level.RegisterNotifyActorDestroyed(self);
	sensorAction.m_Pawn.Level.RegisterNotifyPawnDied(self);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function Cleanup()
{
	super.Cleanup();
	assert(__NFUN_119__(sensorAction.m_Pawn, none));
	sensorAction.m_Pawn.Level.UnRegisterNotifyActorDestroyed(self);
	sensorAction.m_Pawn.Level.UnRegisterNotifyPawnDied(self);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

// Export UAlertSensor::execTestForThreat(FFrame&, void* const)
native function TestForThreat();

function OnOtherPawnDied(Pawn DeadPawn)
{
	// End:0x38
	if(DeadPawn.__NFUN_303__('ShockPawn'))
	{
		HandleDeathOrDestructionMessage(ShockPawn(DeadPawn));
		return;
		@NULL
		CommanderAction
	}
	CommanderAction
}

function OnOtherActorDestroyed(Actor ActorBeingDestroyed)
{
	// End:0x38
	if(ActorBeingDestroyed.__NFUN_303__('ShockPawn'))
	{
		HandleDeathOrDestructionMessage(ShockPawn(ActorBeingDestroyed));
		return;
		@NULL
		CommanderAction
	}
	CommanderAction
}

function HandleDeathOrDestructionMessage(ShockPawn inTarget)
{
	// End:0x2C
	if(__NFUN_114__(CurrentThreat, inTarget))
	{
		CurrentThreat = none;
		NotifyThreatChange();
		return;
		@NULL
		CommanderAction
	}
	EcologyFighterCommanderAction
}

function NotifyThreatChange()
{
	log(,, __NFUN_112__(__NFUN_112__(string(Name), " NotifyThreatChange - CurrentThreat is: "), string(CurrentThreat)));
	setObjectValue(CurrentThreat);
	return;
	@NULL
	CommanderAction
	stop;
	default.@NULL
}

function setParameters(ShockAI inSourceAI, Actor inThreatAnchor, Range inAlertedDistanceRange, bool inOnlyTestPlayer)
{
	assert(Class'Engine.Pawn'.static.checkAlive(inSourceAI));
	assert(__NFUN_119__(inThreatAnchor, none));
	assert(__NFUN_177__(inAlertedDistanceRange.Min, 0.0000000));
	assert(__NFUN_177__(inAlertedDistanceRange.Max, 0.0000000));
	assert(__NFUN_179__(inAlertedDistanceRange.Max, inAlertedDistanceRange.Min));
	SourceAI = inSourceAI;
	ThreatAnchor = inThreatAnchor;
	AlertedDistanceRange = inAlertedDistanceRange;
	bOnlyTestPlayer = inOnlyTestPlayer;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x132
	/*@Error*/
	sensorAction.runAction();
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

defaultproperties
{
	bNotifyOnValueChange=true
}