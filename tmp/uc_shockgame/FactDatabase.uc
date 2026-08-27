class FactDatabase extends Object
	native
	config(Training);

struct native atomic FactPattern
{
	var name Slot_1;
	var string Slot_2;
	var string Slot_3;

	structdefaultproperties
	{
		CheckpointTypePadding=7602293
	}
};

struct native atomic Fact
{
	var travel name Slot_1;
	var travel string Slot_2;
	var travel string Slot_3;
	var travel float FirstTimeAsserted;
	var travel float LastTimeAsserted;
	var travel int TimesAsserted;
	var travel bool persist;

	structdefaultproperties
	{
		CheckpointTypePadding=7602293
	}
};

var private transient ShockGameDriver GameDriver;
var array<Fact> FactStore;
var config array<name> PredefinedFacts;

function Construct(ShockGameDriver GameDriver)
{
	self.GameDriver = GameDriver;
	return;
	@NULL
	Item
}

function PreLevelLoad()
{
	return;
}

function PostLevelLoad()
{
	return;
}

function AssertFactDecomposed(name Slot_1, string Slot_2, string Slot_3, bool persist)
{
	local array<int> Indices;
	local Fact temp;

	GetFactIndices(Slot_1, Slot_2, Slot_3, Indices);
	// End:0x18D
	if(__NFUN_154__(Indices.Length, 0))
	{
		temp.Slot_1 = Slot_1;
		temp.Slot_2 = Slot_2;
		temp.Slot_3 = Slot_3;
		temp.LastTimeAsserted = GameDriver.GetPlayerStatsManager().GetGameplayTime();
		temp.FirstTimeAsserted = GameDriver.GetPlayerStatsManager().GetGameplayTime();
		temp.TimesAsserted = 1;
		temp.persist = persist;
		FactStore[FactStore.Length] = temp;
		goto J0x25F;
		__NFUN_163__(FactStore[Indices[0]].TimesAsserted);
		FactStore[Indices[0]].persist = __NFUN_132__(FactStore[Indices[0]].persist, persist);
		FactStore[Indices[0]].LastTimeAsserted = GameDriver.GetPlayerStatsManager().GetGameplayTime();
		return;
	}
	@NULL
	Item
	stop;
	return @NULL;
}

function ValidatePredefinedFact(name FactSlot_1)
{
	local int i;

	// End:0x1C
	if(__NFUN_155__(__NFUN_126__(string(FactSlot_1), "?"), -1))
	{
		return;
		i = 0;
	}
	// End:0x70
	if(__NFUN_150__(i, PredefinedFacts.Length))
	{
		// End:0x62
		if(__NFUN_254__(PredefinedFacts[i], FactSlot_1))
		{
			return;
			__NFUN_165__(i);
			// [Loop Continue]
			goto J0x27;
			log('Training', 2, __NFUN_112__(string(FactSlot_1), " is not a predefined fact, was it misspelled?"));
		}
	}
	return;
	@NULL
	Item
	ShockPawn
	@NULL
}

function AssertFact(FactPattern Pattern, optional bool persist, optional bool ValidateIsPredefinedFact)
{
	// End:0x31
	if(ValidateIsPredefinedFact)
	{
		ValidatePredefinedFact(Pattern.Slot_1);
		log('Training', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("Asserting Fact (", string(Pattern.Slot_1)), ","), Pattern.Slot_2), ","), Pattern.Slot_3), ")"));
	}
	AssertFactDecomposed(Pattern.Slot_1, Pattern.Slot_2, Pattern.Slot_3, persist);
	return;
	@NULL
	Item
	Item
	@NULL
}

function RetractFactDecomposed(name Slot_1, string Slot_2, string Slot_3, bool CheckTime)
{
	local array<int> Indices;
	local int i;

	GetFactIndices(Slot_1, Slot_2, Slot_3, Indices);
	i = __NFUN_147__(Indices.Length, 1);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xE9
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xDB
	/*@Error*/
	FactStore.Remove(Indices[i], 1);
	__NFUN_164__(i);
	// [Loop Continue]
	goto J0x45;
	return;
	@NULL
	Item
	stop;
	return @NULL;
}

function RetractFact(FactPattern Pattern, optional bool ValidateIsPredefinedFact)
{
	log('Training', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("Retracting Fact (", string(Pattern.Slot_1)), ","), Pattern.Slot_2), ","), Pattern.Slot_3), ")"));
	// End:0xB9
	if(ValidateIsPredefinedFact)
	{
		ValidatePredefinedFact(Pattern.Slot_1);
		RetractFactDecomposed(Pattern.Slot_1, Pattern.Slot_2, Pattern.Slot_3, false);
	}
	return;
	@NULL
	Item
	Item
	@NULL
}

function RetractFactNotAssertedThisFrame(FactPattern Pattern, optional bool ValidateIsPredefinedFact)
{
	log('Training', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("Retracting Fact (", string(Pattern.Slot_1)), ","), Pattern.Slot_2), ","), Pattern.Slot_3), ")"));
	// End:0xB9
	if(ValidateIsPredefinedFact)
	{
		ValidatePredefinedFact(Pattern.Slot_1);
		RetractFactDecomposed(Pattern.Slot_1, Pattern.Slot_2, Pattern.Slot_3, true);
	}
	return;
	@NULL
	Item
	Item
	@NULL
}

function GetFacts(FactPattern Pattern, out array<Fact> Facts, optional bool ValidateIsPredefinedFact)
{
	local array<int> Indices;
	local int i;

	// End:0x31
	if(ValidateIsPredefinedFact)
	{
		ValidatePredefinedFact(Pattern.Slot_1);
		GetFactIndices(Pattern.Slot_1, Pattern.Slot_2, Pattern.Slot_3, Indices);
	}
	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xF4
	/*@Error*/
	Facts[i] = FactStore[Indices[i]];
	__NFUN_165__(i);
	goto J0x9D;
	return;
	@NULL
	Item
	Item
	@NULL
}

function GetPersistentFacts(out array<Fact> Facts)
{
	local int i;

	Facts.Length = 0;
	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x8D
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x7F
	/*@Error*/
	Facts[Facts.Length] = FactStore[i];
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x17;
	return;
	@NULL
	Item
	Item
	@NULL
}

function RestorePersistentFacts(array<Fact> Facts)
{
	local int i, FactIndex;

	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x177
	/*@Error*/
	FactIndex = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x142
	/*@Error*/
	J0x2E:

	// End:0x134 [Loop If]
	if(__NFUN_130__(__NFUN_130__(__NFUN_254__(FactStore[FactIndex].Slot_1, Facts[i].Slot_1), __NFUN_122__(FactStore[FactIndex].Slot_2, Facts[i].Slot_2)), __NFUN_122__(FactStore[FactIndex].Slot_3, Facts[i].Slot_3)))
	{
		goto J0x142;
		__NFUN_163__(FactIndex);
		// [Loop Continue]
		goto J0x2E;
		FactStore[FactIndex] = Facts[i];
		__NFUN_163__(i);
		// [Loop Continue]
		goto J0x0B;
		return;
		@NULL
		Item
		Item
		@NULL
	}
}

function GetFactIndices(name Slot_1, string Slot_2, string Slot_3, out array<int> Indices)
{
	//native.Slot_1;
	//native.Slot_2;
	//native.Slot_3;
	//native.Indices;	
	@NULL
	@NULL
	return default.@NULL;
}

defaultproperties
{
	PredefinedFacts[0]="AbilityMenuOpen"
	PredefinedFacts[1]="AggressorGoingToHealthStation"
	PredefinedFacts[2]="AggressorHealedAtHealthStation"
	PredefinedFacts[3]="AggressorKilledGoingToHealthStation"
	PredefinedFacts[4]="AggressorPoisonedAtHealthStation"
	PredefinedFacts[5]="AlarmCancelled"
	PredefinedFacts[6]="AlarmExpired"
	PredefinedFacts[7]="AlarmSetOff"
	PredefinedFacts[8]="ApproachedLockedDoor"
	PredefinedFacts[9]="BadAmmoUsed"
	PredefinedFacts[10]="Befriend"
	PredefinedFacts[11]="ChangedAmmo"
	PredefinedFacts[12]="ClipAlmostEmpty"
	PredefinedFacts[13]="ClipAlmostFull"
	PredefinedFacts[14]="ClipEmpty"
	PredefinedFacts[15]="ClipFull"
	PredefinedFacts[16]="CraftingAvailable"
	PredefinedFacts[17]="DirectionalArrowUsed"
	PredefinedFacts[18]="Difficulty"
	PredefinedFacts[19]="DryFiredWeapon"
	PredefinedFacts[20]="EnoughEveToFireCurrentAbility"
	PredefinedFacts[21]="EnrageFailure"
	PredefinedFacts[22]="EquippedPlasmid"
	PredefinedFacts[23]="EquippedWeapon"
	PredefinedFacts[24]="FiredAbility"
	PredefinedFacts[25]="FiredWeapon"
	PredefinedFacts[26]="FrozenShattered"
	PredefinedFacts[27]="FrozenTimedOut"
	PredefinedFacts[28]="GoodAmmoAvailable"
	PredefinedFacts[29]="GoodAmmoUsed"
	PredefinedFacts[30]="HackedMachine"
	PredefinedFacts[31]="HarmGatherer"
	PredefinedFacts[32]="HarmNonHostile"
	PredefinedFacts[33]="HasEmptyGeneTonicSlot"
	PredefinedFacts[34]="HasEmptyPlasmidSlot"
	PredefinedFacts[35]="HasFourActivePlasmids"
	PredefinedFacts[36]="IsCrouching"
	PredefinedFacts[37]="IsNotCrouching"
	PredefinedFacts[38]="InPlasmidMode"
	PredefinedFacts[39]="InWeaponMode"
	PredefinedFacts[40]="InZoomMode"
	PredefinedFacts[41]="LastDamagedBy"
	PredefinedFacts[42]="LastDealtDamageTo"
	PredefinedFacts[43]="LastDealtStateTo"
	PredefinedFacts[44]="LastPlayerKill"
	PredefinedFacts[45]="LastPlayerUse"
	PredefinedFacts[46]="LookedAtHelp"
	PredefinedFacts[47]="LookedAtLogs"
	PredefinedFacts[48]="LookedAtMap"
	PredefinedFacts[49]="LookedAtQuests"
	PredefinedFacts[50]="LookedAtRadios"
	PredefinedFacts[51]="Looking"
	PredefinedFacts[52]="LookingAt"
	PredefinedFacts[53]="Movement"
	PredefinedFacts[54]="Near"
	PredefinedFacts[55]="NewPlasmidAcquired"
	PredefinedFacts[56]="NoLooking"
	PredefinedFacts[57]="NoMovement"
	PredefinedFacts[58]="NoOtherAmmoAvailable"
	PredefinedFacts[59]="NoReloadAvailable"
	PredefinedFacts[60]="NotApproachedLockedDoor"
	PredefinedFacts[61]="NotEnoughEveToFireCurrentAbility"
	PredefinedFacts[62]="NotInZoomMode"
	PredefinedFacts[63]="OKAmmoAvailable"
	PredefinedFacts[64]="OKAmmoUsed"
	PredefinedFacts[65]="OtherAmmoAvailable"
	PredefinedFacts[66]="PictureTaken"
	PredefinedFacts[67]="PickedUpCraftingComponent"
	PredefinedFacts[68]="PlayerPickedUpInventory"
	PredefinedFacts[69]="PlayerChangedMapUIRegion"
	PredefinedFacts[70]="PlayerDied"
	PredefinedFacts[71]="PlayerEVEFull"
	PredefinedFacts[72]="PlayerEVEHigh"
	PredefinedFacts[73]="PlayerEVELow"
	PredefinedFacts[74]="PlayerEVEEmpty"
	PredefinedFacts[75]="PlayerHasSpentEPPs"
	PredefinedFacts[76]="PlayerHealthFull"
	PredefinedFacts[77]="PlayerHealthHigh"
	PredefinedFacts[78]="PlayerHealthMedium"
	PredefinedFacts[79]="PlayerHealthLow"
	PredefinedFacts[80]="PlayerHealthCritical"
	PredefinedFacts[81]="PlayerLeaned"
	PredefinedFacts[82]="PlayerShocked"
	PredefinedFacts[83]="Resistant"
	PredefinedFacts[84]="ReloadAvailable"
	PredefinedFacts[85]="Researched"
	PredefinedFacts[86]="SavedGame"
	PredefinedFacts[87]="SavedGatherer"
	PredefinedFacts[88]="SecurityBeacon"
	PredefinedFacts[89]="SearchedAContainer"
	PredefinedFacts[90]="SecurityCameraLostPlayer"
	PredefinedFacts[91]="SecurityCameraSeesPlayer"
	PredefinedFacts[92]="TelekinesisUsed"
	PredefinedFacts[93]="UnEquippedPlasmid"
	PredefinedFacts[94]="UnreadLogs"
	PredefinedFacts[95]="WeaponMenuOpen"
	PredefinedFacts[96]="WeakButRich"
	PredefinedFacts[97]="VitaChamberOff"
	PredefinedFacts[98]="VitaChamberOn"
}