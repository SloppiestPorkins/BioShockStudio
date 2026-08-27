class ShockGameInfo extends VengeanceGameInfo
	native
	config(ShockGame)
	hidecategories(DrawScale3D,DisplayAdvanced,Movement,Collision,Lighting,LightColor,Force,Display,Havok,Advanced,Object);

const DEBUG_BALLISTICS_LINE_TIMEOUT = 8.0;
const SecurityManagerClassName = "ShockAI.SecurityManager";

var bool DebugBallistics;
var bool DebugBotMotion;
var bool DebugCanHit;
var private SecurityManagerBase SecurityManager;
var private SpawningManagerBase SpawningManager;
var private SpeechManager SpeechManager;
var private CorpseManager CorpseManager;
var array<PlantShader> PlantShaders;
var array<float> PlantShaderTransitionWeights;
var array<PlantShader> ChangedPlantShaders;
var array<float> ChangedPlantShaderWeights;
var private config int MaximumNumberOfSpringBoardTrapMarkers;
var array<SpringBoardTrapMarker> ExtantSpringBoardTrapMarkers;
var config bool bDisplayDebugInfoOnAIs;
var bool bDebugAISpeech;
var bool bDisplayPathfindingInfo;
var bool bDebugCollisionAvoidance;
var bool bDisplayAnimationInfo;
var bool bDebugAIAttacking;
var bool bShowDoubtVisionCones;
var bool bShowCertaintyVisionCones;
var bool bPlayerInvisible;
var bool bDisableIlluminationAffectingVision;
var bool bDebugIlluminationAffectingVision;
var bool bDebugVisionCones;
var bool bDebugHeadTracking;
var bool bDebugViewTriggers;
var private int NumSavedGatherersThisLevel;
var private int NumHarvestedGatherersThisLevel;
var private int NumCollectedGatherersThisLevel;
var const transient array<Actor> PhotographTargets;
var private const noexport transient TMap_Padding DamageFactoryMap;
var private const noexport transient TMap_Padding ItemClassMap;
var private const noexport transient TMap_Padding ProjectileClassMap;

function RegisterPhotographTarget(Actor Target)
{
	//native.Target;	
	@NULL
}

function UnregisterPhotographTarget(Actor Target)
{
	//native.Target;	
	@NULL
}

function GetPhotographTargets(out array<Actor> Targets)
{
	//native.Targets;	
	@NULL
}

function DamageFactory GetDamageFactory(Class<DamageFactory> DamageFactoryClass)
{
	//native.DamageFactoryClass;	
	@NULL
}

function Item GetItemFromClass(Class<Item> ItemClass)
{
	//native.ItemClass;	
	@NULL
}

function PreLevelTravel()
{
	// End:0x42
	if(__NFUN_119__(SecurityManager, none))
	{
		SecurityManager.StopAlarm();
		SecurityManager.HackSecuritySystem(0.0000000);
		super(Actor).PreLevelTravel();
		return;
		@NULL
	}
	Item
	stop;
	default.@NULL
}

function PostBeginPlay()
{
	super(GameInfo).PostBeginPlay();
	AssertWithDescription(__NFUN_255__(Level.Label, 'None'), "Dear User,  The level's label is not set.  This will cause problems.  Please fix this.  Now.  Thank you in advance!  Your humble servant, The Programming Team.");
	// End:0x13D
	if(__NFUN_114__(Level.SpawningManager, none))
	{
		__NFUN_232__("SKIPPING SPAWNING: This map has no SpawningManager in its LevelInfo.");
		goto J0x166;
		SpawningManager = SpawningManagerBase(Level.SpawningManager);
	}
	SpawnSecurityManager();
	SpawnSpeechManager();
	SpawnCorpseManager();
	return;
	@NULL
	Item
	Item
	@NULL
}

function SpawnSecurityManager()
{
	local Class<SecurityManagerBase> SecurityManagerClass;

	SecurityManagerClass = Class<SecurityManagerBase>(DynamicLoadObject("ShockAI.SecurityManager", Class'Core.Class'));
	assert(__NFUN_119__(SecurityManagerClass, none));
	SecurityManager = SecurityManagerClass.static.Allocate(self).;
	construct_LevelInfoSpawningManagerBase(Level, SpawningManager);
	assert(__NFUN_119__(SecurityManager, none));
	return;
	@NULL
	Item
	ShockPawn
	@NULL
}

function bool IsSecuritySystemActive()
{
	// End:0x27
	if(__NFUN_119__(SecurityManager, none))
	{
		return SecurityManager.IsAlarmOn();
		return false;
		return;
		@NULL
	}
	Item
}

function Pawn GetSecuritySystemTarget()
{
	// End:0x27
	if(__NFUN_119__(SecurityManager, none))
	{
		return SecurityManager.GetAlarmTarget();
		return none;
		return;
		@NULL
	}
	Item
}

function StopSecurityAlarmForLevelChange()
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x28
	/*@Error*/
	SecurityManager.StopAlarm(, true);
	return;
	@NULL
	Item
}

// Export UShockGameInfo::execGetSecurityManager(FFrame&, void* const)
native function SecurityManagerBase GetSecurityManager();

function SpawnSpeechManager()
{
	SpeechManager = Class'ShockGame.SpeechManager'.static.Allocate(self).;
	construct_LevelInfo(Level);
	assert(__NFUN_119__(SpeechManager, none));
	return;
	@NULL
	Item
	ShockPawn
	@NULL
}

function SpawnCorpseManager()
{
	CorpseManager = Class'ShockGame.CorpseManager'.static.Allocate(self).;
	construct_LevelInfo(Level);
	assert(__NFUN_119__(CorpseManager, none));
	return;
	@NULL
	Item
	ShockPawn
	@NULL
}

// Export UShockGameInfo::execGetSpeechManager(FFrame&, void* const)
native function SpeechManager GetSpeechManager();

function MakeAllPawnsInvincible(bool inInvincible)
{
	local int i;
	local ShockPawn Iter;

	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xA1
	/*@Error*/
	Iter = ShockPawn(Level.PawnList[i]);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x93
	/*@Error*/
	Iter.SetInvincible(inInvincible);
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x0B;
	return;
	@NULL
	Item
	Item
	@NULL
}

function SetUITimer(name timerType, float MaxTime, string Description)
{
	//native.timerType;
	//native.MaxTime;
	//native.Description;	
	@NULL
	@NULL
	return default.@NULL;
}

function UpdateUITimer(name timerType, float TimeRemaining)
{
	//native.timerType;
	//native.TimeRemaining;	
	@NULL
	@NULL
}

function PostLoadGame()
{
	local int i;

	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x65
	/*@Error*/
	ChangedPlantShaders[i].TransitionWeight = ChangedPlantShaderWeights[i];
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x0B;
	return;
	@NULL
	Item
	Item
	@NULL
}

function IncrementNumCollectedGatherersThisLevel()
{
	__NFUN_165__(NumCollectedGatherersThisLevel);
	return;
	@NULL
}

function IncrementNumSavedGatherersThisLevel()
{
	__NFUN_165__(NumSavedGatherersThisLevel);
	return;
	@NULL
}

function IncrementNumHarvestedGatherersThisLevel()
{
	__NFUN_165__(NumHarvestedGatherersThisLevel);
	return;
	@NULL
}

function int GetNumSavedGatherersThisLevel()
{
	return NumSavedGatherersThisLevel;
	return;
	@NULL
}

function int GetNumHarvestedGatherersThisLevel()
{
	return NumHarvestedGatherersThisLevel;
	return;
	@NULL
}

function int GetNumCollectedGatherersThisLevel()
{
	return NumCollectedGatherersThisLevel;
	return;
	@NULL
}

function int GetNumRoamingGatherersThisLevel()
{
	return __NFUN_147__(__NFUN_147__(__NFUN_147__(SpawningManager.GetMaxLootableGatherers(), NumSavedGatherersThisLevel), NumHarvestedGatherersThisLevel), NumCollectedGatherersThisLevel);
	return;
	@NULL
	Item
	Item
	@NULL
}

function Actor GetCurrentTelekinesisTarget()
{
	local TelekinesisAbility TKAbility;

	TKAbility = TelekinesisAbility(ShockPlayer(Level.GetLocalPlayerController().Pawn).GetHands().GetCurrentAbility());
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x83
	/*@Error*/
	return TKAbility.GetTarget();
	return none;
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function TempSavePlayerInventory()
{
	local ShockPlayer thePlayer;

	TempSavePlayerInventoryNative();
	thePlayer = ShockPlayer(Level.GetLocalPlayerController().Pawn);
	thePlayer.RemoveAvailableHoldable(thePlayer.GetHoldableByClassName('Pistol'));
	thePlayer.RemoveAvailableHoldable(thePlayer.GetHoldableByClassName('Shotgun'));
	thePlayer.RemoveAvailableHoldable(thePlayer.GetHoldableByClassName('MachineGun'));
	thePlayer.RemoveAvailableHoldable(thePlayer.GetHoldableByClassName('GrenadeLauncher'));
	thePlayer.RemoveAvailableHoldable(thePlayer.GetHoldableByClassName('Crossbow'));
	thePlayer.RemoveAvailableHoldable(thePlayer.GetHoldableByClassName('ChemicalThrower'));
	thePlayer.UseUpAmmo(Class'ShockGame.MachineGun_ArmorPiercingBullet', 1000);
	thePlayer.UseUpAmmo(Class'ShockGame.MachineGun_Bullet', 1000);
	thePlayer.UseUpAmmo(Class'ShockGame.MachineGun_FrozenBullet', 1000);
	thePlayer.UseUpAmmo(Class'ShockGame.Pistol_AntiPersonnel', 1000);
	thePlayer.UseUpAmmo(Class'ShockGame.Pistol_ArmorPiercing', 1000);
	thePlayer.UseUpAmmo(Class'ShockGame.Pistol_Bullet', 1000);
	thePlayer.UseUpAmmo(Class'ShockGame.Shotgun_00Buck', 1000);
	thePlayer.UseUpAmmo(Class'ShockGame.Shotgun_HighExplosiveBuck', 1000);
	thePlayer.UseUpAmmo(Class'ShockGame.Shotgun_IonicBuck', 1000);
	thePlayer.UseUpAmmo(Class'ShockGame.GrenadeLauncher_FragGrenade', 1000);
	thePlayer.UseUpAmmo(Class'ShockGame.GrenadeLauncher_RPG', 1000);
	thePlayer.UseUpAmmo(Class'ShockGame.GrenadeLauncher_StickyGrenade', 1000);
	thePlayer.UseUpAmmo(Class'ShockGame.ChemicalThrower_Kerosene', 1000);
	thePlayer.UseUpAmmo(Class'ShockGame.ChemicalThrower_LiquidNitrogen', 1000);
	thePlayer.UseUpAmmo(Class'ShockGame.ChemicalThrower_IonicGel', 1000);
	thePlayer.UseUpAmmo(Class'ShockGame.Crossbow_Bolt', 1000);
	thePlayer.UseUpAmmo(Class'ShockGame.Crossbow_TrapBolt', 1000);
	thePlayer.UseUpAmmo(Class'ShockGame.Crossbow_SuperHeatedBolt', 1000);
	return;
	@NULL
	Item
	Item
	@NULL
}

function TempLoadPlayerInventory()
{
	local ShockPlayer thePlayer;

	thePlayer = ShockPlayer(Level.GetLocalPlayerController().Pawn);
	thePlayer.RemoveAvailableHoldable(thePlayer.GetHoldableByClassName('ResearchCamera'));
	thePlayer.RemoveAvailableHoldable(thePlayer.GetHoldableByClassName('Wrench'));
	thePlayer.DontRetriggerWeaponModEffectEvents = true;
	TempLoadPlayerInventoryNative();
	thePlayer.DontRetriggerWeaponModEffectEvents = false;
	return;
	@NULL
	Item
	Item
	@NULL
}

// Export UShockGameInfo::execTempSavePlayerInventoryNative(FFrame&, void* const)
native function TempSavePlayerInventoryNative();

// Export UShockGameInfo::execTempLoadPlayerInventoryNative(FFrame&, void* const)
native function TempLoadPlayerInventoryNative();

defaultproperties
{
	MaximumNumberOfSpringBoardTrapMarkers=5
	HUDType="ShockGame.ShockHUD"
	PlayerControllerClassName="ShockGame.ShockPlayerController"
	bNeedProtectedTick=true
}