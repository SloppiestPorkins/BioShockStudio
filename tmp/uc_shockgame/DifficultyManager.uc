class DifficultyManager extends Object
	native
	config(Difficulty);

struct native atomic DifficultyFloat
{
	var float Low;
	var float Normal;
	var float High;
	var float Extreme;
};

struct native atomic DifficultyInt
{
	var int Low;
	var int Normal;
	var int High;
	var int Extreme;

	structdefaultproperties
	{
		CheckpointTypePadding=7602293
	}
};

struct native atomic ActiveRecommendation
{
	var AdjustmentRecommendation Recommendation;
	var DifficultyAdvisor Advisor;

	structdefaultproperties
	{
		CheckpointTypePadding=7602293
	}
};

struct native atomic ActiveAdjustment
{
	var DifficultyAdjustment Adjustment;
	var float Priority;
};

var private transient ShockGameDriver GameDriver;
var private config bool EnableAdaptiveDifficulty;
var private config bool EnableSessionLogging;
var config array< Class<DifficultyAdvisor> > AdvisorClasses;
var transient array<DifficultyAdvisor> Advisors;
var config array< Class<DifficultyAdjustment> > AdjustmentClasses;
var transient array<DifficultyAdjustment> Adjustments;
var config array<name> NoDifficultySpawnClassNames;
var config array<name> NoDifficultyRemoveClassNames;
var transient DifficultyStatsManager DifficultyStatsManager;
var transient pointer SessionArchive;
var transient array<ActiveRecommendation> ActiveRecommendations;
var transient array<ActiveAdjustment> ActiveAdjustments;
var bool NewSession;
var string SessionLogFileName;

function Initialize()
{
	local int i;

	log('Difficulty', 4, __NFUN_112__(__NFUN_112__("Creating ", string(AdvisorClasses.Length)), " Advisors"));
	i = 0;
	// End:0xAD
	if(__NFUN_150__(i, AdvisorClasses.Length))
	{
		Advisors[i] = AdvisorClasses[i].static.Allocate(self).;
		construct_DifficultyManager(self);
		__NFUN_163__(i);
		// [Loop Continue]
		goto J0x41;
		log('Difficulty', 4, __NFUN_112__(__NFUN_112__("Creating ", string(AdjustmentClasses.Length)), " Adjustments"));
	}
	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x15D
	/*@Error*/
	Adjustments[i] = AdjustmentClasses[i].static.Allocate(self).;
	construct_DifficultyManager(self);
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0xF1;
	StartNewSession();
	return;
	@NULL
	Item
	ShockPawn
	@NULL
}

function Construct(ShockGameDriver GameDriver)
{
	self.GameDriver = GameDriver;
	DifficultyStatsManager = Class'ShockGame.DifficultyStatsManager'.static.Allocate(self).;
	construct_DifficultyManager(self);
	Initialize();
	return;
	@NULL
	Item
	Vector
	@NULL
}

function ShockGameDriver GetGameDriver()
{
	return GameDriver;
	return;
	@NULL
}

function float GetDifficultyFloat(DifficultyFloat DifficultyFloat)
{
	local Controller Controller;
	local ShockPlayer Player;

	Controller = GameDriver.GetLevel().GetLocalPlayerController();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x10F
	/*@Error*/
	Player = ShockPlayer(Controller.Pawn);
	switch(Player.CurrentDifficultySetting)
	{
		// End:0xAC
		case 0:
			return DifficultyFloat.Low;
			// End:0xCC
			case 1:
				return DifficultyFloat.Normal;
				// End:0xEC
				case 2:
					return DifficultyFloat.High;
					// End:0x10C
					case 3:
						return DifficultyFloat.Extreme;
					// End:0xFFFF
					default:
						return 0.0000000;
						break;
				}/* !MISMATCHING REMOVE, tried Switch got Type:Case Position:0x088! */
				return;
				@NULL
				Item
				Item
				@NULL/* !MISMATCHING REMOVE, tried Case got Type:Switch Position:0x050! */
}

function int GetDifficultyInt(DifficultyInt DifficultyInt)
{
	local Controller Controller;
	local ShockPlayer Player;

	Controller = GameDriver.GetLevel().GetLocalPlayerController();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x10F
	/*@Error*/
	Player = ShockPlayer(Controller.Pawn);
	switch(Player.CurrentDifficultySetting)
	{
		// End:0xAC
		case 0:
			return DifficultyInt.Low;
			// End:0xCC
			case 1:
				return DifficultyInt.Normal;
				// End:0xEC
				case 2:
					return DifficultyInt.High;
					// End:0x10C
					case 3:
						return DifficultyInt.Extreme;
					// End:0xFFFF
					default:
						return 0;
						break;
				}/* !MISMATCHING REMOVE, tried Switch got Type:Case Position:0x088! */
				return;
				@NULL
				Item
				Item
				@NULL/* !MISMATCHING REMOVE, tried Case got Type:Switch Position:0x050! */
}

function SetAdaptiveDifficulty(bool On)
{
	EnableAdaptiveDifficulty = On;
	return;
	@NULL
	Item
}

function UpdateAdvisors(ShockPlayer Player)
{
	local int i;
	local float Ease;

	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xCF
	/*@Error*/
	Ease = float(Advisors[i].Assess(Player));
	log('Difficulty', 3, __NFUN_112__(__NFUN_112__(string(Advisors[i].Class.Name), " returned easy value of "), string(Ease)));
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x0B;
	return;
	@NULL
	Item
	ShockPawn
	@NULL
}

function DifficultyAdjustment GetDifficultyAdjustment(Class<DifficultyAdjustment> AdjustmentClass)
{
	local int i;

	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x74
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x66
	/*@Error*/
	return Adjustments[i];
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x0B;
	return;
	@NULL
	Item
	ShockPawn
	@NULL
}

function AddActiveAdjustment(DifficultyAdjustment Adjustment, float Priority)
{
	local ActiveAdjustment ActiveAdjustment;
	local int InsertIndex, i;

	ActiveAdjustment.Priority = Priority;
	ActiveAdjustment.Adjustment = Adjustment;
	i = 0;
	// End:0xF9
	if(__NFUN_150__(i, ActiveAdjustments.Length))
	{
		// End:0xEB
		if(__NFUN_114__(ActiveAdjustments[i].Adjustment, Adjustment))
		{
			// End:0xE9
			if(__NFUN_177__(Priority, ActiveAdjustments[i].Priority))
			{
				ActiveAdjustments.Remove(i, 1);
				goto J0xF9;
				goto J0xEB;
				return;
				__NFUN_163__(i);
				// [Loop Continue]
				goto J0x53;
				InsertIndex = 0;
				/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
					
				*/

				// End:0x15F
				/*@Error*/
				/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
					
				*/

				// End:0x151
				/*@Error*/
				goto J0x15F;
				__NFUN_163__(InsertIndex);
				goto J0x104;
				ActiveAdjustments.Insert(InsertIndex, 1);
				ActiveAdjustments[InsertIndex] = ActiveAdjustment;
			}
		}
		return;
	}
	@NULL
	Item
	J0x104:

	ShockPawn
	@NULL
}

function UpdateActiveAdjustments()
{
	local int i;
	local array<ActiveRecommendation> NewRecommendations;
	local ActiveRecommendation NewRecommendation;
	local EaseTable EaseTable;

	i = 0;
	// End:0x26E
	if(__NFUN_150__(i, Advisors.Length))
	{
		NewRecommendation.Recommendation = Advisors[i].GetRecommendedAdjustment();
		// End:0x260
		if(__NFUN_119__(GetDifficultyAdjustment(NewRecommendation.Recommendation.AdjustmentClass), none))
		{
			NewRecommendation.Advisor = Advisors[i];
			NewRecommendations[NewRecommendations.Length] = NewRecommendation;
			log('Difficulty', 3, __NFUN_112__("Adding request for ", string(NewRecommendation.Recommendation.AdjustmentClass.Name)));
			EaseTable = Class'ShockGame.EaseTable'.static.Allocate(self,, string(NewRecommendation.Recommendation.ProbabilityTableName)).;
			Construct_Void();
			GetDifficultyAdjustment(NewRecommendation.Recommendation.AdjustmentClass).AddRequest(Advisors[i], EaseTable.GetValue(Advisors[i].GetEaseValue(), self), NewRecommendation.Recommendation.Count);
			__NFUN_163__(i);
			// [Loop Continue]
			goto J0x0B;
			i = 0;
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x37C
			/*@Error*/
			log('Difficulty', 3, __NFUN_112__("Removing request to ", string(ActiveRecommendations[i].Recommendation.AdjustmentClass.Name)));
			GetDifficultyAdjustment(ActiveRecommendations[i].Recommendation.AdjustmentClass).RemoveRequest(ActiveRecommendations[i].Advisor);
			__NFUN_163__(i);
			// [Explicit Continue]
			goto J0x279;
		}
		ActiveRecommendations = NewRecommendations;
		assert(__NFUN_154__(ActiveRecommendations.Length, NewRecommendations.Length));
	}
	ActiveAdjustments.Length = 0;
	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x465
	/*@Error*/
	AddActiveAdjustment(GetDifficultyAdjustment(NewRecommendations[i].Recommendation.AdjustmentClass), float(NewRecommendations[i].Recommendation.Priority));
	__NFUN_165__(i);
	goto J0x3BF;
	return;
	@NULL
	Item
	ShockPawn
	@NULL
}

function Tick(float DeltaSeconds)
{
	DifficultyStatsManager.Tick(DeltaSeconds);
	return;
	@NULL
	Item
}

// Export UDifficultyManager::execStartNewSession(FFrame&, void* const)
native function StartNewSession();

// Export UDifficultyManager::execOutputSessionData(FFrame&, void* const)
native function OutputSessionData();

function UpdatePlayerState(ShockPlayer Player)
{
	// End:0x41
	if(__NFUN_180__(DifficultyStatsManager.SnapshotRate, float(0)))
	{
		DifficultyStatsManager.Snapshot(Player);
		goto J0x4B;
		OutputSessionData();
		UpdateAdvisors(Player);
	}
	UpdateActiveAdjustments();
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function ModifyContainer(Container Container)
{
	local Controller Controller;
	local ShockPlayer Player;
	local int i;
	local ILootDifficultyAdjustment LootAdjustment;

	// End:0x11
	if(__NFUN_129__(EnableAdaptiveDifficulty))
	{
		return;
		Controller = GameDriver.GetLevel().GetLocalPlayerController();
	}
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x243
	/*@Error*/
	Player = ShockPlayer(Controller.Pawn);
	UpdatePlayerState(Player);
	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x243
	/*@Error*/
	LootAdjustment = ILootDifficultyAdjustment(ActiveAdjustments[i].Adjustment);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x235
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x1C2
	/*@Error*/
	log('Difficulty', 3, __NFUN_112__(string(ActiveAdjustments[i].Adjustment.Class.Name), ".ModifyContainer call"));
	LootAdjustment.ModifyContainer(Container);
	goto J0x235;
	log('Difficulty', 3, __NFUN_112__(string(ActiveAdjustments[i].Adjustment.Class.Name), " not active for ModifyContainer"));
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0xA3;
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

defaultproperties
{
	EnableAdaptiveDifficulty=true
	AdvisorClasses[0]=Class'ShockGame.HealthAdvisor'
	AdvisorClasses[1]=Class'ShockGame.BioAmmoAdvisor'
	AdvisorClasses[2]=Class'ShockGame.AmmoAdvisor'
	AdvisorClasses[3]=Class'ShockGame.FrequentDeathAdvisor'
	AdjustmentClasses[0]=Class'ShockGame.SpawnMedHypoAdjustment'
	AdjustmentClasses[1]=Class'ShockGame.SpawnBioAmmoAdjustment'
	AdjustmentClasses[2]=Class'ShockGame.SpawnAmmoAdjustment'
	AdjustmentClasses[3]=Class'ShockGame.RemoveMedHypoAdjustment'
	AdjustmentClasses[4]=Class'ShockGame.RemoveBioAmmoAdjustment'
	AdjustmentClasses[5]=Class'ShockGame.RemoveAmmoAdjustment'
	NoDifficultySpawnClassNames[0]="MeleeThugClub"
	NoDifficultySpawnClassNames[1]="Gatherer"
	NoDifficultySpawnClassNames[2]="BotMiniGun"
	NoDifficultySpawnClassNames[3]="TurretMiniGun"
	NoDifficultySpawnClassNames[4]="TurretFlamethrower"
	NoDifficultySpawnClassNames[5]="TurretRPG"
	NoDifficultySpawnClassNames[6]="RangedAggressorPistolWeapon"
	NoDifficultySpawnClassNames[7]="RosieRangedWeapon"
	NoDifficultySpawnClassNames[8]="RosieEliteRangedWeapon"
	NoDifficultySpawnClassNames[9]="RangedAggressorMachineGun"
	NoDifficultySpawnClassNames[10]="GrenadeBox"
	NoDifficultySpawnClassNames[11]="GrenadeBoxMolotov"
	NoDifficultySpawnClassNames[12]="SpawnedSecurityCamera"
	NoDifficultySpawnClassNames[13]="SecurityBot"
	NoDifficultySpawnClassNames[14]="Turret"
	NoDifficultyRemoveClassNames[0]="PistolAndStandardBullet"
	NoDifficultyRemoveClassNames[1]="ShotgunAnd00Buck"
	NoDifficultyRemoveClassNames[2]="CrossbowAndStandardBolt"
	NoDifficultyRemoveClassNames[3]="ChemicalThrowerAndNapalm"
	NoDifficultyRemoveClassNames[4]="GrenadeLauncherAndFragGrenades"
	NoDifficultyRemoveClassNames[5]="MachineGunAndStandardBullet"
}