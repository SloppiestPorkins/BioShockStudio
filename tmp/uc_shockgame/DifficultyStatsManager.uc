class DifficultyStatsManager extends Object
	native
	config(Difficulty);

enum DifficultyStatType
{
	STAT_AVERAGE,                   // 0
	STAT_DURATION                   // 1
};

struct native atomic DifficultySample
{
	var travel float Time;
	var travel float Value;
	var travel float CreditBonus;

	structdefaultproperties
	{
		CheckpointTypePadding=7602293
	}
};

struct native atomic PersistentDifficultyStat
{
	var travel array<DifficultySample> Samples;
	var travel int NextSampleIndex;
	var travel float Value;
	var travel float BaseValue;

	structdefaultproperties
	{
		CheckpointTypePadding=7209061
	}
};

struct native atomic DifficultyStat
{
	var array<DifficultySample> Samples;
	var int NextSampleIndex;
	var DifficultyStatsManager.DifficultyStatType StatType;
	var DifficultyInt MaxSamples;
	var float BonusPerCredit;
	var string FriendlyName;
	var float Value;
	var float BaseValue;

	structdefaultproperties
	{
		CheckpointTypePadding=452
	}
};

var private transient DifficultyManager DifficultyManager;
var const config float SnapshotRate;
var private transient float NextSnapshotTime;
var config DifficultyStat DeathReloadStats;
var config DifficultyStat HealthStats;
var config DifficultyStat TotalHealthStats;
var config DifficultyStat MedHypoStats;
var const config Class<Item> MedHypoClass;
var config DifficultyStat BioAmmoStats;
var config DifficultyStat TotalBioAmmoStats;
var config DifficultyStat BioAmmoHypoStats;
var const config Class<Item> BioAmmoHypoClass;
var config DifficultyStat CreditsStats;
var config DifficultyStat PistolAmmoStats;
var config DifficultyStat ShotgunAmmoStats;
var config DifficultyStat CrossbowAmmoStats;
var config DifficultyStat ChemicalThrowerAmmoStats;
var config DifficultyStat MachineGunAmmoStats;
var config DifficultyStat GrenadeLauncherAmmoStats;

function Construct(DifficultyManager DifficultyManager)
{
	self.DifficultyManager = DifficultyManager;
	return;
	@NULL
	Item
}

function LogStat(DifficultyStat Stat)
{
	local int LastSampleIndex;
	local string EmptyValue;

	EmptyValue = "N/A";
	// End:0x150
	if(__NFUN_154__(Stat.Samples.Length, 0))
	{
		switch(Stat.StatType)
		{
			// End:0xCB
			case 0:
				log('DifficultyStats', 3, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(Stat.FriendlyName, " Sample Time: "), EmptyValue), " Value: "), EmptyValue), " Average: "), EmptyValue));
				// End:0x14E
				break;
				// End:0x14B
				case 1:
					log('DifficultyStats', 3, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(Stat.FriendlyName, " Sample Time: "), EmptyValue), " Value: "), EmptyValue), " Duration: "), EmptyValue));
				// End:0x14E
				break;
				// End:0xFFFF
				default:
					return;
					break;
			}/* !MISMATCHING REMOVE, tried Switch got Type:Case Position:0x030! */
			// End:0x19B
			if(__NFUN_154__(Stat.NextSampleIndex, 0))
			{
				LastSampleIndex = __NFUN_147__(Stat.Samples.Length, 1);
				goto J0x1C2;
				LastSampleIndex = __NFUN_147__(Stat.NextSampleIndex, 1);
				switch(Stat.StatType)
				{/* !MISMATCHING REMOVE, tried Case got Type:Switch Position:0x14A! */
			}/* !MISMATCHING REMOVE, tried Switch got Type:If Position:0x104! */
		}/* !MISMATCHING REMOVE, tried If got Type:Switch Position:0x020! */
		// End:0x2CC
		case 0:
			log('DifficultyStats', 3, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(Stat.FriendlyName, " Sample Time: "), string(Stat.Samples[LastSampleIndex].Time)), " Value: "), string(Stat.Samples[LastSampleIndex].Value)), " Average: "), string(Stat.Value)));
		}/* !MISMATCHING REMOVE, tried If got Type:Case Position:0x15A! */
		// End:0x3BE
		break;
		// End:0x3BB
		case 1:
			log('DifficultyStats', 3, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(Stat.FriendlyName, " Sample Time: "), string(Stat.Samples[LastSampleIndex].Time)), " Value: "), string(Stat.Samples[LastSampleIndex].Value)), " Duration: "), string(Stat.Value)));
			// End:0x3BE
			break;
			// End:0xFFFF
			default:
				return;
				break;
		}/* !MISMATCHING REMOVE, tried Switch got Type:Case Position:0x200! */
		@NULL
		Item
		ShockPawn
		@NULL
	// Failed to format remaining nests!:System.ArgumentOutOfRangeException: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
   at System.Collections.Generic.List`1.get_Item(Int32 index)
   at UELib.Core.UStruct.UByteCodeDecompiler.DecompileNests(Boolean outputAllRemainingNests) in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 849
   at UELib.Core.UStruct.UByteCodeDecompiler.Decompile() in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 724
	// 2 & Type:Switch Position:0x3BE
}

function AddSample(out DifficultyStat Stat, float Value)
{
	local float sum, BonusSum;
	local int i;
	local DifficultySample NewSample;

	// End:0x39
	if(__NFUN_154__(DifficultyManager.GetDifficultyInt(Stat.MaxSamples), 0))
	{
		return;
		NewSample.Value = Value;
	}
	NewSample.CreditBonus = __NFUN_171__(GetLastSampleValue(CreditsStats), Stat.BonusPerCredit);
	NewSample.Time = DifficultyManager.GetGameDriver().GetPlayerStatsManager().GetGameplayTime();
	Stat.Samples[Stat.NextSampleIndex] = NewSample;
	switch(Stat.StatType)
	{
		// End:0x2AB
		case 0:
			i = 0;
			// End:0x217
			if(__NFUN_150__(i, Stat.Samples.Length))
			{
				__NFUN_184__(sum, Stat.Samples[i].Value);
				__NFUN_184__(BonusSum, Stat.Samples[i].CreditBonus);
				__NFUN_163__(i);
				goto J0x160;
				Stat.Value = __NFUN_172__(__NFUN_174__(sum, BonusSum), float(Stat.Samples.Length));
				Stat.BaseValue = __NFUN_172__(sum, float(Stat.Samples.Length));
				// End:0x385
				break;
				// End:0x382
				case 1:
					Stat.Value = __NFUN_175__(Stat.Samples[Stat.NextSampleIndex].Time, Stat.Samples[int(__NFUN_173__(float(__NFUN_146__(Stat.NextSampleIndex, 1)), float(Stat.Samples.Length)))].Time);
				}/* !MISMATCHING REMOVE, tried If got Type:Case Position:0x1AB! */
				// End:0x385
				break;
				// End:0xFFFF
				default:
					Stat.NextSampleIndex = int(__NFUN_173__(float(__NFUN_146__(Stat.NextSampleIndex, 1)), float(DifficultyManager.GetDifficultyInt(Stat.MaxSamples))));
					LogStat(Stat);
					return;
					break;
			}/* !MISMATCHING REMOVE, tried Switch got Type:If Position:0x0E8! */
			@NULL
			Item
			ShockPawn
			@NULL
	// Failed to format remaining nests!:System.ArgumentOutOfRangeException: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
   at System.Collections.Generic.List`1.get_Item(Int32 index)
   at UELib.Core.UStruct.UByteCodeDecompiler.DecompileNests(Boolean outputAllRemainingNests) in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 849
   at UELib.Core.UStruct.UByteCodeDecompiler.Decompile() in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 724
	// 1 & Type:Case Position:0x2AB
}

function float GetLastSampleTime(DifficultyStat Stat)
{
	local int LastSampleIndex;

	// End:0x27
	if(__NFUN_154__(Stat.Samples.Length, 0))
	{
		return -1.0000000;
		// End:0x72
		if(__NFUN_154__(Stat.NextSampleIndex, 0))
		{
		}
		LastSampleIndex = __NFUN_147__(Stat.Samples.Length, 1);
		goto J0x99;
		LastSampleIndex = __NFUN_147__(Stat.NextSampleIndex, 1);
		return Stat.Samples[LastSampleIndex].Time;
	}
	return;
	@NULL
	Item
	Class'ShockGame.Item'
	@NULL
}

function float GetLastSampleValue(DifficultyStat Stat)
{
	local int LastSampleIndex;

	// End:0x27
	if(__NFUN_154__(Stat.Samples.Length, 0))
	{
		return 0.0000000;
		// End:0x72
		if(__NFUN_154__(Stat.NextSampleIndex, 0))
		{
		}
		LastSampleIndex = __NFUN_147__(Stat.Samples.Length, 1);
		goto J0x99;
		LastSampleIndex = __NFUN_147__(Stat.NextSampleIndex, 1);
		return Stat.Samples[LastSampleIndex].Value;
	}
	return;
	@NULL
	Item
	Class'ShockGame.Item'
	@NULL
}

function Snapshot(ShockPlayer Player)
{
	log('DifficultyStats', 3, "########## Snapshot #########");
	AddSample(CreditsStats, float(Player.GetCredits()));
	AddSample(HealthStats, __NFUN_172__(Player.GetHealth(), Player.GetMaxHealth()));
	AddSample(TotalHealthStats, __NFUN_174__(__NFUN_172__(Player.GetHealth(), Player.GetMaxHealth()), float(Player.GetNumberOfItems(MedHypoClass))));
	AddSample(MedHypoStats, float(Player.GetNumberOfItems(MedHypoClass)));
	AddSample(BioAmmoStats, __NFUN_172__(Player.GetBioAmmo(), Player.GetMaxBioAmmo()));
	AddSample(TotalBioAmmoStats, __NFUN_174__(__NFUN_172__(Player.GetBioAmmo(), Player.GetMaxBioAmmo()), float(Player.GetNumberOfItems(BioAmmoHypoClass))));
	AddSample(BioAmmoHypoStats, float(Player.GetNumberOfItems(BioAmmoHypoClass)));
	AddSample(PistolAmmoStats, float(Player.GetAmmoCount('Pistol')));
	AddSample(ShotgunAmmoStats, float(Player.GetAmmoCount('Shotgun')));
	AddSample(CrossbowAmmoStats, float(Player.GetAmmoCount('Crossbow')));
	AddSample(ChemicalThrowerAmmoStats, float(Player.GetAmmoCount('ChemicalThrower')));
	AddSample(MachineGunAmmoStats, float(Player.GetAmmoCount('MachineGun')));
	AddSample(GrenadeLauncherAmmoStats, float(Player.GetAmmoCount('GrenadeLauncher')));
	LogStat(DeathReloadStats);
	DifficultyManager.OutputSessionData();
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function Tick(float DeltaSeconds)
{
	local Controller Controller;
	local ShockPlayer Player;


	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0xFB
	/*@Error*/
	Controller = DifficultyManager.GetGameDriver().GetLevel().GetLocalPlayerController();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xFB
	/*@Error*/
	Player = ShockPlayer(Controller.Pawn);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xFB
	/*@Error*/
	Snapshot(Player);
	__NFUN_184__(NextSnapshotTime, SnapshotRate);
	return;
	@NULL
	Item
	Item
	@NULL
}

function GatherPersistentStat(DifficultyStat Stat, out array<PersistentDifficultyStat> PersistentDifficultyStats)
{
	local int Index;

	Index = PersistentDifficultyStats.Length;
	PersistentDifficultyStats.Insert(Index, 1);
	PersistentDifficultyStats[Index].NextSampleIndex = Stat.NextSampleIndex;
	PersistentDifficultyStats[Index].Samples = Stat.Samples;
	PersistentDifficultyStats[Index].Value = Stat.Value;
	PersistentDifficultyStats[Index].BaseValue = Stat.BaseValue;
	return;
	@NULL
	Item
	ShockPawn
	@NULL
}

function RestorePersistentStat(int Index, out array<PersistentDifficultyStat> PersistentDifficultyStats, out DifficultyStat Stat)
{
	Stat.NextSampleIndex = PersistentDifficultyStats[Index].NextSampleIndex;
	Stat.Samples = PersistentDifficultyStats[Index].Samples;
	Stat.Value = PersistentDifficultyStats[Index].Value;
	Stat.BaseValue = PersistentDifficultyStats[Index].BaseValue;
	return;
	@NULL
	Item
	ShockPawn
	@NULL
}

function GatherPersistentStats(out array<PersistentDifficultyStat> PersistentDifficultyStats)
{
	PersistentDifficultyStats.Length = 0;
	GatherPersistentStat(DeathReloadStats, PersistentDifficultyStats);
	GatherPersistentStat(HealthStats, PersistentDifficultyStats);
	GatherPersistentStat(TotalHealthStats, PersistentDifficultyStats);
	GatherPersistentStat(MedHypoStats, PersistentDifficultyStats);
	GatherPersistentStat(BioAmmoStats, PersistentDifficultyStats);
	GatherPersistentStat(TotalBioAmmoStats, PersistentDifficultyStats);
	GatherPersistentStat(BioAmmoHypoStats, PersistentDifficultyStats);
	GatherPersistentStat(CreditsStats, PersistentDifficultyStats);
	GatherPersistentStat(PistolAmmoStats, PersistentDifficultyStats);
	GatherPersistentStat(ShotgunAmmoStats, PersistentDifficultyStats);
	GatherPersistentStat(CrossbowAmmoStats, PersistentDifficultyStats);
	GatherPersistentStat(ChemicalThrowerAmmoStats, PersistentDifficultyStats);
	GatherPersistentStat(MachineGunAmmoStats, PersistentDifficultyStats);
	GatherPersistentStat(GrenadeLauncherAmmoStats, PersistentDifficultyStats);
	return;
	@NULL
	Item
	Item
	@NULL
}

function RestorePersistentStats(out array<PersistentDifficultyStat> PersistentDifficultyStats)
{
	RestorePersistentStat(0, PersistentDifficultyStats, DeathReloadStats);
	RestorePersistentStat(1, PersistentDifficultyStats, HealthStats);
	RestorePersistentStat(2, PersistentDifficultyStats, TotalHealthStats);
	RestorePersistentStat(3, PersistentDifficultyStats, MedHypoStats);
	RestorePersistentStat(4, PersistentDifficultyStats, BioAmmoStats);
	RestorePersistentStat(5, PersistentDifficultyStats, TotalBioAmmoStats);
	RestorePersistentStat(6, PersistentDifficultyStats, BioAmmoHypoStats);
	RestorePersistentStat(7, PersistentDifficultyStats, CreditsStats);
	RestorePersistentStat(8, PersistentDifficultyStats, PistolAmmoStats);
	RestorePersistentStat(9, PersistentDifficultyStats, ShotgunAmmoStats);
	RestorePersistentStat(10, PersistentDifficultyStats, CrossbowAmmoStats);
	RestorePersistentStat(11, PersistentDifficultyStats, ChemicalThrowerAmmoStats);
	RestorePersistentStat(12, PersistentDifficultyStats, MachineGunAmmoStats);
	RestorePersistentStat(13, PersistentDifficultyStats, GrenadeLauncherAmmoStats);
	return;
	@NULL
	Item
	Item
	@NULL
}

function GotItemFromMachine(Class<Item> ItemClass, ShockPlayer Player)
{
	local Weapon Weapon;
	local Class<Ammunition> AmmoClass;

	AmmoClass = Class<Ammunition>(ItemClass);
	// End:0x227
	if(__NFUN_119__(AmmoClass, none))
	{
		Weapon = Player.GetWeaponFromAmmoClass(AmmoClass);
		// End:0x224
		if(__NFUN_119__(Weapon, none))
		{
			switch(Weapon.Class.Name)
			{
				// End:0xCD
				case 'Pistol':
					AddSample(PistolAmmoStats, float(Player.GetAmmoCount('Pistol')));
					// End:0x224
					break;
					// End:0x111
					case 'Shotgun':
						AddSample(ShotgunAmmoStats, float(Player.GetAmmoCount('Shotgun')));
					// End:0x224
					break;
					// End:0x155
					case 'Crossbow':
						AddSample(CrossbowAmmoStats, float(Player.GetAmmoCount('Crossbow')));
						// End:0x224
						break;
					// End:0x199
					case 'ChemicalThrower':
						AddSample(ChemicalThrowerAmmoStats, float(Player.GetAmmoCount('ChemicalThrower')));
						// End:0x224
						break;
						// End:0x1DD
						case 'MachineGun':
						AddSample(MachineGunAmmoStats, float(Player.GetAmmoCount('MachineGun')));
						// End:0x224
						break;
						// End:0x221
						case 'GrenadeLanucher':
							AddSample(GrenadeLauncherAmmoStats, float(Player.GetAmmoCount('GrenadeLauncher')));
						// End:0x224
						break;
						// End:0xFFFF
						default:
							// End:0x418
							break;
							break;
					}/* !MISMATCHING REMOVE, tried Switch got Type:Case Position:0x111! */
					// End:0x321
					if(__NFUN_258__(ItemClass, MedHypoClass))
					{
						AddSample(HealthStats, __NFUN_172__(Player.GetHealth(), Player.GetMaxHealth()));/* !MISMATCHING REMOVE, tried Case got Type:If Position:0x1CB! */
					AddSample(TotalHealthStats, __NFUN_174__(__NFUN_172__(Player.GetHealth(), Player.GetMaxHealth()), float(Player.GetNumberOfItems(MedHypoClass))));
			}
		}
	}
	AddSample(MedHypoStats, float(Player.GetNumberOfItems(MedHypoClass)));
	goto J0x418;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x418
	/*@Error*/
	AddSample(BioAmmoStats, __NFUN_172__(Player.GetBioAmmo(), Player.GetMaxBioAmmo()));
	AddSample(TotalBioAmmoStats, __NFUN_174__(__NFUN_172__(Player.GetBioAmmo(), Player.GetMaxBioAmmo()), float(Player.GetNumberOfItems(BioAmmoHypoClass))));
	// Failed to format nests!:System.ArgumentOutOfRangeException: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
   at System.Collections.Generic.List`1.get_Item(Int32 index)
   at UELib.Core.UStruct.UByteCodeDecompiler.DecompileNests(Boolean outputAllRemainingNests) in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 849
   at UELib.Core.UStruct.UByteCodeDecompiler.Decompile() in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 702
	// 1 & Type:If Position:0x321
	AddSample(BioAmmoHypoStats, float(Player.GetNumberOfItems(BioAmmoHypoClass)));
	// Failed to format nests!:System.ArgumentOutOfRangeException: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
   at System.Collections.Generic.List`1.get_Item(Int32 index)
   at UELib.Core.UStruct.UByteCodeDecompiler.DecompileNests(Boolean outputAllRemainingNests) in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 849
   at UELib.Core.UStruct.UByteCodeDecompiler.Decompile() in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 702
	// 1 & Type:If Position:0x321
	return;
	// Failed to format nests!:System.ArgumentOutOfRangeException: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
   at System.Collections.Generic.List`1.get_Item(Int32 index)
   at UELib.Core.UStruct.UByteCodeDecompiler.DecompileNests(Boolean outputAllRemainingNests) in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 849
   at UELib.Core.UStruct.UByteCodeDecompiler.Decompile() in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 702
	// 1 & Type:If Position:0x321
	@NULL
	// Failed to format nests!:System.ArgumentOutOfRangeException: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
   at System.Collections.Generic.List`1.get_Item(Int32 index)
   at UELib.Core.UStruct.UByteCodeDecompiler.DecompileNests(Boolean outputAllRemainingNests) in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 849
   at UELib.Core.UStruct.UByteCodeDecompiler.Decompile() in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 702
	// 1 & Type:If Position:0x321
	Item
	// Failed to format nests!:System.ArgumentOutOfRangeException: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
   at System.Collections.Generic.List`1.get_Item(Int32 index)
   at UELib.Core.UStruct.UByteCodeDecompiler.DecompileNests(Boolean outputAllRemainingNests) in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 849
   at UELib.Core.UStruct.UByteCodeDecompiler.Decompile() in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 702
	// 1 & Type:If Position:0x321
	Item
	// Failed to format nests!:System.ArgumentOutOfRangeException: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
   at System.Collections.Generic.List`1.get_Item(Int32 index)
   at UELib.Core.UStruct.UByteCodeDecompiler.DecompileNests(Boolean outputAllRemainingNests) in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 849
   at UELib.Core.UStruct.UByteCodeDecompiler.Decompile() in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 702
	// 1 & Type:If Position:0x321
	@NULL
	// Failed to format nests!:System.ArgumentOutOfRangeException: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
   at System.Collections.Generic.List`1.get_Item(Int32 index)
   at UELib.Core.UStruct.UByteCodeDecompiler.DecompileNests(Boolean outputAllRemainingNests) in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 849
   at UELib.Core.UStruct.UByteCodeDecompiler.Decompile() in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 702
	// 1 & Type:If Position:0x321
	// Failed to format remaining nests!:System.ArgumentOutOfRangeException: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
   at System.Collections.Generic.List`1.get_Item(Int32 index)
   at UELib.Core.UStruct.UByteCodeDecompiler.DecompileNests(Boolean outputAllRemainingNests) in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 849
   at UELib.Core.UStruct.UByteCodeDecompiler.Decompile() in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 724
	// 1 & Type:If Position:0x321
}

function PlayerDied(Actor Killer)
{
	AddSample(DeathReloadStats, __NFUN_174__(GetLastSampleValue(DeathReloadStats), float(1)));
	DifficultyManager.OutputSessionData();
	return;
	@NULL
	Item
	Item
}

function CraftedItem(ShockPlayer Player, Class<Item> ItemClass)
{
	GotItemFromMachine(ItemClass, Player);
	return;
	@NULL
	Item
}

function PurchasedItem(Class<Item> ItemClass, ShockPlayer Player)
{
	AddSample(CreditsStats, float(Player.GetCredits()));
	GotItemFromMachine(ItemClass, Player);
	return;
	@NULL
	Item
	Item
	@NULL
}

defaultproperties
{
	DeathReloadStats=(Samples=none,NextSampleIndex=0,StatType=1,MaxSamples=(Low=1,Normal=2,High=3,Extreme=3),BonusPerCredit=0.0000000,FriendlyName="Death/Reload",Value=0.0000000,BaseValue=0.0000000)
	HealthStats=(Samples=none,NextSampleIndex=0,StatType=0,MaxSamples=(Low=4,Normal=4,High=4,Extreme=4),BonusPerCredit=0.0300000,FriendlyName="Current Health",Value=0.0000000,BaseValue=0.0000000)
	TotalHealthStats=(Samples=none,NextSampleIndex=0,StatType=0,MaxSamples=(Low=4,Normal=4,High=4,Extreme=4),BonusPerCredit=0.0300000,FriendlyName="Total Health",Value=0.0000000,BaseValue=0.0000000)
	MedHypoStats=(Samples=none,NextSampleIndex=0,StatType=0,MaxSamples=(Low=5,Normal=5,High=5,Extreme=5),BonusPerCredit=0.0000000,FriendlyName="Med Hypo",Value=0.0000000,BaseValue=0.0000000)
	MedHypoClass=Class'ShockGame.ShockDesignerClasses.MedHypo'
	BioAmmoStats=(Samples=none,NextSampleIndex=0,StatType=0,MaxSamples=(Low=5,Normal=5,High=5,Extreme=5),BonusPerCredit=0.0250000,FriendlyName="BioAmmo",Value=0.0000000,BaseValue=0.0000000)
	TotalBioAmmoStats=(Samples=none,NextSampleIndex=0,StatType=0,MaxSamples=(Low=5,Normal=5,High=5,Extreme=5),BonusPerCredit=0.0250000,FriendlyName="Total BioAmmo",Value=0.0000000,BaseValue=0.0000000)
	BioAmmoHypoStats=(Samples=none,NextSampleIndex=0,StatType=0,MaxSamples=(Low=5,Normal=5,High=5,Extreme=5),BonusPerCredit=0.0000000,FriendlyName="BioAmmo Hypo",Value=0.0000000,BaseValue=0.0000000)
	BioAmmoHypoClass=Class'ShockGame.ShockDesignerClasses.BioAmmoHypo'
	CreditsStats=(Samples=none,NextSampleIndex=0,StatType=0,MaxSamples=(Low=5,Normal=5,High=5,Extreme=5),BonusPerCredit=0.0000000,FriendlyName="Credits",Value=0.0000000,BaseValue=0.0000000)
	PistolAmmoStats=(Samples=none,NextSampleIndex=0,StatType=0,MaxSamples=(Low=5,Normal=5,High=5,Extreme=5),BonusPerCredit=0.0800000,FriendlyName="Pistol Ammo",Value=0.0000000,BaseValue=0.0000000)
	ShotgunAmmoStats=(Samples=none,NextSampleIndex=0,StatType=0,MaxSamples=(Low=5,Normal=5,High=5,Extreme=5),BonusPerCredit=0.0500000,FriendlyName="Shotgun Ammo",Value=0.0000000,BaseValue=0.0000000)
	CrossbowAmmoStats=(Samples=none,NextSampleIndex=0,StatType=0,MaxSamples=(Low=5,Normal=5,High=5,Extreme=5),BonusPerCredit=0.0900000,FriendlyName="Crossbow Ammo",Value=0.0000000,BaseValue=0.0000000)
	ChemicalThrowerAmmoStats=(Samples=none,NextSampleIndex=0,StatType=0,MaxSamples=(Low=5,Normal=5,High=5,Extreme=5),BonusPerCredit=0.4400000,FriendlyName="Chemical Thrower Ammo",Value=0.0000000,BaseValue=0.0000000)
	MachineGunAmmoStats=(Samples=none,NextSampleIndex=0,StatType=0,MaxSamples=(Low=5,Normal=5,High=5,Extreme=5),BonusPerCredit=0.3300000,FriendlyName="Machine Gun Ammo",Value=0.0000000,BaseValue=0.0000000)
	GrenadeLauncherAmmoStats=(Samples=none,NextSampleIndex=0,StatType=0,MaxSamples=(Low=5,Normal=5,High=5,Extreme=5),BonusPerCredit=0.0250000,FriendlyName="Grenade Launcher Ammo",Value=0.0000000,BaseValue=0.0000000)
}