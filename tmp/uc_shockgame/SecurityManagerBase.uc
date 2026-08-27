class SecurityManagerBase extends Object
	abstract
	native;

overloaded function Construct(LevelInfo inLevel, SpawningManagerBase inSpawningManager)
{
	return;
}

function bool IsActive()
{
	return;
}

function HackSecuritySystem(float TimeOut)
{
	return;
}

function SetUnHacked()
{
	return;
}

function StartAlarm(Actor AlarmSource, ShockPawn AlarmTarget, Class<ShockPawn> BotClass, int NumDesiredBots, optional bool bForceNewSecurityTarget, optional bool bInfiniteAlarm, optional bool bDontShowHUDTimer)
{
	return;
}

function StopAlarm(optional bool TurnedOffBySecurityStation, optional bool CleanupSecurityImmediately)
{
	return;
}

function bool IsAlarmOn()
{
	return;
}

function ShockPawn GetAlarmTarget()
{
	return;
}

function bool LastAlarmTargetWasPlayer()
{
	return;
}

function Vector GetLastAlarmTargetLocation()
{
	return;
}

function Vector GetLastAlarmTargetLocationAsSeenByBots()
{
	return;
}

function Vector GetLastAlarmTargetVelocity()
{
	return;
}

function bool AlarmTargetIsVisible()
{
	return;
}

function int GetNumberOfBotsForCurrentAlarm()
{
	return;
}

function UpdateAlarmUIState()
{
	return;
}

function SpawnTestBot()
{
	return;
}

event name GetBotHackInfoName(Class BotClass)
{
	return;
}
