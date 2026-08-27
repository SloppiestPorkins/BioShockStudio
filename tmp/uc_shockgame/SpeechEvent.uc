class SpeechEvent extends Object
	native
	config(Speech)
	perobjectconfig;

struct native atomic PriorityOverrideInfo
{
	var config name VoiceType;
	var config int PriorityOverride;
};

struct native atomic LoopTimeOverrideInfo
{
	var config name VoiceType;
	var config Range LoopTimeOverride;
};

var config bool bQueue;
var private const config int Priority;
var config float TriggerChance;
var config float MinTimeBetweenEvents;
var config name EffectEvent;
var config float LowHealthCutoff;
var config float HighHealthCutoff;
var config bool bTriggerOnce;
var private const config Range LoopTimeRange;
var config bool bIgnoreQueueDelay;
var config array<PriorityOverrideInfo> PriorityOverrides;
var config array<LoopTimeOverrideInfo> LoopTimeOverrides;

function int GetPriority(ShockPawn AI)
{
	//native.AI;	
	@NULL
}

defaultproperties
{
	Priority=3
	TriggerChance=1.0000000
	HighHealthCutoff=1.0000000
}