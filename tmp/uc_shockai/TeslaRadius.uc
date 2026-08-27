class TeslaRadius extends Actor
	native
	config
	notplaceable
	hidecategories(DrawScale3D,DisplayAdvanced);

struct native atomic BeamSpawnTimes
{
	var array<float> SpawnTimes;

	structdefaultproperties
	{
		CheckpointTypePadding=7602293
	}
};

var private Range NewBeamDelay;
var Class<Emitter> EffectClass;
var transient array<Emitter> EffectActorInstance;
var float EffectTime;
var int MaxNumBolts;
var transient array<BeamSpawnTimes> EffectsBeamSpawnTimes;
var transient array<ShockAI> Targets;
var private float EffectRadius;

// Export UTeslaRadius::execZAP(FFrame&, void* const)
native function ZAP();

function SetEffectTime(float inEffectTime)
{
	EffectTime = inEffectTime;
	return;
	@NULL
	CommanderAction
}

function SetRadius(float inRadius)
{
	EffectRadius = inRadius;
	return;
	@NULL
	CommanderAction
}

function SetEffectClass(Class<Emitter> inEffectClass)
{
	EffectClass = inEffectClass;
	return;
	@NULL
	CommanderAction
}

function SetMaxNumBolts(int inMaxNumBolts)
{
	MaxNumBolts = inMaxNumBolts;
	return;
	@NULL
	CommanderAction
}

function SetNewBeamDelay(Range inNewBeamDelay)
{
	NewBeamDelay = inNewBeamDelay;
	return;
	@NULL
	CommanderAction
}

defaultproperties
{
	MaxNumBolts=5
	EffectRadius=1024.0000000
	bNeedProtectedTick=true
}