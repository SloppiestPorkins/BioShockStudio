class AwardAchievementsManager extends Object
	native
	config(AwardAchievements);

var private travel int NumMachinesHacked;
var private travel int NumItemsCrafted;
var private travel bool WasSecurityEverTriggered;
var private travel bool DidDamageUsingNonWrenchWeapon;
var travel array<int> AmmoCrafted;
var private travel int NumGatherersHarvested;
var private travel int NumGatherersInteracted;
var private travel int NumTracksMaxed;
var travel ShockPlayer PlayerOwner;
var private travel bool DifficultyChanged;
var private travel bool PlayerRespawned;
var private travel bool JustCraftedAnItem;
var private bool DLC1_DestroyedSpawnedDLCMinimumSecurityTurretInThisDLCLevel;
var private UserSettings.EGameDifficulty DLC1_MinDifficulty;
var private int DLC1_NumRosesCollectedThisLevel;
var private config int NumGatherersInGame;
var private config int MachinesHackedForAward;
var private config int TotalLogsInGame;
var private config int TotalPassivePlasmidsInGame;
var private config int ItemsCraftedForAward;
var config array< Class<Ammunition> > CraftableAmmoTypes;
var private config int DLC1_Combat_NumRoses;
var private config float DLC1_Combat_GoldSeconds;
var private config int DLC1_Electric_NumRoses;
var private config int DLC1_Electric_GoldSeconds;
var private config int DLC1_Decoy_NumRoses;
var private config int DLC1_Decoy_GoldSeconds;

function IncrementProgressAchievement(name FieldName)
{
	PlayerOwner.Level.GetGameDriver().GetAchievementManager().IncrementProgressAchievement(FieldName);
	return;
	@NULL
	Item
	ShockPawn
}

function IncrementTrackerAchievement(name GroupName, name FieldName)
{
	PlayerOwner.Level.GetGameDriver().GetAchievementManager().IncrementTrackerAchievement(GroupName, FieldName);
	return;
	@NULL
	Item
	ShockPawn
	@NULL
}

function SetTrackerAchievement(name GroupName, name FieldName, int Value, bool IsHighValueReward)
{
	PlayerOwner.Level.GetGameDriver().GetAchievementManager().SetTrackerAchievement(GroupName, FieldName, Value, IsHighValueReward);
	return;
	@NULL
	Item
	ShockPawn
	@NULL
}

function UpdateUniqueProgressAchievement(name GroupName, name FieldName, name FieldEntry)
{
	PlayerOwner.Level.GetGameDriver().GetAchievementManager().UpdateUniqueProgressAchievement(GroupName, FieldName, FieldEntry);
	return;
	@NULL
	Item
	ShockPawn
	@NULL
}

function AwardAchievement(name AchievementName)
{
	// End:0x2B
	if(__NFUN_154__(int(GetPlatform()), int(3)))
	{
		EventAwardAchievement(AchievementName);
		goto J0x74;
		PlayerOwner.Level.GetGameDriver().GetAchievementManager().AwardAchievement(AchievementName);
	}
	return;
	@NULL
	Item
	ShockPawn
	@NULL
}

function AwardDLCAchievement(name AchievementName)
{
	// End:0x2B
	if(__NFUN_154__(int(GetPlatform()), int(3)))
	{
		EventAwardAchievement(AchievementName);
		goto J0x74;
		PlayerOwner.Level.GetGameDriver().GetAchievementManager().AwardAchievement(AchievementName);
	}
	return;
	@NULL
	Item
	ShockPawn
	@NULL
}

function EventAwardAchievement(name AchievementName)
{
	//native.AchievementName;	
	@NULL
}

function bool PlayerHasAndFullyUpgradedWeapon(name WeaponName)
{
	local Weapon Weapon;

	Weapon = Weapon(PlayerOwner.GetHoldableByClassName(WeaponName));
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x63
	/*@Error*/
	return true;
	goto J0x65;
	return false;
	return;
	@NULL
	Item
	Item
	@NULL
}

function PlayerTriggeredAlarm()
{
	WasSecurityEverTriggered = true;
	return;
	@NULL
}

function PlayerPlasmidEquipped(Plasmid Plasmid)
{
	//native.Plasmid;	
	@NULL
}

function ResearchedTrack(name ResearchTrack)
{
	// End:0x4B
	if(__NFUN_154__(int(GetPlatform()), int(3)))
	{
		EventResearchedTrack(ResearchTrack, PlayerOwner.GetResearchScoreForTrack(ResearchTrack));
		goto J0x88;
		SetTrackerAchievement('Research', ResearchTrack, PlayerOwner.GetResearchScoreForTrack(ResearchTrack), true);
	}
	return;
	@NULL
	Item
	Item
	@NULL
}

function EventResearchedTrack(name ResearchTrack, int Level)
{
	//native.ResearchTrack;
	//native.Level;	
	@NULL
	@NULL
}

function GradePhoto(ShockPlayer.EPhotoGrade Grade, bool isSplicerPhoto)
{
	// End:0x2D
	if(__NFUN_154__(int(GetPlatform()), int(3)))
	{
		EventGradePhoto(int(Grade));
		goto J0x95;
		// End:0x6A
		if(__NFUN_132__(__NFUN_154__(int(Grade), int(4)), __NFUN_154__(int(Grade), int(5))))
		{
		}
		IncrementProgressAchievement('GradeAPhoto');
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x95
		/*@Error*/
		SetTrackerAchievement('Research', 'ResearchedASplicer', 1, true);
	}
	return;
	@NULL
	Item
	Item
	@NULL
}

function EventGradePhoto(int Grade)
{
	//native.Grade;	
	@NULL
}

function FinishedHacking(ICanBeHacked HackedObject, string HackResult)
{
	//native.HackedObject;
	//native.HackResult;	
	@NULL
	@NULL
}

function EventFinishedHacking(string HackedName)
{
	//native.HackedName;	
	@NULL
}

function WeaponUpgraded(name WeaponName)
{
	// End:0x22
	if(__NFUN_154__(int(GetPlatform()), int(3)))
	{
		EventWeaponUpgraded();
		goto J0x35;
		IncrementProgressAchievement('UpgradedAWeapon');
	}
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x92
	/*@Error*/
	// End:0x76
	if(__NFUN_154__(int(GetPlatform()), int(3)))
	{
		EventWeaponFullyUpgraded(WeaponName);
		goto J0x92;
		IncrementTrackerAchievement('FullyUpgradedWeapons', WeaponName);
	}
	return;
	@NULL
	Item
	Item
	@NULL
}

// Export UAwardAchievementsManager::execEventWeaponUpgraded(FFrame&, void* const)
private native function EventWeaponUpgraded();

function EventWeaponFullyUpgraded(name WeaponName)
{
	//native.WeaponName;	
	@NULL
}

function CraftedItem(Class<Item> ItemClass)
{
	local int i;

	// End:0x44
	if(__NFUN_154__(int(GetPlatform()), int(3)))
	{
		EventCraftedItem(ItemClass.Name);
		JustCraftedAnItem = true;
		goto J0xDB;
		IncrementProgressAchievement('CraftedAnItem');
	}
	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xDB
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xCD
	/*@Error*/
	UpdateUniqueProgressAchievement('CraftedAmmo', 'UniqueAmmo', ItemClass.Name);
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x62;
	return;
	@NULL
	Item
	Item
	@NULL
}

function EventCraftedItem(name ItemName)
{
	//native.ItemName;	
	@NULL
}

function PurchasedItem(Class<Item> ItemClass)
{
	return;
}

function PlasmidTrackSlotLocked(Plasmid.ePlasmidTrack Track, int NumSlots)
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x1B
	/*@Error*/
	__NFUN_164__(NumTracksMaxed);
	return;
	@NULL
	Item
}

function PlasmidTrackSlotUnlocked(Plasmid.ePlasmidTrack Track, int NumSlots)
{
	// End:0x4C
	if(__NFUN_154__(int(GetPlatform()), int(3)))
	{
		EventPlasmidTrack(Track, __NFUN_147__(NumSlots, PlayerOwner.BasePlasmidSlots));
		goto J0x9F;
		SetTrackerAchievement('PlasmidTracks', GetEnum(Enum'ShockGame.Plasmid.ePlasmidTrack', int(Track)), __NFUN_147__(NumSlots, PlayerOwner.BasePlasmidSlots), true);
	}
	return;
	@NULL
	Item
	Item
	@NULL
}

function EventPlasmidTrack(Plasmid.ePlasmidTrack Track, int Slots)
{
	//native.Track;
	//native.Slots;	
	@NULL
	@NULL
}

function OpenedSecurityCrate()
{
	return;
}

function GameFinished(bool GoodEnding)
{
	local int Difficulty;

	// End:0x7F
	if(__NFUN_154__(int(GetPlatform()), int(3)))
	{
		// End:0x34
		if(DifficultyChanged)
		{
			Difficulty = -1;
			goto J0x56;
			Difficulty = int(PlayerOwner.CurrentDifficultySetting);
		}
		EventGameCompleted(Difficulty, PlayerRespawned, NumGatherersHarvested);
		goto J0x235;
		// End:0xA1
		if(__NFUN_154__(NumGatherersHarvested, 0))
		{
			IncrementProgressAchievement('NoGatherersHarvested');
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x235
			/*@Error*/
		}
		// End:0x15B
		if(__NFUN_154__(int(PlayerOwner.CurrentDifficultySetting), int(2)))
		{
			log(,, "finished game on Hard!");
		}
		IncrementProgressAchievement('CompletedGameOnHardestDifficulty');
		// End:0x158
		if(__NFUN_129__(PlayerRespawned))
		{
			log(,, "finished game without using vita chambers!");
			IncrementProgressAchievement('Moxie');
			goto J0x235;
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x235
			/*@Error*/
			log(,, "finished game on Extreme/Survivor!");
		}
	}
	IncrementProgressAchievement('CompletedGameOnHardestDifficulty');
	IncrementProgressAchievement('Survivor');
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x235
	/*@Error*/
	log(,, "finished game without using vita chambers!");
	IncrementProgressAchievement('Moxie');
	IncrementProgressAchievement('CheatTheReaper');
	return;
	@NULL
	Item
	Item
	@NULL
}

function EventGameCompleted(int Difficulty, bool Revived, int GatherersHarvested)
{
	//native.Difficulty;
	//native.Revived;
	//native.GatherersHarvested;	
	@NULL
	@NULL
	return return @NULL;
}

function PlayerPickedUpInventory(Class<Item> ItemClass, int Amount)
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0xAE
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xA2
	/*@Error*/
	EventItemAcquireed(PlayerOwner.Level.Outer.Name, int(PlayerOwner.CurrentDifficultySetting), ItemClass.Name, PlayerOwner.Location);
	JustCraftedAnItem = false;
	return;
	@NULL
	Item
	Item
	@NULL
}

function EventItemAcquireed(name LevelName, int Difficulty, name ItemName, Vector Position)
{
	//native.LevelName;
	//native.Difficulty;
	//native.ItemName;
	//native.Position;	
	@NULL
	@NULL
	return return @NULL;
}

function PlayerCollectedPlasmid(name PlasmidName)
{
	// End:0x2B
	if(__NFUN_154__(int(GetPlatform()), int(3)))
	{
		EventPlasmidUnlocked(PlasmidName);
		goto J0x47;
		IncrementTrackerAchievement('Plasmids', PlasmidName);
	}
	return;
	@NULL
	Item
	J0x47:

	stop;
	default.@NULL
}

function EventPlasmidUnlocked(name PlasmidName)
{
	//native.PlasmidName;	
	@NULL
}

function PlayerPickedUpLog(name LevelName, name LogName)
{
	// End:0x2B
	if(__NFUN_154__(int(GetPlatform()), int(3)))
	{
		EventLog(LogName);
		goto J0x50;
		UpdateUniqueProgressAchievement('Logs', LevelName, LogName);
	}
	return;
	@NULL
	Item
	Item
	@NULL
}

function EventLog(name LogName)
{
	//native.LogName;	
	@NULL
}

function PlayerHitTarget(Actor Target, IProvideDamageData DamageData)
{
	local Weapon Weapon;


	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x8E
	/*@Error*/
	Weapon = PlayerOwner.GetWeaponFromDamageData(DamageData);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x8E
	/*@Error*/
	DidDamageUsingNonWrenchWeapon = true;
	return;
	@NULL
	Item
	Item
	@NULL
}

function PossiblyChangedMinDifficulty()
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0xA3
	/*@Error*/
	switch(PlayerOwner.CurrentDifficultySetting)
	{
		// End:0x53
		case 0:
			DLC1_MinDifficulty = 0;
			// End:0xA3
			break;
			// End:0x7B
			case 1:
				// End:0x78
				if(__NFUN_155__(int(DLC1_MinDifficulty), int(0)))
				{
					DLC1_MinDifficulty = 1;/* !MISMATCHING REMOVE, tried Case got Type:If Position:0x040! */
				// End:0xA3
				break;
				// End:0xA0
				case 2:
					/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
						
					*/

					// End:0xA0
					/*@Error*/
					DLC1_MinDifficulty = 2;
				}/* !MISMATCHING REMOVE, tried If got Type:Case Position:0x05B! */
				// End:0xFFFF
				default:
					break;/* Tried to find Switch scope, found Case instead */
			return;
			@NULL
			Item
			Item
			@NULL
	}
}

function StartingDifficultySet()
{
	DLC1_MinDifficulty = PlayerOwner.CurrentDifficultySetting;
	return;
	@NULL
	Item
	Item
}

function ChangedDifficulty()
{
	PossiblyChangedMinDifficulty();
	DifficultyChanged = true;
	return;
	@NULL
}

function bool PlayerNeverUsedEasyMode()
{
	return __NFUN_155__(int(DLC1_MinDifficulty), int(0));
	return;
	@NULL
}

function PlayerUsedVita()
{
	PlayerRespawned = true;
	return;
	@NULL
}

function KilledByPlayer(Actor Killed)
{
	return;
}

function int GetNumberOfGatherersHarvested()
{
	return NumGatherersHarvested;
	return;
	@NULL
}

function SavedGatherer()
{
	return;
}

function InteractedWithGatherer(name LevelName, int NumGatherers)
{
	// End:0x34
	if(__NFUN_154__(int(GetPlatform()), int(3)))
	{
		EventGatherers(LevelName, NumGatherers);
		goto J0x5A;
		SetTrackerAchievement('Gatherers', LevelName, NumGatherers, true);
	}
	return;
	@NULL
	Item
	Item
	@NULL
}

function EventGatherers(name LevelName, int NumGatherers)
{
	//native.LevelName;
	//native.NumGatherers;	
	@NULL
	@NULL
}

function CollectedGatherer()
{
	local float ChallengeTime;
	local int ChallengeMilliseconds;
	local ShockUserSettings ShockUserSettings;

	ShockUserSettings = ShockUserSettings(PlayerOwner.Level.GetGameDriver().GetUserSettings());
	ChallengeTime = PlayerOwner.GetChallengeTimeInSeconds();
	ChallengeMilliseconds = int(__NFUN_171__(ChallengeTime, float(1000)));
	// End:0xFC
	if(__NFUN_154__(int(GetPlatform()), int(3)))
	{
		EventChallengeGameCompleted(PlayerOwner.Level.Outer.Name, int(DLC1_MinDifficulty), ChallengeTime, DLC1_NumRosesCollectedThisLevel, __NFUN_129__(DidDamageUsingNonWrenchWeapon));
		// End:0x15E
		if(__NFUN_155__(int(GetPlatform()), int(3)))
		{
			SetTrackerAchievement('Challenge', PlayerOwner.Level.Outer.Name, ChallengeMilliseconds, false);
		}
		// End:0x415
		if(__NFUN_124__(string(PlayerOwner.Level.Outer.Name), "ChallengeRoomCombat"))
		{
			// End:0x1F0
			if(__NFUN_130__(__NFUN_155__(int(GetPlatform()), int(3)), PlayerNeverUsedEasyMode()))
			{
			}
			// End:0x1F0
			if(__NFUN_129__(DidDamageUsingNonWrenchWeapon))
			{
				IncrementProgressAchievement('CombatNoWeapons');
				switch(DLC1_MinDifficulty)
				{
					// End:0x280
					case 0:
						// End:0x27D
						if(__NFUN_132__(__NFUN_176__(ChallengeTime, ShockUserSettings.DLC1_Combat_Easy_BestTimeInSeconds), __NFUN_180__(ShockUserSettings.DLC1_Combat_Easy_BestTimeInSeconds, 0.0000000)))
						{
							ShockUserSettings.DLC1_Combat_Easy_BestTimeInSeconds = ChallengeTime;
							ShockUserSettings.SaveSettings();
							// End:0x412
							break;
							// End:0x305
							case 1:
								// End:0x302
								if(__NFUN_132__(__NFUN_176__(ChallengeTime, ShockUserSettings.DLC1_Combat_Medium_BestTimeInSeconds), __NFUN_180__(ShockUserSettings.DLC1_Combat_Medium_BestTimeInSeconds, 0.0000000)))
								{
								}
							}/* !MISMATCHING REMOVE, tried If got Type:Case Position:0x1E4! */
							ShockUserSettings.DLC1_Combat_Medium_BestTimeInSeconds = ChallengeTime;
							ShockUserSettings.SaveSettings();
							// End:0x412
							break;
							// End:0x38A
							case 2:
								// End:0x387
								if(__NFUN_132__(__NFUN_176__(ChallengeTime, ShockUserSettings.DLC1_Combat_Hard_BestTimeInSeconds), __NFUN_180__(ShockUserSettings.DLC1_Combat_Hard_BestTimeInSeconds, 0.0000000)))
								{
									ShockUserSettings.DLC1_Combat_Hard_BestTimeInSeconds = ChallengeTime;
								}
							ShockUserSettings.SaveSettings();
							// End:0x412
							break;
							// End:0x40F
							case 3:
								// End:0x40C
								if(__NFUN_132__(__NFUN_176__(ChallengeTime, ShockUserSettings.DLC1_Combat_Survivor_BestTimeInSeconds), __NFUN_180__(ShockUserSettings.DLC1_Combat_Survivor_BestTimeInSeconds, 0.0000000)))
								{
									ShockUserSettings.DLC1_Combat_Survivor_BestTimeInSeconds = ChallengeTime;
									ShockUserSettings.SaveSettings();
								}
								// End:0x412
								break;
							// End:0xFFFF
							default:
								// End:0x5F8
								break;
								break;
						}/* !MISMATCHING REMOVE, tried Switch got Type:If Position:0x188! */
						/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
							
						*/

						// End:0x52D
						/*@Error*/
						// End:0x4AD
						if(__NFUN_129__(DLC1_DestroyedSpawnedDLCMinimumSecurityTurretInThisDLCLevel))
						{
							// End:0x49A
							if(__NFUN_155__(int(GetPlatform()), int(3)))
							{
								IncrementProgressAchievement('DecoyTurretsAlive');
								goto J0x4AD;
								EventAwardAchievement('DecoyTurretsAlive');
							}/* !MISMATCHING REMOVE, tried Case got Type:If Position:0x348! */
						/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
							
						*/

						// End:0x52A
						/*@Error*/
						ShockUserSettings.DLC1_Decoy_BestTimeInSeconds = ChallengeTime;
						ShockUserSettings.SaveSettings();
						goto J0x5F8;
						assert(__NFUN_124__(string(PlayerOwner.Level.Outer.Name), "ChallengeRoomElectric"));
					}/* !MISMATCHING REMOVE, tried If got Type:Case Position:0x183! *//* !MISMATCHING REMOVE, tried Case got Type:Switch Position:0x17C! */
			}/* !MISMATCHING REMOVE, tried Switch got Type:If Position:0x15E! */
		}
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x5F8
		/*@Error*/
		ShockUserSettings.DLC1_Electric_BestTimeInSeconds = ChallengeTime;
		ShockUserSettings.SaveSettings();
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x65A
		/*@Error*/
		SetTrackerAchievement('Roses', PlayerOwner.Level.Outer.Name, DLC1_NumRosesCollectedThisLevel, true);
	// Failed to format nests!:System.ArgumentOutOfRangeException: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
   at System.Collections.Generic.List`1.get_Item(Int32 index)
   at UELib.Core.UStruct.UByteCodeDecompiler.DecompileNests(Boolean outputAllRemainingNests) in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 849
   at UELib.Core.UStruct.UByteCodeDecompiler.Decompile() in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 702
	// 1 & Type:If Position:0x4AD
	return;
	// Failed to format nests!:System.ArgumentOutOfRangeException: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
   at System.Collections.Generic.List`1.get_Item(Int32 index)
   at UELib.Core.UStruct.UByteCodeDecompiler.DecompileNests(Boolean outputAllRemainingNests) in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 849
   at UELib.Core.UStruct.UByteCodeDecompiler.Decompile() in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 702
	// 1 & Type:If Position:0x4AD
	@NULL
	// Failed to format nests!:System.ArgumentOutOfRangeException: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
   at System.Collections.Generic.List`1.get_Item(Int32 index)
   at UELib.Core.UStruct.UByteCodeDecompiler.DecompileNests(Boolean outputAllRemainingNests) in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 849
   at UELib.Core.UStruct.UByteCodeDecompiler.Decompile() in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 702
	// 1 & Type:If Position:0x4AD
	Item
	// Failed to format nests!:System.ArgumentOutOfRangeException: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
   at System.Collections.Generic.List`1.get_Item(Int32 index)
   at UELib.Core.UStruct.UByteCodeDecompiler.DecompileNests(Boolean outputAllRemainingNests) in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 849
   at UELib.Core.UStruct.UByteCodeDecompiler.Decompile() in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 702
	// 1 & Type:If Position:0x4AD
	Item
	// Failed to format nests!:System.ArgumentOutOfRangeException: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
   at System.Collections.Generic.List`1.get_Item(Int32 index)
   at UELib.Core.UStruct.UByteCodeDecompiler.DecompileNests(Boolean outputAllRemainingNests) in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 849
   at UELib.Core.UStruct.UByteCodeDecompiler.Decompile() in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 702
	// 1 & Type:If Position:0x4AD
	@NULL
	// Failed to format nests!:System.ArgumentOutOfRangeException: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
   at System.Collections.Generic.List`1.get_Item(Int32 index)
   at UELib.Core.UStruct.UByteCodeDecompiler.DecompileNests(Boolean outputAllRemainingNests) in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 849
   at UELib.Core.UStruct.UByteCodeDecompiler.Decompile() in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 702
	// 1 & Type:If Position:0x4AD
	// Failed to format remaining nests!:System.ArgumentOutOfRangeException: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
   at System.Collections.Generic.List`1.get_Item(Int32 index)
   at UELib.Core.UStruct.UByteCodeDecompiler.DecompileNests(Boolean outputAllRemainingNests) in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 849
   at UELib.Core.UStruct.UByteCodeDecompiler.Decompile() in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 724
	// 1 & Type:If Position:0x4AD
}

function EventChallengeGameCompleted(name LevelName, int Difficulty, float Time, int Roses, bool WrenchOnly)
{
	//native.LevelName;
	//native.Difficulty;
	//native.Time;
	//native.Roses;
	//native.WrenchOnly;	
	@NULL
	@NULL
	return return @NULL;
}

// Export UAwardAchievementsManager::execGetBestTimeInCurrentDLCLevel(FFrame&, void* const)
native function float GetBestTimeInCurrentDLCLevel();

// Export UAwardAchievementsManager::execGetGoldTimeInCurrentDLCLevel(FFrame&, void* const)
native function bool GetGoldTimeInCurrentDLCLevel();

// Export UAwardAchievementsManager::execGetNumCollectedRosesInCurrentDLCLevel(FFrame&, void* const)
native function int GetNumCollectedRosesInCurrentDLCLevel();

// Export UAwardAchievementsManager::execGetTotalRosesInCurerntDLCLevel(FFrame&, void* const)
native function int GetTotalRosesInCurerntDLCLevel();

function CollectedRose()
{
	__NFUN_163__(DLC1_NumRosesCollectedThisLevel);
	return;
	@NULL
}

function SpawnedDLCMinimumSecurityTurretWasDestroyedInDLC1Level()
{
	DLC1_DestroyedSpawnedDLCMinimumSecurityTurretInThisDLCLevel = true;
	return;
	@NULL
}

function PacifiedGatherer()
{
	__NFUN_163__(NumGatherersInteracted);
	__NFUN_163__(NumGatherersHarvested);
	return;
	@NULL
	Item
}

function ShockedAIinWater()
{
	// End:0x22
	if(__NFUN_154__(int(GetPlatform()), int(3)))
	{
		EventShockAIinWater();
		goto J0x35;
		IncrementProgressAchievement('ShockAIinWater');
	}
	return;
	@NULL
}

// Export UAwardAchievementsManager::execEventShockAIinWater(FFrame&, void* const)
private native function EventShockAIinWater();

defaultproperties
{
	DLC1_MinDifficulty=3
	NumGatherersInGame=21
	MachinesHackedForAward=50
	TotalLogsInGame=122
	TotalPassivePlasmidsInGame=53
	ItemsCraftedForAward=100
	CraftableAmmoTypes[0]=Class'ShockGame.Pistol_AntiPersonnel'
	CraftableAmmoTypes[1]=Class'ShockGame.Shotgun_HighExplosiveBuck'
	CraftableAmmoTypes[2]=Class'ShockGame.Crossbow_TrapBolt'
	CraftableAmmoTypes[3]=Class'ShockGame.GrenadeLauncher_RPG'
	CraftableAmmoTypes[4]=Class'ShockGame.ChemicalThrower_IonicGel'
	CraftableAmmoTypes[5]=Class'ShockGame.MachineGun_ArmorPiercingBullet'
	DLC1_Combat_NumRoses=8
	DLC1_Combat_GoldSeconds=900.0000000
	DLC1_Electric_NumRoses=10
	DLC1_Electric_GoldSeconds=240
	DLC1_Decoy_NumRoses=4
	DLC1_Decoy_GoldSeconds=180
}