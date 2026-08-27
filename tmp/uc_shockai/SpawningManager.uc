class SpawningManager extends SpawningManagerBase implements ISpawningManager, IInterestedActorDestroyed, IInterestedPawnDied
	native
	config(Spawning)
	editinlinenew
	collapsecategories
	hidecategories(Object);

var export editinline array<export editinline SpawnZoneInfo> SpawningZones;
var export editinline array<export editinline PatrolList> Patrols;
var export editinline array<export editinline AIContainerInfo> DefaultAILoot;
var const editconstarray editconst array< Class<ShockAI> > AIClassesInLevel;
var export array<export name> AIArchetypeNames;
var export editinline array<export editinline DamageSendMessageSpecifier> DamageMessageSpecifiers;
var int MaxLootableGatherers;
var bool bDontSpawnAIs;
var const array<AIArchetype> LoadedAIArchetypes;
var const transient name ArchetypeOverrideName;
var const array<AnimationCategoryEntry> AnimationCategoryEntries;
var const array<AggressorSpawner> AggressorSpawners;
var const array<ProtectorSpawner> ProtectorSpawners;
var const array<SecurityCameraSpawner> SecurityCameraSpawners;
var const array<TurretSpawner> TurretSpawners;
var const array<SecurityBotSpawner> SecurityBotSpawners;
var const array<GathererVent> GathererVents;
var const array<IBooty> Booty;
var const array<TeleportPoint> TeleportPoints;
var const array<HealthStation> HealthStations;
var const array<Actor> InterestingObjectsForGatherers;
var const array<Aggressor> SpawnedAggressors;
var const array<Protector> SpawnedProtectors;
var const array<Gatherer> SpawnedGatherers;
var const array<SecurityElement> SpawnedSecurityElements;
var const array<SecurityBot> SpawnedSecurityBots;
var const array<SecurityCamera> SpawnedSecurityCameras;
var const array<Turret> SpawnedTurrets;
var const DecoyHumanAI SpawnedDecoyHumanAI;
var const array<InsectSwarm> SpawnedInsectSwarms;
var private LevelInfo Level;
var private name NextSecurityBotSpawnLocationLabel;
var private int NumEcologyFightersThatCanSeePlayer;
var private const bool bInitialAIsSpawned;
var private ShockAIScout GameScout;
var private bool bRepopulationEnabled;
var private int NumLootedGatherers;
var private config Range PlayerSecurityBotSpawnRange;
var private config Range AISecurityBotSpawnRange;
var config array<name> ArchetypeNames;
var config array<name> AnimationCategoryNames;
var private config float DistanceForAggressorsToNoticeAttacks;
var private config float DistanceForAggressorsToJoinInvestigation;
var private config float DistanceForProtectorsToNoticeAttacks;
var private config int MaxNumberOfInsectSwarmsInWorld;
var private config int MaxNumberOfDormantSecurityBotsInWorld;
var private config float BotForcedDestroyTime;
var private SecurityBot LastBotToEnterTestMode;
var(SecurityBotHackInfo) name MinimumSecurityBotHackInfoName;
var(SecurityBotHackInfo) name MediumSecurityBotHackInfoName;
var(SecurityBotHackInfo) name MaximumSecurityBotHackInfoName;

function string DisplaySpawningZones(SpawnZoneInfo SpawnZone)
{
	log(,, __NFUN_112__(__NFUN_112__(__NFUN_112__("SpawnZone is: ", string(SpawnZone)), " SpawnZone.SpawnZoneName is: "), string(SpawnZone.SpawnZoneName)));
	// End:0x8A
	if(__NFUN_119__(SpawnZone, none))
	{
		return string(SpawnZone.SpawnZoneName);
		goto J0x91;
		return "None";
		return;
		@NULL
		CommanderAction
		CommanderAction
	}
	@NULL
}

function OutputSpawnZonesToBox(LevelInfo Level, out array<name> S)
{
	local int i;

	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x66
	/*@Error*/
	S[S.Length] = SpawningZones[i].SpawnZoneName;
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x0B;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function string DisplayPatrols(PatrolList Patrol)
{
	// End:0x2B
	if(__NFUN_119__(Patrol, none))
	{
		return string(Patrol.PatrolName);
		goto J0x32;
		return "None";
		return;
		@NULL
	}
	CommanderAction
	J0x32:

	CommanderAction
}

function OutputPatrolsToBox(LevelInfo Level, out array<name> S)
{
	local int i;

	S[0] = 'None';
	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xC3
	/*@Error*/
	S[__NFUN_146__(i, 1)] = SpawningManager(Level.SpawningManager).Patrols[i].PatrolName;
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x20;
	return;
	@NULL
	CommanderAction
	Class'ShockAI.CommanderAction'
	@NULL
}

function string DisplayArchetypeInfo(AIArchetype Archetype)
{
	return __NFUN_112__(__NFUN_112__(__NFUN_112__("A ", string(Archetype.AIType.Name)), " using the mesh "), string(Archetype.Mesh.Name));
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function OutputArchetypesToBox(LevelInfo Level, out array<name> S)
{
	local int i;

	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x59
	/*@Error*/
	S[S.Length] = ArchetypeNames[i];
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x0B;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function OutputAnimationCategories(LevelInfo Level, out array<name> S)
{
	S = AnimationCategoryNames;
	return;
	@NULL
	CommanderAction
}

function string DisplayAITypeName(Class<ShockAI> AIClass)
{
	// End:0x2B
	if(__NFUN_119__(AIClass, none))
	{
		return string(AIClass.Name);
		goto J0x3B;
		return "Class Not Set";
	}
	return;
	@NULL
	CommanderAction
	J0x3B:

	CommanderAction
}

function AllHackInfoNames(LevelInfo Level, out array<name> S)
{
	local int i;
	local HackInfoList HackInfoList;

	HackInfoList = Class'ShockGame.HackInfoList'.static.Allocate(self).;
	Construct_Void();
	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xA3
	/*@Error*/
	S[i] = HackInfoList.HackInfoName[i];
	__NFUN_165__(i);
	// [Loop Continue]
	goto J0x3C;
	HackInfoList.__NFUN_200__();
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function DisplayAggressorTypes(LevelInfo Level, out array< Class<ShockAI> > S, optional bool bDisplayAbstractClasses)
{
	//native.Level;
	//native.S;
	//native.bDisplayAbstractClasses;	
	@NULL
	@NULL
	return default.@NULL;
}

function DisplayProtectorTypes(LevelInfo Level, out array< Class<ShockAI> > S, optional bool bDisplayAbstractClasses)
{
	//native.Level;
	//native.S;
	//native.bDisplayAbstractClasses;	
	@NULL
	@NULL
	return default.@NULL;
}

function DisplaySecurityCameraTypes(LevelInfo Level, out array< Class<ShockAI> > S, optional bool bDisplayAbstractClasses)
{
	//native.Level;
	//native.S;
	//native.bDisplayAbstractClasses;	
	@NULL
	@NULL
	return default.@NULL;
}

function DisplaySecurityBotTypes(LevelInfo Level, out array< Class<ShockAI> > S, optional bool bDisplayAbstractClasses)
{
	//native.Level;
	//native.S;
	//native.bDisplayAbstractClasses;	
	@NULL
	@NULL
	return default.@NULL;
}

function DisplayTurretTypes(LevelInfo Level, out array< Class<ShockAI> > S, optional bool bDisplayAbstractClasses)
{
	//native.Level;
	//native.S;
	//native.bDisplayAbstractClasses;	
	@NULL
	@NULL
	return default.@NULL;
}

function DisplayAllAITypes(LevelInfo Level, out array< Class<ShockAI> > S, optional bool bDisplayAbstractClasses)
{
	//native.Level;
	//native.S;
	//native.bDisplayAbstractClasses;	
	@NULL
	@NULL
	return default.@NULL;
}

function DisplayAbstractAITypes(LevelInfo Level, out array< Class<ShockAI> > S)
{
	//native.Level;
	//native.S;	
	@NULL
	@NULL
}

function Initialize(LevelInfo inLevel)
{
	// End:0x31
	if(__NFUN_114__(Level, none))
	{
		assert(__NFUN_119__(inLevel, none));
		Level = inLevel;
		PopulateArchetypes();
		PopulateAnimationCategories();
	}
	Level.RegisterNotifyPawnDied(self);
	Level.RegisterNotifyActorDestroyed(self);
	ValidateCachedActors();
	DestroyGameScout();
	SpawnInitialAIs();
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

// Export USpawningManager::execDestroyGameScout(FFrame&, void* const)
native function DestroyGameScout();

// Export USpawningManager::execValidateCachedActors(FFrame&, void* const)
native function ValidateCachedActors();

function RetainRequiredAnimationGroups()
{
	RetainRequiredAnimationGroupsNative();
	return;
}

// Export USpawningManager::execRetainRequiredAnimationGroupsNative(FFrame&, void* const)
native function RetainRequiredAnimationGroupsNative();

// Export USpawningManager::execSpawnInitialAIs(FFrame&, void* const)
native function SpawnInitialAIs();

// Export USpawningManager::execPopulateArchetypes(FFrame&, void* const)
private native function PopulateArchetypes();

// Export USpawningManager::execPopulateAnimationCategories(FFrame&, void* const)
private native function PopulateAnimationCategories();

function name GetAnimationByCategory(Class AIClass, name AnimationCategory)
{
	//native.AIClass;
	//native.AnimationCategory;	
	@NULL
	@NULL
}

function SetRepopulationEnabled(bool inRepopulationEnabled)
{
	bRepopulationEnabled = inRepopulationEnabled;
	return;
	@NULL
	CommanderAction
}

function bool IsRepopulationEnabled()
{
	return bRepopulationEnabled;
	return;
	@NULL
}

function AddBooty(IBooty BootyToAdd)
{
	//native.BootyToAdd;	
	@NULL
}

function RemoveBooty(IBooty BootyToRemove)
{
	//native.BootyToRemove;	
	@NULL
}

function UpdateBootyZone(IBooty BootyToMove, ZoneInfo NewZone)
{
	//native.BootyToMove;
	//native.NewZone;	
	@NULL
	@NULL
}

function NotifyAISpawned(Pawn AI)
{
	//native.AI;	
	@NULL
}

function OnOtherActorDestroyed(Actor ActorBeingDestroyed)
{
	//native.ActorBeingDestroyed;	
	@NULL
}

function OnOtherPawnDied(Pawn DeadPawn)
{
	//native.DeadPawn;	
	@NULL
}

function int GetNumAIsInSpawnZone(Class<ShockAI> AIType, name SpawnZoneName)
{
	//native.AIType;
	//native.SpawnZoneName;	
	@NULL
	@NULL
}

// Export USpawningManager::execCanSpawnNewGatherer(FFrame&, void* const)
native function bool CanSpawnNewGatherer();

function int GetNumSpawnZones()
{
	return SpawningZones.Length;
	return;
	@NULL
}

function name GetSpawnZoneByIndex(int Index)
{
	// End:0x4D
	if(__NFUN_130__(__NFUN_153__(Index, 0), __NFUN_150__(Index, SpawningZones.Length)))
	{
		return SpawningZones[Index].SpawnZoneName;
		goto J0x57;
		return 'NoSpawnZonesFound';
		return;
		@NULL
		CommanderAction
		CommanderAction
	}
	@NULL
}

function SpawnZoneInfo GetSpawnZoneByName(name SpawnZoneName)
{
	//native.SpawnZoneName;	
	@NULL
}

function AssignLootContainerToAI(ShockAI AI)
{
	//native.AI;	
	@NULL
}

function ShockAI SpawnScriptedAI(Class<ShockAI> AIClass, name SpawnLocationLabel, name AILabel, Container LootContainer, name PatrolName, float MinRadiusToSpawnAroundSpawnLoc, float MaxRadiusToSpawnAroundSpawnLoc, bool bShouldStartAsMimic, Range ProtectorGuardRange, name OverriddenArchetypeName, bool bCorpseCanBeRemoved, bool bForceSpawn)
{
	//native.AIClass;
	//native.SpawnLocationLabel;
	//native.AILabel;
	//native.LootContainer;
	//native.PatrolName;
	//native.MinRadiusToSpawnAroundSpawnLoc;
	//native.MaxRadiusToSpawnAroundSpawnLoc;
	//native.bShouldStartAsMimic;
	//native.ProtectorGuardRange;
	//native.OverriddenArchetypeName;
	//native.bCorpseCanBeRemoved;
	//native.bForceSpawn;	
	@NULL
	@NULL
	return default.@NULL;
}

function SetArchetypeOverrideName(name OverriddenArchetypeName)
{
	//native.OverriddenArchetypeName;	
	@NULL
}

function SetSecurityBotSpawnLocationLabel(name inNextSecurityBotSpawnLocationLabel)
{
	NextSecurityBotSpawnLocationLabel = inNextSecurityBotSpawnLocationLabel;
	return;
	@NULL
	CommanderAction
}

function SetAggressorRepopulationEnabledInSpawnZone(name SpawnZoneName, bool bAggressorRepopulationEnabled)
{
	//native.SpawnZoneName;
	//native.bAggressorRepopulationEnabled;	
	@NULL
	@NULL
}

function SetProtectorRepopulationEnabledInSpawnZone(name SpawnZoneName, bool bProtectorRepopulationEnabled)
{
	//native.SpawnZoneName;
	//native.bProtectorRepopulationEnabled;	
	@NULL
	@NULL
}

function ResetAIAggressionTowards(Pawn Target)
{
	local int i;
	local Pawn Iter;


	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0xF7
	/*@Error*/
	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xF7
	/*@Error*/
	Iter = Level.PawnList[i];
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xE9
	/*@Error*/
	EcologyFighter(Iter).ResetAttackTarget(ShockPawn(Target));
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x27;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

// Export USpawningManager::execIncrementLootableGatherers(FFrame&, void* const)
native function IncrementLootableGatherers();

function DisableAllAIsExcept(Pawn Target)
{
	//native.Target;	
	@NULL
}

// Export USpawningManager::execEnableAllAIs(FFrame&, void* const)
native function EnableAllAIs();

function NotifyNearbyProtectorsOfAttackOnPerceivedGatherer(Pawn Player, Actor Damager)
{
	local int i;
	local Protector Iter;
	local ShockPawn ShockPawnDamager;

	assert(__NFUN_119__(Player, none));
	assert(Player.__NFUN_303__('ShockPlayer'));
	ShockPawnDamager = ShockPawn(Damager);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x131
	/*@Error*/
	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x131
	/*@Error*/
	Iter = SpawnedProtectors[i];
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x123
	/*@Error*/
	Iter.NotifyAttackDamagerOfPerceivedGatherer(ShockPawnDamager);
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x61;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function AddEcologyFighterThatCanSeePlayer()
{
	__NFUN_165__(NumEcologyFightersThatCanSeePlayer);
	return;
	@NULL
}

function RemoveEcologyFighterThatCanSeePlayer()
{
	__NFUN_166__(NumEcologyFightersThatCanSeePlayer);
	assert(__NFUN_153__(NumEcologyFightersThatCanSeePlayer, 0));
	return;
	@NULL
	CommanderAction
}

// Export USpawningManager::execCanAnyEcologyFighterSeePlayer(FFrame&, void* const)
native event bool CanAnyEcologyFighterSeePlayer();

function PostAIEventNotification(AIEventNotification Event)
{
	local int i;

	i = 0;
	// End:0xFB
	if(__NFUN_150__(i, SpawnedAggressors.Length))
	{
		// End:0xED
		if(__NFUN_130__(__NFUN_119__(SpawnedAggressors[i], Event.SourceActor), IsPointWithinCylinder(SpawnedAggressors[i].Location, Event.GetLocation(), Event.Radius, Event.Height)))
		{
			SpawnedAggressors[i].HandleAIEventNotification(Event);
			__NFUN_163__(i);
			// [Loop Continue]
			goto J0x0B;
			i = 0;
			// End:0x1F6
			if(__NFUN_150__(i, SpawnedProtectors.Length))
			{
				// End:0x1E8
				if(__NFUN_130__(__NFUN_119__(SpawnedProtectors[i], Event.SourceActor), IsPointWithinCylinder(SpawnedProtectors[i].Location, Event.GetLocation(), Event.Radius, Event.Height)))
				{
				}
			}
			SpawnedProtectors[i].HandleAIEventNotification(Event);
			__NFUN_163__(i);
			// [Loop Continue]
			goto J0x106;
			i = 0;
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x2F1
			/*@Error*/
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x2E3
			/*@Error*/
			SpawnedGatherers[i].HandleAIEventNotification(Event);
		}
	}
	__NFUN_163__(i);	
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function NotifyAggressorIsAttacking(Aggressor AI, ShockPawn AttackTarget)
{
	//native.AI;
	//native.AttackTarget;	
	@NULL
	@NULL
}

function NotifyAggressorIsInvestigating(Aggressor AI, Vector InvestigateLocation, Vector InvestigateDirection)
{
	//native.AI;
	//native.InvestigateLocation;
	//native.InvestigateDirection;	
	@NULL
	@NULL
	return default.@NULL;
}

function NotifyProtectorIsAttacking(Protector AI, ShockPawn AttackTarget)
{
	//native.AI;
	//native.AttackTarget;	
	@NULL
	@NULL
}

function SendPawnTookDamageMessages(Pawn Damagee, Actor Damager)
{
	local int i;

	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x1E1
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x1D3
	/*@Error*/
	Damagee.dispatchMessage(Class'ShockGame.MessagePawnTookDamage'.static.Allocate(self)., construct_ShockPawnActor(ShockPawn(Damagee), Damager));
	goto J0x1E1;
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x0B;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

// Export USpawningManager::execGetGameScout(FFrame&, void* const)
native function ShockAIScout GetGameScout();

function MaxOutAIHealth()
{
	local int i;

	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x7D
	/*@Error*/
	AIClassesInLevel[i].default.Health = 1000000.0000000;
	AIClassesInLevel[i].default.MaxHealth = 1000000.0000000;
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x0B;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function BotEnterTestMode(name BotLabel)
{
	local SecurityBot FoundBot;

	log(,, "Finding bot");
	FoundBot = SecurityBot(Level.findByLabel(Class'ShockAI.SecurityBot', BotLabel));
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xA5
	/*@Error*/
	log(,, __NFUN_112__("Found ", string(FoundBot)));
	LastBotToEnterTestMode = FoundBot;
	LastBotToEnterTestMode.EnterTestMode();
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function BotGoToLocation(name ActorLocationLabel)
{
	local Actor foundActor;


	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x6F
	/*@Error*/
	foundActor = Level.findByLabel(Class'Engine.Actor', ActorLocationLabel);
	LastBotToEnterTestMode.TestGoToLocation(foundActor.Location);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function BotFakeAttackPawn(name PawnLabel)
{
	local ShockPawn foundPawn;


	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x6B
	/*@Error*/
	foundPawn = ShockPawn(Level.findByLabel(Class'ShockGame.ShockPawn', PawnLabel));
	LastBotToEnterTestMode.FakeAttackPawn(foundPawn);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function int GetMaxLootableGatherers()
{
	return MaxLootableGatherers;
	return;
	@NULL
}

defaultproperties
{
	MaxLootableGatherers=3
	bRepopulationEnabled=true
	PlayerSecurityBotSpawnRange=(Min=3000.0000000,Max=6000.0000000)
	AISecurityBotSpawnRange=(Min=1500.0000000,Max=4000.0000000)
	ArchetypeNames[0]="Gatherer"
	ArchetypeNames[1]="GathererRobot"
	ArchetypeNames[2]="TheaterGatherer"
	ArchetypeNames[3]="PlayerEscortedGatherer"
	ArchetypeNames[4]="PlayerEscortedGathererDLCCombat"
	ArchetypeNames[5]="PlayingGatherer"
	ArchetypeNames[6]="GathererHoldDoor"
	ArchetypeNames[7]="GathererMedical"
	ArchetypeNames[8]="ScriptedGathererMedical"
	ArchetypeNames[9]="GathererMarket"
	ArchetypeNames[10]="ScriptedGathererRYAN"
	ArchetypeNames[11]="GathererStuckUnderRosie"
	ArchetypeNames[12]="InvisibleGatherer"
	ArchetypeNames[13]="Ghost"
	ArchetypeNames[14]="Bouncer"
	ArchetypeNames[15]="BouncerElite"
	ArchetypeNames[16]="Rosie"
	ArchetypeNames[17]="RosieElite"
	ArchetypeNames[18]="UnderwaterRosie"
	ArchetypeNames[19]="SPF"
	ArchetypeNames[20]="SPFElite"
	ArchetypeNames[21]="TheaterBouncer"
	ArchetypeNames[22]="MedicalBouncer"
	ArchetypeNames[23]="MedicalBouncerTennenbaum"
	ArchetypeNames[24]="SPFHoldDoor"
	ArchetypeNames[25]="GauntletBouncer"
	ArchetypeNames[26]="BouncerEliteEngineering"
	ArchetypeNames[27]="BabyJaneCeilingCrawler"
	ArchetypeNames[28]="ToastyCeilingCrawler"
	ArchetypeNames[29]="WadersCeilingCrawler"
	ArchetypeNames[30]="RosebudCeilingCrawler"
	ArchetypeNames[31]="BreadwinnerCeilingCrawler"
	ArchetypeNames[32]="WadersLifeDrainCeilingCrawler"
	ArchetypeNames[33]="ToastyLifeDrainCeilingCrawler"
	ArchetypeNames[34]="BabyJaneLifeDrainCeilingCrawler"
	ArchetypeNames[35]="RosebudLifeDrainCeilingCrawler"
	ArchetypeNames[36]="ScienceToastyLifeDrainCeilingCrawler"
	ArchetypeNames[37]="ScienceRosebudLifeDrainCeilingCrawler"
	ArchetypeNames[38]="GauntletToastyLifeDrainCeilingCrawler"
	ArchetypeNames[39]="GauntletBabyJaneLifeDrainCeilingCrawler"
	ArchetypeNames[40]="TheArtist"
	ArchetypeNames[41]="BabyJaneSubbayCeilingCrawler"
	ArchetypeNames[42]="BabyJaneWelcomeCeilingCrawler"
	ArchetypeNames[43]="WelcomeRosebudCeilingCrawler"
	ArchetypeNames[44]="CrispyCeilingCrawler"
	ArchetypeNames[45]="FisheriesBabyJaneCeilingCrawler"
	ArchetypeNames[46]="FisheriesRosebudCeilingCrawler"
	ArchetypeNames[47]="FisheriesAmbushRosebudCeilingCrawler"
	ArchetypeNames[48]="FisheriesUberAmbushRosebudCeilingCrawler"
	ArchetypeNames[49]="FisheriesWadersCeilingCrawler"
	ArchetypeNames[50]="RecreationToastyCeilingCrawler"
	ArchetypeNames[51]="RecreationToastyCeilingCrawlerSPIDER"
	ArchetypeNames[52]="RecreationToastyCeilingCrawlerBUNNY"
	ArchetypeNames[53]="RecreationBabyJaneCeilingCrawler"
	ArchetypeNames[54]="RecreationBabyJaneCeilingCrawlerBUNNY"
	ArchetypeNames[55]="RecreationBabyJaneCeilingCrawlerSPIDER"
	ArchetypeNames[56]="RecreationBabyJaneCeilingCrawlerKITTEN"
	ArchetypeNames[57]="RecreationBabyJaneCeilingCrawlerBUTTERFLY"
	ArchetypeNames[58]="RecreationBreadwinnerCeilingCrawler"
	ArchetypeNames[59]="RecreationBreadwinnerCeilingCrawlerBUTTERFLY"
	ArchetypeNames[60]="EngineeringWadersCeilingCrawler"
	ArchetypeNames[61]="EngineeringRosebudCeilingCrawler"
	ArchetypeNames[62]="TestToastyCeilingCrawler"
	ArchetypeNames[63]="EbonyCeilingCrawler"
	ArchetypeNames[64]="IvoryCeilingCrawler"
	ArchetypeNames[65]="ToastyMelee"
	ArchetypeNames[66]="ToastyMeleeDLC"
	ArchetypeNames[67]="WadersMelee"
	ArchetypeNames[68]="PigskinMelee"
	ArchetypeNames[69]="DoctorMelee"
	ArchetypeNames[70]="DuckyMelee"
	ArchetypeNames[71]="BreadwinnerMelee"
	ArchetypeNames[72]="BabyJaneMelee"
	ArchetypeNames[73]="LadySmithMelee"
	ArchetypeNames[74]="RosebudMelee"
	ArchetypeNames[75]="WelcomeToastyMelee"
	ArchetypeNames[76]="WelcomeLadySmithMelee"
	ArchetypeNames[77]="WelcomeHiddenThug"
	ArchetypeNames[78]="WelcomeRosebudMelee"
	ArchetypeNames[79]="WelcomeBurningMelee"
	ArchetypeNames[80]="ToastyElectrifiedMelee"
	ArchetypeNames[81]="FatToastyElectrifiedMelee"
	ArchetypeNames[82]="WadersElectrifiedMelee"
	ArchetypeNames[83]="PigskinElectrifiedMelee"
	ArchetypeNames[84]="DoctorElectrifiedMelee"
	ArchetypeNames[85]="DuckyElectrifiedMelee"
	ArchetypeNames[86]="BreadwinnerElectrifiedMelee"
	ArchetypeNames[87]="RosebudElectrifiedMelee"
	ArchetypeNames[88]="BabyJaneElectrifiedMelee"
	ArchetypeNames[89]="LadySmithElectrifiedMelee"
	ArchetypeNames[90]="ResidentialLadySmithElectrifiedMelee"
	ArchetypeNames[91]="ResidentialDuckyElectrifiedMelee"
	ArchetypeNames[92]="ResidentialBreadwinnerElectrifiedMelee"
	ArchetypeNames[93]="SlumsToastyElectrifiedMeleeBUFF"
	ArchetypeNames[94]="SlumsWadersElectrifiedMelee"
	ArchetypeNames[95]="SlumsBabyJaneElectrifiedMelee"
	ArchetypeNames[96]="SlumsDuckyElectrifiedMelee"
	ArchetypeNames[97]="SlumsDuckyElectrifiedMelee"
	ArchetypeNames[98]="BabyJaneHarlequinMelee"
	ArchetypeNames[99]="LadySmithNurseMelee"
	ArchetypeNames[100]="ToastyWelcomeMelee"
	ArchetypeNames[101]="MedicalDoctorMelee"
	ArchetypeNames[102]="MedicalDoctorMeleeCRC"
	ArchetypeNames[103]="MedicalDoctorMeleeNoRunAway"
	ArchetypeNames[104]="MedicalMeleeForTennenbaum"
	ArchetypeNames[105]="ToastyMedicalMelee"
	ArchetypeNames[106]="MedicalBabyJaneMelee"
	ArchetypeNames[107]="MedicalBabyJaneMeleeNoRunAway"
	ArchetypeNames[108]="TheaterToasty"
	ArchetypeNames[109]="WelcomeShockedGuy"
	ArchetypeNames[110]="MedicalLadySmithMelee"
	ArchetypeNames[111]="MedicalLadySmithMeleeNoRunAway"
	ArchetypeNames[112]="MedicalLadySmithNurseMelee"
	ArchetypeNames[113]="ArcadiaLadySmithMelee"
	ArchetypeNames[114]="ArcadiaDoctorMelee"
	ArchetypeNames[115]="ArcadiaBreadwinnerMelee"
	ArchetypeNames[116]="ArcadiaDoctorWeldMaskMelee"
	ArchetypeNames[117]="ArcadiaLadySmithWeldMaskMelee"
	ArchetypeNames[118]="ArcadiaBreadwinnerWeldMaskMelee"
	ArchetypeNames[119]="MarketPigskinMelee"
	ArchetypeNames[120]="MarketWadersMelee"
	ArchetypeNames[121]="MarketBabyJaneMelee"
	ArchetypeNames[122]="DEMOFisheriesRosebudMelee"
	ArchetypeNames[123]="DEMOFisheriesWadersMelee"
	ArchetypeNames[124]="DEMOFisheriesDuckyMelee"
	ArchetypeNames[125]="RecreationToastyMelee"
	ArchetypeNames[126]="RecreationToastyMeleeBUNNY"
	ArchetypeNames[127]="RecreationBabyJaneMelee"
	ArchetypeNames[128]="RecreationBabyJaneMeleeBUNNY"
	ArchetypeNames[129]="RecreationBreadwinnerMelee"
	ArchetypeNames[130]="RecreationBreadwinnerMeleeDLC"
	ArchetypeNames[131]="Charley"
	ArchetypeNames[132]="Brenda"
	ArchetypeNames[133]="BabyCarriage"
	ArchetypeNames[134]="EngineeringWadersElectrifiedMelee"
	ArchetypeNames[135]="EngineeringRosebudElectrifiedMelee"
	ArchetypeNames[136]="EngineeringDuckyElectrifiedMelee"
	ArchetypeNames[137]="ScienceToastyElectrifiedMelee"
	ArchetypeNames[138]="ScienceRosebudElectrifiedMelee"
	ArchetypeNames[139]="ScienceDoctorElectrifiedMelee"
	ArchetypeNames[140]="GauntletBabyJaneElectrifiedMelee"
	ArchetypeNames[141]="GauntletDoctorElectrifiedMelee"
	ArchetypeNames[142]="GauntletToastyElectrifiedMelee"
	ArchetypeNames[143]="ToastyGrenadier"
	ArchetypeNames[144]="DoctorGrenadier"
	ArchetypeNames[145]="DoctorSteinmanGrenadier"
	ArchetypeNames[146]="DuckyGrenadier"
	ArchetypeNames[147]="WadersGrenadier"
	ArchetypeNames[148]="PigskinGrenadier"
	ArchetypeNames[149]="BreadwinnerGrenadier"
	ArchetypeNames[150]="RosebudGrenadier"
	ArchetypeNames[151]="BabyJaneGrenadier"
	ArchetypeNames[152]="LadySmithGrenadier"
	ArchetypeNames[153]="ToastyMolotov"
	ArchetypeNames[154]="DoctorMolotov"
	ArchetypeNames[155]="WadersMolotov"
	ArchetypeNames[156]="PigskinMolotov"
	ArchetypeNames[157]="DuckyMolotov"
	ArchetypeNames[158]="RosebudMolotov"
	ArchetypeNames[159]="BabyJaneMolotov"
	ArchetypeNames[160]="LadySmithMolotov"
	ArchetypeNames[161]="BreadwinnerMolotov"
	ArchetypeNames[162]="CrispyMolotov"
	ArchetypeNames[163]="MedicalDoctorGrenadier"
	ArchetypeNames[164]="MedicalDoctorGrenadier_NoBurningAnims"
	ArchetypeNames[165]="FisheriesRosebudGrenadier"
	ArchetypeNames[166]="DEMOFisheriesRosebudGrenadier"
	ArchetypeNames[167]="FisheriesWadersGrenadier"
	ArchetypeNames[168]="DEMOFisheriesWadersGrenadier"
	ArchetypeNames[169]="FisheriesDuckyGrenadier"
	ArchetypeNames[170]="DEMOFisheriesDuckyGrenadier"
	ArchetypeNames[171]="RecreationToastyMolotov"
	ArchetypeNames[172]="RecreationBabyJaneMolotov"
	ArchetypeNames[173]="RecreationBreadwinnerMolotov"
	ArchetypeNames[174]="RecreationBreadwinnerMolotovSPIDER"
	ArchetypeNames[175]="ResidentialLadySmithMolotov"
	ArchetypeNames[176]="ResidentialDuckyMolotov"
	ArchetypeNames[177]="ResidentialBreadwinnerMolotov"
	ArchetypeNames[178]="SlumsToastyMolotov"
	ArchetypeNames[179]="SlumsWadersMolotov"
	ArchetypeNames[180]="SlumsBabyJaneMolotov"
	ArchetypeNames[181]="SlumsDuckyMolotov"
	ArchetypeNames[182]="GauntletBabyJaneMolotov"
	ArchetypeNames[183]="GauntletDoctorMolotov"
	ArchetypeNames[184]="GauntletToastyMolotov"
	ArchetypeNames[185]="Peaches"
	ArchetypeNames[186]="ToastySMG"
	ArchetypeNames[187]="DoctorSMG"
	ArchetypeNames[188]="WadersSMG"
	ArchetypeNames[189]="PigskinSMG"
	ArchetypeNames[190]="DuckySMG"
	ArchetypeNames[191]="DuckyGreenSMG"
	ArchetypeNames[192]="DuckyRedSMG"
	ArchetypeNames[193]="DuckyWhiteSMG"
	ArchetypeNames[194]="BreadwinnerSMG"
	ArchetypeNames[195]="BabyJaneSMG"
	ArchetypeNames[196]="LadySmithSMG"
	ArchetypeNames[197]="RosebudSMG"
	ArchetypeNames[198]="DoctorSteinman"
	ArchetypeNames[199]="SteinmanPatient"
	ArchetypeNames[200]="MedicalToastySMG"
	ArchetypeNames[201]="MedicalToastySMGDLC"
	ArchetypeNames[202]="EngineeringWadersSMG"
	ArchetypeNames[203]="EngineeringRosebudSMG"
	ArchetypeNames[204]="EngineeringDuckySMG"
	ArchetypeNames[205]="EngineeringDuckyGreenSMG"
	ArchetypeNames[206]="EngineeringDuckyRedSMG"
	ArchetypeNames[207]="EngineeringDuckyWhiteSMG"
	ArchetypeNames[208]="ResidentialLadySmithSMG"
	ArchetypeNames[209]="ResidentialDuckySMG"
	ArchetypeNames[210]="ResidentialDuckyGreenSMG"
	ArchetypeNames[211]="ResidentialDuckyRedSMG"
	ArchetypeNames[212]="ResidentialDuckyWhiteSMG"
	ArchetypeNames[213]="ResidentialBreadwinnerSMG"
	ArchetypeNames[214]="SlumsToastySMG"
	ArchetypeNames[215]="SlumsBabyJaneSMG"
	ArchetypeNames[216]="SlumsWadersSMG"
	ArchetypeNames[217]="SlumsWadersSMGBUFF"
	ArchetypeNames[218]="SlumsDuckySMG"
	ArchetypeNames[219]="SlumsDuckySMGBUFF"
	ArchetypeNames[220]="SlumsDuckyGreenSMG"
	ArchetypeNames[221]="SlumsDuckyRedSMG"
	ArchetypeNames[222]="SlumsDuckyWhiteSMG"
	ArchetypeNames[223]="ScienceToastySMG"
	ArchetypeNames[224]="ScienceRosebudSMG"
	ArchetypeNames[225]="ScienceDoctorSMG"
	ArchetypeNames[226]="GauntletToastySMG"
	ArchetypeNames[227]="GauntletDoctorSMG"
	ArchetypeNames[228]="GauntletBabyJaneSMG"
	ArchetypeNames[229]="ToastyPISTOL"
	ArchetypeNames[230]="DoctorPISTOL"
	ArchetypeNames[231]="DuckyPISTOL"
	ArchetypeNames[232]="WadersPISTOL"
	ArchetypeNames[233]="PigskinPISTOL"
	ArchetypeNames[234]="BreadwinnerPISTOL"
	ArchetypeNames[235]="BabyJanePISTOL"
	ArchetypeNames[236]="LadySmithPISTOL"
	ArchetypeNames[237]="RosebudPISTOL"
	ArchetypeNames[238]="HumanAtlas"
	ArchetypeNames[239]="HumanAtlasScience"
	ArchetypeNames[240]="MedicalDoctorPISTOL"
	ArchetypeNames[241]="MedicalBabyJanePISTOL"
	ArchetypeNames[242]="MedicalLadySmithPISTOL"
	ArchetypeNames[243]="MedicalLadySmithNursePISTOL"
	ArchetypeNames[244]="FisheriesRosebudPISTOL"
	ArchetypeNames[245]="DEMOFisheriesRosebudPISTOL"
	ArchetypeNames[246]="FisheriesWadersPISTOL"
	ArchetypeNames[247]="DEMOFisheriesWadersPISTOL"
	ArchetypeNames[248]="FisheriesDuckyPISTOL"
	ArchetypeNames[249]="DEMOFisheriesDuckyPISTOL"
	ArchetypeNames[250]="ArcadiaLadySmithPISTOL"
	ArchetypeNames[251]="ArcadiaDoctorPISTOL"
	ArchetypeNames[252]="ArcadiaBreadwinnerPISTOL"
	ArchetypeNames[253]="MarketPigskinPISTOL"
	ArchetypeNames[254]="MarketWadersPISTOL"
	ArchetypeNames[255]="MarketBabyJanePISTOL"
	ArchetypeNames[256]="BrendaPISTOL"
	ArchetypeNames[257]="ToastyTeleport"
	ArchetypeNames[258]="DoctorTeleport"
	ArchetypeNames[259]="DuckyTeleport"
	ArchetypeNames[260]="WadersTeleport"
	ArchetypeNames[261]="PigskinTeleport"
	ArchetypeNames[262]="BreadwinnerTELEPORT"
	ArchetypeNames[263]="BreadwinnerArcadiaIntroTeleport"
	ArchetypeNames[264]="BreadwinnerArcadiaIntroTeleportWithMASK"
	ArchetypeNames[265]="RosebudTeleport"
	ArchetypeNames[266]="LadySmithTeleport"
	ArchetypeNames[267]="BabyJaneTeleport"
	ArchetypeNames[268]="RecHiddenTeleport"
	ArchetypeNames[269]="ToastyMagicTeleport"
	ArchetypeNames[270]="DoctorMagicTeleport"
	ArchetypeNames[271]="DuckyMagicTeleport"
	ArchetypeNames[272]="WadersMagicTeleport"
	ArchetypeNames[273]="PigskinMagicTeleport"
	ArchetypeNames[274]="RosebudMagicTeleport"
	ArchetypeNames[275]="LadySmithMagicTeleport"
	ArchetypeNames[276]="BabyJaneMagicTeleport"
	ArchetypeNames[277]="ScienceToastyMagicTeleport"
	ArchetypeNames[278]="ScienceRosebudMagicTeleport"
	ArchetypeNames[279]="ScienceDoctorMagicTeleport"
	ArchetypeNames[280]="GauntletToastyMagicTeleport"
	ArchetypeNames[281]="GauntletBabyJaneMagicTeleport"
	ArchetypeNames[282]="GauntletDoctorMagicTeleport"
	ArchetypeNames[283]="LadySmithResidentialTeleport"
	ArchetypeNames[284]="LadySmithResidentialTeleportNOMASK"
	ArchetypeNames[285]="ToastyResidentialTeleport"
	ArchetypeNames[286]="ToastyResidentialTeleportNOMASK"
	ArchetypeNames[287]="CrispyTeleport"
	ArchetypeNames[288]="CrispyMagicTeleport"
	ArchetypeNames[289]="ArcadiaLadySmithTeleport"
	ArchetypeNames[290]="ArcadiaDoctorTeleport"
	ArchetypeNames[291]="ArcadiaBreadwinnerTELEPORT"
	ArchetypeNames[292]="MarketPigskinTeleport"
	ArchetypeNames[293]="MarketWadersTeleport"
	ArchetypeNames[294]="MarketBabyJaneTeleport"
	ArchetypeNames[295]="RecreationToastyTeleport"
	ArchetypeNames[296]="RecreationBabyJaneTeleport"
	ArchetypeNames[297]="RecreationBabyJaneTeleportBIRD"
	ArchetypeNames[298]="RecreationBreadwinnerTELEPORT"
	ArchetypeNames[299]="RecreationBreadwinnerTELEPORTBIRD"
	ArchetypeNames[300]="EngineeringWadersTeleport"
	ArchetypeNames[301]="EngineeringRosebudTeleport"
	ArchetypeNames[302]="EngineeringDuckyTeleport"
	ArchetypeNames[303]="Atlas"
	ArchetypeNames[304]="CohenFriend_1"
	ArchetypeNames[305]="CohenFriend_2"
	ArchetypeNames[306]="CohenFriend_3"
	ArchetypeNames[307]="CohenFriend_4"
	ArchetypeNames[308]="Cohen"
	ArchetypeNames[309]="UltimateCohen"
	ArchetypeNames[310]="CohenResidential"
	ArchetypeNames[311]="ToastyPiano"
	ArchetypeNames[312]="TenenbaumMedical"
	AnimationCategoryNames[0]="LookOverLedge"
	AnimationCategoryNames[1]="LookOverLedgeLoop"
	AnimationCategoryNames[2]="BangDoorTurnAround"
	AnimationCategoryNames[3]="BangOnMidMachine"
	AnimationCategoryNames[4]="DoorPushLoop"
	AnimationCategoryNames[5]="SteppedInShit"
	AnimationCategoryNames[6]="KickingAtGround"
	AnimationCategoryNames[7]="KneelDownInspect"
	AnimationCategoryNames[8]="InspectingObjectAtFeet"
	AnimationCategoryNames[9]="LootingBodyLoop"
	AnimationCategoryNames[10]="PullMachineTurnAround"
	AnimationCategoryNames[11]="SwingingAtAir"
	AnimationCategoryNames[12]="BangOnHighMachineGeneric"
	AnimationCategoryNames[13]="BangOnMidMachineGeneric"
	AnimationCategoryNames[14]="BangOnLowMachineGeneric"
	AnimationCategoryNames[15]="LookingInRoomGeneric"
	AnimationCategoryNames[16]="LookingUnderDeskGeneric"
	AnimationCategoryNames[17]="ScratchingNeck"
	AnimationCategoryNames[18]="WarmingAtFire"
	DistanceForAggressorsToNoticeAttacks=1000.0000000
	DistanceForAggressorsToJoinInvestigation=1000.0000000
	DistanceForProtectorsToNoticeAttacks=1000.0000000
	MaxNumberOfInsectSwarmsInWorld=2
	MaxNumberOfDormantSecurityBotsInWorld=7
	BotForcedDestroyTime=10.0000000
	MinimumSecurityBotHackInfoName="SecurityBotDefault"
	MediumSecurityBotHackInfoName="SecurityBotDefault"
	MaximumSecurityBotHackInfoName="SecurityBotDefault"
}