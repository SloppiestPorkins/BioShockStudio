class SecurityStation extends ShockMachine
	native
	config(Machines)
	notplaceable
	hidecategories(DrawScale3D,DisplayAdvanced);

var(Machine) private bool AllowHacking;
var(Machine) private float SecurityTimeout;
var private config localized string UsedFeedbackTextNoAlarmActive;
var private config name AnimPrepareForInteraction;
var private config name AnimUnprepareForInteraction;

function int GetDesiredAnimationCapabilities()
{
	return __NFUN_158__(super(Actor).GetDesiredAnimationCapabilities(), 256);
	return;
	@NULL
}

function PostBeginPlay()
{
	log('Machines', 5, __NFUN_112__(string(self), "---SecurityStation::PostBeginPlay()"));
	super.PostBeginPlay();
	SetStateEffectEvents();
	return;
	@NULL
}

function PostLoadGame()
{
	local SecurityManagerBase SecuritySystem;

	super(Actor).PostLoadGame();
	SecuritySystem = ShockGameInfo(Level.Game).GetSecurityManager();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xB5
	/*@Error*/
	// End:0x7A
	if(__NFUN_129__(SecuritySystem.IsActive()))
	{
		OnNotifySecurityAlarmOff(false);
		goto J0xB5;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0xB5
		/*@Error*/
		OnNotifySecurityAlarmOn(SecuritySystem.GetAlarmTarget());
	}
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

event OnNotifySecuritySystemActive()
{
	log('Machines', 4, "NotifySecuritySystemActive() called on SecurityStation.");
	SetStateEffectEvents();
	return;
}

event OnNotifySecuritySystemInactive()
{
	log('Machines', 4, "NotifySecuritySystemInactive() called on SecurityStation.");
	SetStateEffectEvents();
	return;
}

function OnNotifySecurityAlarmOn(ShockPawn inAlarmTarget)
{
	log('Machines', 4, "NotifySecurityAlarmOn() called on SecurityStation.");
	log('Machines', 5, __NFUN_112__("...playing AnimPrepareForInteraction=", string(AnimPrepareForInteraction)));
	SetStateEffectEvents();
	PlayAnimationOnChannel(0, AnimPrepareForInteraction, 4);
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function OnNotifySecurityAlarmOff(bool TurnedOffBySecurityStation)
{
	log('Machines', 4, __NFUN_112__(__NFUN_112__("NotifySecurityAlarmOff( ", string(TurnedOffBySecurityStation)), " ) called on SecurityStation."));
	SetStateEffectEvents();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xCE
	/*@Error*/
	log('Machines', 5, __NFUN_112__("...playing AnimUnprepareForInteraction=", string(AnimUnprepareForInteraction)));
	PlayAnimationOnChannel(0, AnimUnprepareForInteraction);
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function bool CanBeUsedNow()
{
	return __NFUN_130__(super.CanBeUsedNow(), ShockGameInfo(Level.Game).GetSecurityManager().IsAlarmOn());
	return;
	@NULL
	Item
	Item
	@NULL
}

function bool CanBeHackedNow(ShockPlayer Player)
{
	return __NFUN_130__(AllowHacking, __NFUN_129__(ShockGameInfo(Level.Game).GetSecurityManager().IsAlarmOn()));
	return;
	@NULL
	Item
	Item
	@NULL
}

function HackInfo OnHackSucceeded(ShockPlayer Player, string HackResult)
{
	super.OnHackSucceeded(Player, HackResult);
	ShockGameInfo(Level.Game).GetSecurityManager().HackSecuritySystem(GetEffectiveSecurityTimeout());
	TriggerEffectEvent('HackSucceeded');
	SetStateEffectEvents();
	return GetHackInfo();
	return;
	@NULL
	Item
	Item
	@NULL
}

function HackInfo OnHackFailed(ShockPlayer Player, string HackResult)
{
	TriggerEffectEvent('HackFailed');
	return GetHackInfo();
	return;
}

function float GetEffectiveSecurityTimeout()
{
	return ShockPlayer(Level.GetLocalPlayerController().Pawn).ModifyStat('SecurityTimeout_Bonus', SecurityTimeout);
	return;
	@NULL
	Item
	Item
	@NULL
}

function SetStateEffectEvents()
{
	local SecurityManagerBase SecuritySystem;

	UnTriggerEffectEvent('AlarmActive');
	UnTriggerEffectEvent('SecurityHacked');
	SecuritySystem = ShockGameInfo(Level.Game).GetSecurityManager();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xCB
	/*@Error*/
	// End:0x9E
	if(__NFUN_129__(SecuritySystem.IsActive()))
	{
		TriggerEffectEvent('SecurityHacked');
		goto J0xCB;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0xCB
		/*@Error*/
		TriggerEffectEvent('AlarmActive');
	}
	return;
	@NULL
	Item
	Item
	@NULL
}

state Waiting
{	stop;
}

state Interacting
{
	protected function OnInteractionFailed()
	{
		return;
	}
	stop;
}

defaultproperties
{
	SecurityTimeout=30.0000000
	UsedFeedbackTextNoAlarmActive="Alarm is already off."
	AnimPrepareForInteraction="intoWaiting"
	AnimUnprepareForInteraction="outofWaitingALT"
	HackInfoName="SecurityStationDefault"
	HackingSuccessFeedbackText="RESULT OF SUCCESSFUL HACK: Security systems temporarily disabled."
	FriendlyName="Security Station"
	AnimWaitingStarted="DormantLoop"
	AnimInteractionStarted="Interacting"
	AnimInteractionLoop="InteractingDown"
	AnimInteractionEnded="outofWaiting"
}