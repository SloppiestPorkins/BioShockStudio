class GathererVent extends StaticMeshActor implements IDamagee
	native
	config(AI)
	hidecategories(DrawScale3D,DisplayAdvanced,Force,LightColor,Lighting,Object,Sound);

var private localized string FriendlyName;
var private localized string UseVerbText;
var const editconstarray editconst array<name> SpawnZones;
var bool bDontSpawnGatherers;
var bool bProtectorsShouldntUse;
var float WaitForNoGathererTime;
var private PathNode FrontPathNode;
var private ShockAI CurrentAI;
var private config string GathererSpawnLocationSocketName;
var private config string GathererEnterWithoutProtectorSocketName;
var private config string BouncerExitWithGathererSocketName;
var private config string RosieExitWithGathererSocketName;
var private config string SPFExitWithGathererSocketName;
var private config string BouncerEnterWithGathererSocketName;
var private config string RosieEnterWithGathererSocketName;
var private config string SPFEnterWithGathererSocketName;
var private config string GathererEnterWithBouncerSocketName;
var private config string GathererEnterWithRosieSocketName;
var private config string GathererEnterWithSPFSocketName;
var private config string NavigationPointSocketName;
var private Vector GathererSpawnLocation;
var private Vector GathererEnterWithoutProtectorLocation;
var private Vector BouncerExitWithGathererLocation;
var private Vector RosieExitWithGathererLocation;
var private Vector SPFExitWithGathererLocation;
var private Vector BouncerEnterWithGathererLocation;
var private Vector RosieEnterWithGathererLocation;
var private Vector SPFEnterWithGathererLocation;
var private Vector GathererEnterWithBouncerLocation;
var private Vector GathererEnterWithRosieLocation;
var private Vector GathererEnterWithSPFLocation;
var config Class<Gatherer> GathererClass;
var config Class<Gatherer> PlayerEscortedGathererClass;
var private bool bPlayerCanSpawn;
var private bool bGathererEnterWithoutProtectorLocationInvalid;
var private bool bBouncerExitWithGathererLocationInvalid;
var private bool bRosieExitWithGathererLocationInvalid;
var private bool bSPFExitWithGathererLocationInvalid;
var private bool bBouncerEnterWithGathererLocationInvalid;
var private bool bRosieEnterWithGathererLocationInvalid;
var private bool bSPFEnterWithGathererLocationInvalid;
var private bool bGathererEnterWithBouncerLocationInvalid;
var private bool bGathererEnterWithRosieLocationInvalid;
var private bool bGathererEnterWithSPFLocationInvalid;

function PathNode GetFrontPathNode()
{
	return FrontPathNode;
	return;
	@NULL
}

function Vector GetGathererSpawnLocation()
{
	return GathererSpawnLocation;
	return;
	@NULL
}

function Vector GetGathererEnterWithoutProtectorLocation()
{
	return GathererEnterWithoutProtectorLocation;
	return;
	@NULL
}

function Vector GetGathererEnterWithProtectorLocation(Protector ProtectorEscort)
{
	assert(__NFUN_119__(ProtectorEscort, none));
	// End:0x38
	if(ProtectorEscort.__NFUN_303__('Bouncer'))
	{
		return GathererEnterWithBouncerLocation;
		goto J0x6B;
		// End:0x61
		if(ProtectorEscort.__NFUN_303__('Rosie'))
		{
		}
		return GathererEnterWithRosieLocation;
		goto J0x6B;
		return GathererEnterWithSPFLocation;
		return;
		@NULL
		CommanderAction
		CommanderAction
	}
	@NULL
}

function Vector GetProtectorEnterLocation(Protector Requester)
{
	assert(__NFUN_119__(Requester, none));
	// End:0x38
	if(Requester.__NFUN_303__('Bouncer'))
	{
		return BouncerEnterWithGathererLocation;
		goto J0x6B;
		// End:0x61
		if(Requester.__NFUN_303__('Rosie'))
		{
		}
		return RosieEnterWithGathererLocation;
		goto J0x6B;
		return SPFEnterWithGathererLocation;
		return;
		@NULL
		CommanderAction
		CommanderAction
	}
	@NULL
}

function Vector GetProtectorExitLocation(Protector Requester)
{
	assert(__NFUN_119__(Requester, none));
	// End:0x38
	if(Requester.__NFUN_303__('Bouncer'))
	{
		return BouncerExitWithGathererLocation;
		goto J0x6B;
		// End:0x61
		if(Requester.__NFUN_303__('Rosie'))
		{
		}
		return RosieExitWithGathererLocation;
		goto J0x6B;
		return SPFExitWithGathererLocation;
		return;
		@NULL
		CommanderAction
		CommanderAction
	}
	@NULL
}

function bool HasCurrentAI(ShockAI Requester)
{
	return __NFUN_130__(Class'Engine.Pawn'.static.checkAlive(CurrentAI), __NFUN_119__(CurrentAI, Requester));
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function Class<Gatherer> GetGathererClass(optional bool bPlayerEscortedGatherer)
{
	// End:0x1A
	if(bPlayerEscortedGatherer)
	{
		return PlayerEscortedGathererClass;
		goto J0x24;
		return GathererClass;
		return;
	}
	@NULL
	CommanderAction
	J0x24:

	CommanderAction
}

function SetCurrentAI(ShockAI AI)
{
	assert(__NFUN_132__(__NFUN_129__(Class'Engine.Pawn'.static.checkAlive(CurrentAI)), __NFUN_114__(CurrentAI, AI)));
	assert(Class'Engine.Pawn'.static.checkAlive(AI));
	CurrentAI = AI;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function ResetCurrentAI(ShockAI RequestingAI)
{
	assert(__NFUN_119__(RequestingAI, none));
	// End:0x31
	if(__NFUN_114__(CurrentAI, RequestingAI))
	{
		CurrentAI = none;
		return;
		@NULL
		CommanderAction
		CommanderAction
	}
	@NULL
}

function ShockAI GetCurrentAI()
{
	return CurrentAI;
	return;
	@NULL
}

function Gatherer SpawnGatherer(ShockPawn PawnThatSpawnedGatherer, optional name SpawnedGathererLabel, optional bool bForceSpawn)
{
	local Gatherer SpawnedGatherer;
	local Rotator SpawnRotation;
	local name GathererLabel;
	local Protector ProtectorThatSpawnedGatherer;

	assert(__NFUN_119__(GathererClass, none));
	assert(__NFUN_119__(PawnThatSpawnedGatherer, none));
	SpawnRotation.Yaw = __NFUN_146__(Rotation.Yaw, 32768);
	ProtectorThatSpawnedGatherer = Protector(PawnThatSpawnedGatherer);
	// End:0xA3
	if(__NFUN_255__(SpawnedGathererLabel, 'None'))
	{
		GathererLabel = SpawnedGathererLabel;
		goto J0xE9;
		// End:0xD6
		if(__NFUN_119__(ProtectorThatSpawnedGatherer, none))
		{
			GathererLabel = ProtectorThatSpawnedGatherer.GetNextGathererLabel();
			goto J0xE9;
			GathererLabel = 'PlayerEscortedGatherer';
			SpawnedGatherer = __NFUN_278__(GetGathererClass(__NFUN_114__(ProtectorThatSpawnedGatherer, none)),,, GathererSpawnLocation, SpawnRotation, bForceSpawn, GathererLabel);
		}
		SpawnedGatherer.SetCurrentVent(self);
	}
	SpawnedGatherer.SetEscort(PawnThatSpawnedGatherer);
	return SpawnedGatherer;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function SetPlayerCanSpawn(bool Flag)
{
	bPlayerCanSpawn = Flag;
	return;
	@NULL
	CommanderAction
}

function IPotentialAimOrActionTarget.TargetType GetTargetType()
{
	// End:0x13
	if(CanBeUsedNow())
	{
		return 1;		
	}
	else
	{
		return 0;
	}
	return;
}

function float GetUseDistance()
{
	return 0.0000000;
	return;
}

function bool ActionBlockedByPawns()
{
	return true;
	return;
}

function bool CanBeUsedNow()
{
	return bPlayerCanSpawn;
	return;
	@NULL
}

function bool GetRequiredPlacementForUse(out Vector WorldSpaceLocation, out Rotator WorldSpaceRotation)
{
	return false;
	return;
}

function OnUsed(Pawn Pawn)
{
	local ShockPlayer Player;

	Player = ShockPlayer(Level.GetLocalPlayerController().Pawn);
	Player.EscortedGatherer = SpawnGatherer(Player);
	bPlayerCanSpawn = false;
	return;
	@NULL
	EcologyCommanderAction
	BioshockMovementAction
	@NULL
}

function OnUseStopped(Pawn Pawn)
{
	return;
}

function string GetUseVerbText()
{
	return UseVerbText;
	return;
	@NULL
}

function bool CanBeFocusedNow()
{
	return CanBeUsedNow();
	return;
}

function string GetFocusDisplayName()
{
	return FriendlyName;
	return;
	@NULL
}

function string GetHUDMessageForFocusAttained()
{
	return GetFocusDisplayName();
	return;
}

function bool ShouldHighlightWhenFocused()
{
	return CanBeUsedNow();
	return;
}

function bool ShouldShowHelpTagWhenFocused()
{
	return true;
	return;
}

function OnFocusStarted()
{
	TriggerEffectEvent('BecameUseFocus');
	return;
}

function OnFocusStopped()
{
	UnTriggerEffectEvent('BecameUseFocus');
	return;
}

function TakeDamage(DamageStimuliSet DamageStimuli, float CritChance, Actor Damager, Vector HitLocation, Vector HitNormal, Vector HitImpulseDirection, name EffectEventName, float DamageAttenuation, name HitHighBone, name HitLowBone, optional bool WasMeleeAttack)
{
	local ShockPlayer Player;


	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0xD2
	/*@Error*/
	dispatchMessage(Class'ShockAI.MessagePlayerHitGathererVent'.static.Allocate(self)., construct_GathererVentBool(self, bPlayerCanSpawn));
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xD2
	/*@Error*/
	Player = ShockPlayer(Level.GetLocalPlayerController().Pawn);
	Player.EscortedGatherer = SpawnGatherer(Player);
	bPlayerCanSpawn = false;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function TakeScriptedDamage(DamageStimuliSet.DamageStimulusType DamageType, float DamageAmount, float DamageChance, optional Actor Damager)
{
	return;
}

defaultproperties
{
	FriendlyName="Vent"
	UseVerbText="SUMMON A LITTLE SISTER"
	GathererSpawnLocationSocketName="GathererSpawn"
	GathererEnterWithoutProtectorSocketName="GathererAloneClimbStart"
	BouncerExitWithGathererSocketName="ProtectorKneel"
	RosieExitWithGathererSocketName="ProtectorKneel"
	SPFExitWithGathererSocketName="ProtectorKneel"
	BouncerEnterWithGathererSocketName="ProtectorKneel"
	RosieEnterWithGathererSocketName="ProtectorKneel"
	SPFEnterWithGathererSocketName="ProtectorKneel"
	GathererEnterWithBouncerSocketName="GathererClimbStart"
	GathererEnterWithRosieSocketName="GathererClimbStart"
	GathererEnterWithSPFSocketName="GathererClimbStart"
	NavigationPointSocketName="PathNodePlacement"
	StaticMesh=StaticMesh'SimpleShapes.Cube256Diameter'
	bForceStaticLighting=true
	bStatic=false
	bStasis=true
	bOccludesSound=false
	bPathColliding=true
	ActorSpecificTextureWeight=8.0000000
}