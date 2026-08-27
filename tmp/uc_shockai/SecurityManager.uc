class SecurityManager extends SecurityManagerBase implements IInterestedActorDestroyed, IInterestedPawnDied
	native
	config(AI);

var private LevelInfo Level;
var private SpawningManager SpawningManager;
var array<SecurityStation> SecurityStations;
var private bool bIsActive;
var private bool bShowAlarmTimer;
var private bool bLastAlarmTargetWasPlayer;
var private float EndDisableTime;
var private bool bIsAlarmOn;
var private float EndAlarmTime;
var private float ForceEndAlarmTime;
var private ShockPawn AlarmTarget;
var private Actor CurrentAlarmSource;
var private Vector LastAlarmTargetLocation;
var private Vector LastAlarmTargetVelocity;
var private Vector LastAlarmTargetLocationAsSeenByBots;
var private int AlarmTimeRemaining;
var private ShockPawn OriginalAlarmTarget;
var array<Actor> AIsViewingAlarmTarget;
var private float AlarmTimeReductionAmount;
var private config float RapidDepletionPhase;
var private Class<ShockPawn> AlarmBotClass;
var private int NumDesiredBotsForAlarm;
var private float BaseAlarmTime;
var private const config float PlayerAlarmTime;
var private const config float AIAlarmTime;
var private const config float SecurityBeaconAlarmTime;
var bool TargetWasSecurityBeaconed;

function Construct(LevelInfo inLevel, SpawningManagerBase inSpawningManager)
{
	local SecurityStation S;

	assert(__NFUN_119__(inLevel, none));
	Level = inLevel;
	assert(__NFUN_119__(inSpawningManager, none));
	SpawningManager = SpawningManager(inSpawningManager);
	// End:0x91
	foreach Level.__NFUN_304__(Class'ShockGame.SecurityStation', S)
	{
		SecurityStations[SecurityStations.Length] = S;				
		Level.RegisterNotifyPawnDied(self);
		Level.RegisterNotifyActorDestroyed(self);
		return;
		@NULL
		CommanderAction
		AIEventNotification
		@NULL
	}
}

// Export USecurityManager::execIsActive(FFrame&, void* const)
native function bool IsActive();

// Export USecurityManager::execIsAlarmOn(FFrame&, void* const)
native function bool IsAlarmOn();

// Export USecurityManager::execGetAlarmTarget(FFrame&, void* const)
native function ShockPawn GetAlarmTarget();

// Export USecurityManager::execGetLastAlarmTargetLocation(FFrame&, void* const)
native function Vector GetLastAlarmTargetLocation();

// Export USecurityManager::execGetLastAlarmTargetLocationAsSeenByBots(FFrame&, void* const)
native function Vector GetLastAlarmTargetLocationAsSeenByBots();

// Export USecurityManager::execGetLastAlarmTargetVelocity(FFrame&, void* const)
native function Vector GetLastAlarmTargetVelocity();

// Export USecurityManager::execAlarmTargetIsVisible(FFrame&, void* const)
native function bool AlarmTargetIsVisible();

// Export USecurityManager::execGetNumberOfBotsForCurrentAlarm(FFrame&, void* const)
native function int GetNumberOfBotsForCurrentAlarm();

// Export USecurityManager::execUpdateAlarmUIState(FFrame&, void* const)
native function UpdateAlarmUIState();

function bool LastAlarmTargetWasPlayer()
{
	return bLastAlarmTargetWasPlayer;
	return;
	@NULL
}

function HackSecuritySystem(float TimeOut)
{
	//native.TimeOut;	
	@NULL
}

// Export USecurityManager::execSetUnHacked(FFrame&, void* const)
native function SetUnHacked();

function name GetBotHackInfoName(Class BotClass)
{
	local SpawningManager SpawningManager;

	assert(__NFUN_258__(BotClass, Class'ShockAI.SecurityBot'));
	SpawningManager = SpawningManager(Level.SpawningManager);
	// End:0x77
	if(BotClass.__NFUN_303__('MinimumSecurityBot'))
	{
		return SpawningManager.MinimumSecurityBotHackInfoName;
		goto J0xE0;
		// End:0xAD
		if(BotClass.__NFUN_303__('MediumSecurityBot'))
		{
			return SpawningManager.MediumSecurityBotHackInfoName;
		}
		goto J0xE0;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0xE0
		/*@Error*/
		return SpawningManager.MaximumSecurityBotHackInfoName;
		return;
		@NULL
		CommanderAction
	}
	stop;
	default.@NULL
}

function StartAlarm(Actor AlarmSource, ShockPawn AlarmTarget, Class<ShockPawn> BotClass, int NumDesiredBots, optional bool bForceNewSecurityTarget, optional bool bInfiniteAlarm, optional bool bDontShowHUDTimer)
{
	//native.AlarmSource;
	//native.AlarmTarget;
	//native.BotClass;
	//native.NumDesiredBots;
	//native.bForceNewSecurityTarget;
	//native.bInfiniteAlarm;
	//native.bDontShowHUDTimer;	
	@NULL
	@NULL
	return default.@NULL;
}

function StopAlarm(optional bool TurnedOffBySecurityStation, optional bool CleanupSecurityImmediately)
{
	//native.TurnedOffBySecurityStation;
	//native.CleanupSecurityImmediately;	
	@NULL
	@NULL
}

function OnAlarmStarted()
{
	Level.dispatchMessage(Class'ShockAI.MessageSecurityAlarmStarted'.static.Allocate(self)., construct_NameName(CurrentAlarmSource.Label, AlarmTarget.Label));
	return;
	@NULL
	CommanderAction
	stop;
	default.@NULL
}

function OnAlarmStopped()
{
	Level.dispatchMessage(Class'ShockAI.MessageSecurityAlarmStopped'.static.Allocate(self)., construct_NameName(CurrentAlarmSource.Label, AlarmTarget.Label));
	return;
	@NULL
	CommanderAction
	stop;
	default.@NULL
}

function NotifySawTarget(ShockAI Viewer, ShockPawn Target)
{
	//native.Viewer;
	//native.Target;	
	@NULL
	@NULL
}

function NotifyLostTarget(ShockAI Viewer, ShockPawn Target)
{
	//native.Viewer;
	//native.Target;	
	@NULL
	@NULL
}

function NotifyNewTargetSeen(ShockAI Viewer, ShockPawn NewTarget)
{
	//native.Viewer;
	//native.NewTarget;	
	@NULL
	@NULL
}

function int GetTargetPriority(ShockPawn PotentialTarget)
{
	//native.PotentialTarget;	
	@NULL
}

function OnOtherActorDestroyed(Actor ActorBeingDestroyed)
{
	//native.ActorBeingDestroyed;	
	@NULL
}

function OnOtherPawnDied(Pawn DeadPawn)
{
	return;
}

defaultproperties
{
	bIsActive=true
	RapidDepletionPhase=3.0000000
	PlayerAlarmTime=60.0000000
	AIAlarmTime=60.0000000
	SecurityBeaconAlarmTime=60.0000000
}