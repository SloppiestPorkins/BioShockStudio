class TrainingMessageManager extends Object
	native
	config(Training);

const NUM_TIPS = 3;

enum EPhotoRejectReason
{
	NOT_REJECTED,                   // 0
	REJECT_OFFSCREEN,               // 1
	REJECT_HACKED,                  // 2
	REJECT_NO_SUBJECT,              // 3
	REJECT_LOW_SCORE,               // 4
	REJECT_COMPLETE                 // 5
};

enum QueuePriority
{
	QUEUE_No,                       // 0
	QUEUE_Low,                      // 1
	QUEUE_Normal,                   // 2
	QUEUE_High,                     // 3
	QUEUE_Interrupt                 // 4
};

struct native atomic TrainingTip
{
	var name Name;
	var localized string Text;
	var localized string TextPC;
	var TrainingMessageManager.QueuePriority QueuePriority;
	var bool PlayOnce;

	structdefaultproperties
	{
		CheckpointTypePadding=7602293
	}
};

struct native atomic TrainingMessage
{
	var name Name;
	var localized string Text;
	var localized string TextPC;
	var name HelpTag;
	var TrainingMessageManager.QueuePriority QueuePriority;
	var float RepeatDelay;
	var bool ShowInCombat;
	var bool DoNotShowWhenHasFocus;
	var bool IsModal;
	var bool NotAdaptive;
	var name SpokenDialog;
	var name GlowHudItem;

	structdefaultproperties
	{
		CheckpointTypePadding=7602293
	}
};

struct native atomic NearCheckInfo
{
	var name ClassName;
	var float Distance;
	var bool AssertedThisFrame;

	structdefaultproperties
	{
		CheckpointTypePadding=7602293
	}
};

struct native atomic TriggeredMessage
{
	var int Index;
	var TrainingMessageTrigger MessageTrigger;

	structdefaultproperties
	{
		CheckpointTypePadding=7602293
	}
};

var config localized array<localized TrainingMessage> TrainingMessages;
var config localized array<localized TrainingTip> TrainingTips;
var private config float TipRepeatDelay;
var private int SelectedTips[3];
var private int NumTipsDisplayed;
var private bool TipsSelected;
var private config float TipDisplayTime;
var private config float MinTipDisplayTime;
var array<TriggeredMessage> TriggeredMessages;
var private transient ShockGameDriver GameDriver;
var private config float MessageSuppressionTime;
var private config float MessageCombatSuppressionTime;
var private float LastMessageDisplayedTime;
var private name LastMessageDisplayedName;
var const config bool EnableTrainingScripts;
var config bool EnableAdaptiveMessages;
var config bool EnableTrainingLogs;
var config float TrainingMessageBaseDuration;
var config float TrainingMessageCharacterMultiplier;
var config array<NearCheckInfo> NearnessChecks;
var config float TelekinesisFlubTime;
var config float TimeToConsiderEnrageFailure;
var private float MaxNearCheckDistance;
var private float MaxNearCheckDistanceSquare;
var private float LastNearCheckLevelTime;
var private transient FactDatabase FactDatabase;

function string SubstituteKeyMappingTags(string TextPC, string MessageName)
{
	//native.TextPC;
	//native.MessageName;	
	@NULL
	@NULL
}

function bool TriggerTrainingMessage(name MessageName, TrainingMessageTrigger MessageTrigger)
{
	//native.MessageName;
	//native.MessageTrigger;	
	@NULL
	@NULL
}

function bool ClearTrainingMessage(name MessageName)
{
	//native.MessageName;	
	@NULL
}

function SetTipPriority(name TipName, TrainingMessageManager.QueuePriority Priority)
{
	local Controller Controller;
	local ShockPlayer Player;
	local int i;

	Controller = GameDriver.GetLevel().GetLocalPlayerController();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x104
	/*@Error*/
	Player = ShockPlayer(Controller.Pawn);
	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x104
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xF6
	/*@Error*/
	Player.TipsQueuePriority[i] = Priority;
	goto J0x104;
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x7F;
	return;
	@NULL
	Item
	Item
	@NULL
}

function bool TipAlreadySelected(int Index)
{
	local int i;

	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x4C
	/*@Error*/
	// End:0x3E
	if(__NFUN_154__(SelectedTips[i], Index))
	{
		return true;
		__NFUN_163__(i);
		// [Loop Continue]
		goto J0x0B;
		return false;
		return;
		@NULL
		Item
	}
	ShockPawn
	@NULL
}

function int GetTipWithPriority(TrainingMessageManager.QueuePriority Priority)
{
	local int i, NumTips, Tip;

	i = 0;
	// End:0x8B
	if(__NFUN_150__(i, TrainingTips.Length))
	{
		// End:0x7D
		if(__NFUN_154__(int(TrainingTips[i].QueuePriority), int(Priority)))
		{
			// End:0x72
			if(TipAlreadySelected(i))
			{
				goto J0x7D;
				__NFUN_163__(NumTips);
				__NFUN_163__(i);
				// [Loop Continue]
				goto J0x0B;
				Tip = __NFUN_167__(NumTips);
				NumTips = 0;
			}
			i = 0;
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x157
			/*@Error*/
		}
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x149
		/*@Error*/
	}
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x11D
	/*@Error*/
	goto J0x149;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x13E
	/*@Error*/
	return i;
	__NFUN_163__(NumTips);
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0xB6;
	return -1;
	return;
	@NULL
	Item
	ShockPawn
	@NULL
}

function int GetNextTipWithPriority(ShockPlayer Player, TrainingMessageManager.QueuePriority Priority, bool CheckDisplayTime)
{
	local int i, NumTips, Tip;

	i = 0;
	// End:0xEF
	if(__NFUN_150__(i, TrainingTips.Length))
	{
		// End:0xE1
		if(__NFUN_130__(__NFUN_154__(int(Player.TipsQueuePriority[i]), int(Priority)), __NFUN_132__(__NFUN_129__(CheckDisplayTime), __NFUN_177__(__NFUN_175__(GameDriver.GetPlayerStatsManager().GetGameplayTime(), Player.LastTipDisplayTimes[i]), TipRepeatDelay))))
		{
			// End:0xD6
			if(TipAlreadySelected(i))
			{
				goto J0xE1;
				__NFUN_163__(NumTips);
				__NFUN_163__(i);
				// [Loop Continue]
				goto J0x0B;
				Tip = __NFUN_167__(NumTips);
				NumTips = 0;
				i = 0;
				/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
					
				*/

				// End:0x21F
				/*@Error*/
			}
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x211
			/*@Error*/
		}
	}
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x1E5
	/*@Error*/
	goto J0x211;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x206
	/*@Error*/
	return i;
	__NFUN_163__(NumTips);
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x11A;
	return -1;
	return;
	@NULL
	Item
	ShockPawn
	@NULL
}

function SelectNextTip()
{
	local Controller Controller;
	local ShockPlayer Player;
	local int i;

	// End:0x0F
	if(TipsSelected)
	{
		return;
		i = 0;
	}
	// End:0x51
	if(__NFUN_150__(i, 3))
	{
		SelectedTips[i] = -1;
		__NFUN_163__(i);
		// [Loop Continue]
		goto J0x1A;
		NumTipsDisplayed = 0;
		Controller = GameDriver.GetLevel().GetLocalPlayerController();
	}
	// End:0x19E
	if(__NFUN_132__(__NFUN_114__(Controller, none), __NFUN_114__(Controller.Pawn, none)))
	{
		i = 0;
		// End:0x19B
		if(__NFUN_150__(i, 3))
		{
			SelectedTips[i] = GetTipWithPriority(3);
			// End:0x130
			if(__NFUN_154__(SelectedTips[i], -1))
			{
				SelectedTips[i] = GetTipWithPriority(2);
				// End:0x16D
				if(__NFUN_154__(SelectedTips[i], -1))
				{
					SelectedTips[i] = GetTipWithPriority(1);
					// End:0x18D
					if(__NFUN_154__(SelectedTips[i], -1))
					{
						goto J0x19B;
						__NFUN_163__(i);
						// [Loop Continue]
						goto J0xC3;
						goto J0x39D;
						Player = ShockPlayer(Controller.Pawn);
					}
					i = 0;
					/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
						
					*/

					// End:0x39D
					/*@Error*/
					SelectedTips[i] = GetNextTipWithPriority(Player, 3, true);
				}
				// End:0x253
				if(__NFUN_154__(SelectedTips[i], -1))
				{
				}
				SelectedTips[i] = GetNextTipWithPriority(Player, 2, true);
			}
		}
		// End:0x29A
		if(__NFUN_154__(SelectedTips[i], -1))
		{
			SelectedTips[i] = GetNextTipWithPriority(Player, 1, true);
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x2E1
			/*@Error*/
			SelectedTips[i] = GetNextTipWithPriority(Player, 3, false);
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x328
			/*@Error*/
			SelectedTips[i] = GetNextTipWithPriority(Player, 2, false);
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x36F
			/*@Error*/
		}
		SelectedTips[i] = GetNextTipWithPriority(Player, 1, false);
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x38F
		/*@Error*/
		goto J0x39D;
		__NFUN_163__(i);
		// [Loop Continue]
		goto J0x1D2;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x3BE
		/*@Error*/
	}
	TipsSelected = true;
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

// Export UTrainingMessageManager::execShouldUseController(FFrame&, void* const)
native function bool ShouldUseController();

function GetTips(out array<string> Tips)
{
	local string TextPC;
	local int i;

	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x17A
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x16C
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x129
	/*@Error*/
	TextPC = TrainingTips[SelectedTips[i]].TextPC;
	Tips[Tips.Length] = SubstituteKeyMappingTags(TextPC, string(TrainingTips[SelectedTips[i]].Name));
	goto J0x16C;
	Tips[Tips.Length] = TrainingTips[SelectedTips[i]].Text;
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x0B;
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function TipsDisplayed(int NumTips)
{
	NumTipsDisplayed = NumTips;
	return;
	@NULL
	Item
}

function InitMaxNearCheckDistance()
{
	local int i;

	MaxNearCheckDistance = 0.0000000;
	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x7F
	/*@Error*/
	MaxNearCheckDistance = float(__NFUN_250__(int(MaxNearCheckDistance), int(NearnessChecks[i].Distance)));
	__NFUN_165__(i);
	// [Loop Continue]
	goto J0x1A;
	MaxNearCheckDistanceSquare = __NFUN_171__(MaxNearCheckDistance, MaxNearCheckDistance);
	return;
	@NULL
	Item
	ShockPawn
	@NULL
}

function Construct(ShockGameDriver GameDriver)
{
	self.GameDriver = GameDriver;
	InitMaxNearCheckDistance();
	return;
	@NULL
	Item
}

function PreLevelLoad()
{
	TriggeredMessages.Length = 0;
	FactDatabase = GameDriver.GetFactDatabase();
	FactDatabase.FactStore.Length = 0;
	SelectNextTip();
	return;
	@NULL
	Item
	Item
	@NULL
}

function PostLevelLoad()
{
	local Controller Controller;
	local ShockPlayer Player;
	local Weapon Weapon;
	local int i;

	LastNearCheckLevelTime = 0.0000000;
	Controller = GameDriver.GetLevel().GetLocalPlayerController();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x347
	/*@Error*/
	Player = ShockPlayer(Controller.Pawn);
	Weapon = Weapon(Player.GetActiveHoldable());
	// End:0xFC
	if(__NFUN_119__(Weapon, none))
	{
		AvailableAmmoStateChanged(Player, Weapon);
		ClipStateChanged(Weapon);
		ChangedDifficulty(Player);
		PlayerUnCrouched(Player);
		ZoomModeChanged(false);
		ChangedMapUIRegion(Player.Region.Zone.MapUIRegion);
	}
	PlayerInDoor(none);
	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x33C
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x32E
	/*@Error*/
	// End:0x217
	if(TrainingTips[SelectedTips[i]].PlayOnce)
	{
		Player.TipsQueuePriority[SelectedTips[i]] = 0;
		goto J0x2DE;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x27C
		/*@Error*/
		Player.TipsQueuePriority[SelectedTips[i]] = 2;
		goto J0x2DE;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x2DE
		/*@Error*/
		Player.TipsQueuePriority[SelectedTips[i]] = 1;
		Player.LastTipDisplayTimes[SelectedTips[i]] = GameDriver.GetPlayerStatsManager().GetGameplayTime();
	}
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x181;
	NumTipsDisplayed = 0;
	TipsSelected = false;
	return;
	@NULL
	Item
	Item
	@NULL
}

function AvailableAmmoStateChanged(ShockPlayer Player, Weapon Weapon)
{
	local FactPattern Pattern;
	local int AdditionalAmmoTypesWithAmmo, i;

	// End:0x164
	if(__NFUN_114__(Weapon.Class, Class'ShockGame.Wrench'))
	{
		log('PlayerStats', 4, "Wrench doesn't use ammo");
		Pattern.Slot_1 = 'ReloadAvailable';
		FactDatabase.RetractFact(Pattern, true);
		Pattern.Slot_1 = 'NoReloadAvailable';
		FactDatabase.RetractFact(Pattern, true);
		Pattern.Slot_1 = 'OtherAmmoAvailable';
		FactDatabase.RetractFact(Pattern, true);
		Pattern.Slot_1 = 'NoOtherAmmoAvailable';
		FactDatabase.AssertFact(Pattern, false, true);
		return;
		// End:0x25E
		if(__NFUN_151__(Player.GetNumberOfItems(Weapon.GetCurrentAmmoSelection()), Weapon.GetRoundsRemaining()))
		{
			log('PlayerStats', 4, "Reload available");
		}
		Pattern.Slot_1 = 'NoReloadAvailable';
		FactDatabase.RetractFact(Pattern, true);
		Pattern.Slot_1 = 'ReloadAvailable';
		FactDatabase.AssertFact(Pattern, false, true);
		goto J0x30E;
		log('PlayerStats', 4, "No Reload available");
		Pattern.Slot_1 = 'ReloadAvailable';
		FactDatabase.RetractFact(Pattern, true);
		Pattern.Slot_1 = 'NoReloadAvailable';
		FactDatabase.AssertFact(Pattern, false, true);
		AdditionalAmmoTypesWithAmmo = 0;
		i = 0;
	}
	// End:0x3DA
	if(__NFUN_150__(i, Weapon.AvailableAmmoTypes.Length))
	{
		// End:0x3CC
		if(__NFUN_130__(__NFUN_119__(Weapon.AvailableAmmoTypes[i], Weapon.GetCurrentAmmoSelection()), Player.HasAmmoRemaining(Weapon.AvailableAmmoTypes[i])))
		{
			__NFUN_163__(AdditionalAmmoTypesWithAmmo);
			__NFUN_163__(i);
			goto J0x324;
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x49D
			/*@Error*/
			log('PlayerStats', 4, "Other ammo available");
			Pattern.Slot_1 = 'NoOtherAmmoAvailable';
			FactDatabase.RetractFact(Pattern, true);
			Pattern.Slot_1 = 'OtherAmmoAvailable';
			FactDatabase.AssertFact(Pattern, false, true);
			goto J0x551;
			log('PlayerStats', 4, "No other ammo available");
			Pattern.Slot_1 = 'OtherAmmoAvailable';
			FactDatabase.RetractFact(Pattern, true);
		}
		Pattern.Slot_1 = 'NoOtherAmmoAvailable';
	}
	FactDatabase.AssertFact(Pattern, false, true);
	return;
	@NULL
	Item
	ShockPawn
	@NULL
}

function ClipStateChanged(Weapon Weapon)
{
	local FactPattern Pattern;

	// End:0x166
	if(__NFUN_114__(Weapon.Class, Class'ShockGame.Wrench'))
	{
		log('PlayerStats', 4, "Wrench doesn't have a clip");
		Pattern.Slot_1 = 'ClipFull';
		FactDatabase.RetractFact(Pattern, true);
		Pattern.Slot_1 = 'ClipEmpty';
		FactDatabase.RetractFact(Pattern, true);
		Pattern.Slot_1 = 'ClipAlmostFull';
		FactDatabase.RetractFact(Pattern, true);
		Pattern.Slot_1 = 'ClipAlmostEmpty';
		FactDatabase.RetractFact(Pattern, true);
		return;
		// End:0x2CC
		if(__NFUN_154__(Weapon.GetRoundsRemaining(), Weapon.GetMagazineSize()))
		{
			log('PlayerStats', 4, "Full clip");
			Pattern.Slot_1 = 'ClipEmpty';
		}
		FactDatabase.RetractFact(Pattern, true);
		Pattern.Slot_1 = 'ClipAlmostFull';
		FactDatabase.RetractFact(Pattern, true);
		Pattern.Slot_1 = 'ClipAlmostEmpty';
		FactDatabase.RetractFact(Pattern, true);
		Pattern.Slot_1 = 'ClipFull';
		FactDatabase.AssertFact(Pattern, false, true);
		goto J0x6C6;
		// End:0x41D
		if(__NFUN_152__(Weapon.GetRoundsRemaining(), 0))
		{
			log('PlayerStats', 4, "Empty clip");
			Pattern.Slot_1 = 'ClipFull';
			FactDatabase.RetractFact(Pattern, true);
			Pattern.Slot_1 = 'ClipAlmostFull';
			FactDatabase.RetractFact(Pattern, true);
			Pattern.Slot_1 = 'ClipAlmostEmpty';
			FactDatabase.RetractFact(Pattern, true);
		}
		Pattern.Slot_1 = 'ClipEmpty';
		FactDatabase.AssertFact(Pattern, false, true);
		goto J0x6C6;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x58E
		/*@Error*/
		log('PlayerStats', 4, "Almost Full clip");
		Pattern.Slot_1 = 'ClipFull';
		FactDatabase.RetractFact(Pattern, true);
		Pattern.Slot_1 = 'ClipEmpty';
		FactDatabase.RetractFact(Pattern, true);
		Pattern.Slot_1 = 'ClipAlmostEmpty';
		FactDatabase.RetractFact(Pattern, true);
		Pattern.Slot_1 = 'ClipAlmostFull';
		FactDatabase.AssertFact(Pattern, false, true);
	}
	goto J0x6C6;
	log('PlayerStats', 4, "Almost Empty clip");
	Pattern.Slot_1 = 'ClipFull';
	FactDatabase.RetractFact(Pattern, true);
	Pattern.Slot_1 = 'ClipEmpty';
	FactDatabase.RetractFact(Pattern, true);
	Pattern.Slot_1 = 'ClipAlmostFull';
	FactDatabase.RetractFact(Pattern, true);
	Pattern.Slot_1 = 'ClipAlmostEmpty';
	FactDatabase.AssertFact(Pattern, false, true);
	return;
	@NULL
	Item
	ShockPawn
	@NULL
}

function PlayerHealthChanged(ShockPlayer Player)
{
	local FactPattern Pattern;
	local float HealthRatio;

	HealthRatio = __NFUN_172__(Player.GetHealth(), Player.GetMaxHealth());
	// End:0x1C9
	if(__NFUN_176__(Player.GetHealth(), Player.NearDeathHealthThreshold))
	{
		Pattern.Slot_1 = 'PlayerHealthFull';
		FactDatabase.RetractFact(Pattern, true);
		Pattern.Slot_1 = 'PlayerHealthHigh';
		FactDatabase.RetractFact(Pattern, true);
		Pattern.Slot_1 = 'PlayerHealthMedium';
		FactDatabase.RetractFact(Pattern, true);
		Pattern.Slot_1 = 'PlayerHealthLow';
		FactDatabase.RetractFact(Pattern, true);
		Pattern.Slot_1 = 'PlayerHealthCritical';
		FactDatabase.AssertFact(Pattern, false, true);
		goto J0x773;
		// End:0x339
		if(__NFUN_180__(HealthRatio, 1.0000000))
		{
			Pattern.Slot_1 = 'PlayerHealthHigh';
			FactDatabase.RetractFact(Pattern, true);
			Pattern.Slot_1 = 'PlayerHealthMedium';
			FactDatabase.RetractFact(Pattern, true);
			Pattern.Slot_1 = 'PlayerHealthLow';
		}
		FactDatabase.RetractFact(Pattern, true);
		Pattern.Slot_1 = 'PlayerHealthCritical';
		FactDatabase.RetractFact(Pattern, true);
		Pattern.Slot_1 = 'PlayerHealthFull';
		FactDatabase.AssertFact(Pattern, false, true);
		goto J0x773;
		// End:0x4A9
		if(__NFUN_179__(HealthRatio, 0.6000000))
		{
			Pattern.Slot_1 = 'PlayerHealthFull';
			FactDatabase.RetractFact(Pattern, true);
			Pattern.Slot_1 = 'PlayerHealthMedium';
			FactDatabase.RetractFact(Pattern, true);
			Pattern.Slot_1 = 'PlayerHealthLow';
			FactDatabase.RetractFact(Pattern, true);
			Pattern.Slot_1 = 'PlayerHealthCritical';
			FactDatabase.RetractFact(Pattern, true);
			Pattern.Slot_1 = 'PlayerHealthHigh';
		}
		FactDatabase.AssertFact(Pattern, false, true);
		goto J0x773;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x619
		/*@Error*/
		Pattern.Slot_1 = 'PlayerHealthFull';
		FactDatabase.RetractFact(Pattern, true);
		Pattern.Slot_1 = 'PlayerHealthHigh';
		FactDatabase.RetractFact(Pattern, true);
		Pattern.Slot_1 = 'PlayerHealthLow';
		FactDatabase.RetractFact(Pattern, true);
		Pattern.Slot_1 = 'PlayerHealthCritical';
		FactDatabase.RetractFact(Pattern, true);
		Pattern.Slot_1 = 'PlayerHealthMedium';
		FactDatabase.AssertFact(Pattern, false, true);
		goto J0x773;
		Pattern.Slot_1 = 'PlayerHealthFull';
		FactDatabase.RetractFact(Pattern, true);
		Pattern.Slot_1 = 'PlayerHealthHigh';
	}
	FactDatabase.RetractFact(Pattern, true);
	Pattern.Slot_1 = 'PlayerHealthMedium';
	FactDatabase.RetractFact(Pattern, true);
	Pattern.Slot_1 = 'PlayerHealthCritical';
	FactDatabase.RetractFact(Pattern, true);
	Pattern.Slot_1 = 'PlayerHealthLow';
	FactDatabase.AssertFact(Pattern, false, true);
	return;
	@NULL
	Item
	ShockPawn
	@NULL
}

function PlayerBioAmmoChanged(ShockPlayer Player)
{
	local FactPattern Pattern;
	local float BioAmmoRatio, BioAmmo;

	BioAmmo = Player.GetBioAmmo();
	BioAmmoRatio = __NFUN_172__(BioAmmo, Player.GetMaxBioAmmo());
	// End:0x178
	if(__NFUN_180__(BioAmmoRatio, 1.0000000))
	{
		Pattern.Slot_1 = 'PlayerEVEHigh';
		FactDatabase.RetractFact(Pattern, true);
		Pattern.Slot_1 = 'PlayerEVELow';
		FactDatabase.RetractFact(Pattern, true);
		Pattern.Slot_1 = 'PlayerEVEEmpty';
		FactDatabase.RetractFact(Pattern, true);
		Pattern.Slot_1 = 'PlayerEVEFull';
		FactDatabase.AssertFact(Pattern, false, true);
		goto J0x4E3;
		// End:0x2A3
		if(__NFUN_179__(BioAmmoRatio, 0.5000000))
		{
			Pattern.Slot_1 = 'PlayerEVEFull';
			FactDatabase.RetractFact(Pattern, true);
			Pattern.Slot_1 = 'PlayerEVELow';
			FactDatabase.RetractFact(Pattern, true);
		}
		Pattern.Slot_1 = 'PlayerEVEEmpty';
		FactDatabase.RetractFact(Pattern, true);
		Pattern.Slot_1 = 'PlayerEVEHigh';
		FactDatabase.AssertFact(Pattern, false, true);
		goto J0x4E3;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x3CE
		/*@Error*/
		Pattern.Slot_1 = 'PlayerEVEFull';
		FactDatabase.RetractFact(Pattern, true);
		Pattern.Slot_1 = 'PlayerEVEHigh';
		FactDatabase.RetractFact(Pattern, true);
		Pattern.Slot_1 = 'PlayerEVEEmpty';
		FactDatabase.RetractFact(Pattern, true);
		Pattern.Slot_1 = 'PlayerEVELow';
		FactDatabase.AssertFact(Pattern, false, true);
	}
	goto J0x4E3;
	Pattern.Slot_1 = 'PlayerEVEFull';
	FactDatabase.RetractFact(Pattern, true);
	Pattern.Slot_1 = 'PlayerEVEHigh';
	FactDatabase.RetractFact(Pattern, true);
	Pattern.Slot_1 = 'PlayerEVELow';
	FactDatabase.RetractFact(Pattern, true);
	Pattern.Slot_1 = 'PlayerEVEEmpty';
	FactDatabase.AssertFact(Pattern, false, true);
	CanUseAbility(Player, Player.GetActiveAbility());
	return;
	@NULL
	Item
	ShockPawn
	@NULL
}

function CanUseAbility(ShockPlayer Player, Ability theActiveAbility)
{
	local FactPattern Pattern;

	Pattern.Slot_1 = 'EnoughEveToFireCurrentAbility';
	// End:0xE8
	if(__NFUN_130__(__NFUN_130__(__NFUN_119__(theActiveAbility, none), __NFUN_181__(theActiveAbility.GetBioAmmoCost(Player), float(0))), __NFUN_180__(Player.GetBioAmmo(), float(0))))
	{
		FactDatabase.AssertFact(Pattern, false, true);
		Pattern.Slot_1 = 'NotEnoughEveToFireCurrentAbility';
		FactDatabase.RetractFact(Pattern, true);
		goto J0x14F;
		FactDatabase.RetractFact(Pattern, true);
		Pattern.Slot_1 = 'NotEnoughEveToFireCurrentAbility';
		FactDatabase.AssertFact(Pattern, false, true);
	}
	return;
	@NULL
	Item
	ShockPawn
	@NULL
}

function AssertCompleteFormulas(ShockPlayer Player)
{
	//native.Player;	
	@NULL
}

function PlayerMovement(float X, float Y)
{
	local FactPattern Pattern;

	// End:0xB6
	if(__NFUN_132__(__NFUN_181__(X, 0.0000000), __NFUN_181__(Y, 0.0000000)))
	{
		Pattern.Slot_1 = 'NoMovement';
		FactDatabase.RetractFact(Pattern, true);
		Pattern.Slot_1 = 'Movement';
		FactDatabase.AssertFact(Pattern, false, true);
		goto J0x141;
		Pattern.Slot_1 = 'Movement';
		FactDatabase.RetractFact(Pattern, true);
	}
	Pattern.Slot_1 = 'NoMovement';
	FactDatabase.AssertFact(Pattern, false, true);
	return;
	@NULL
	Item
	Item
	@NULL
}

function PlayerView(float X, float Y)
{
	local FactPattern Pattern;

	// End:0xB6
	if(__NFUN_132__(__NFUN_181__(X, 0.0000000), __NFUN_181__(Y, 0.0000000)))
	{
		Pattern.Slot_1 = 'NoLooking';
		FactDatabase.RetractFact(Pattern, true);
		Pattern.Slot_1 = 'Looking';
		FactDatabase.AssertFact(Pattern, false, true);
		goto J0x141;
		Pattern.Slot_1 = 'Looking';
		FactDatabase.RetractFact(Pattern, true);
	}
	Pattern.Slot_1 = 'NoLooking';
	FactDatabase.AssertFact(Pattern, false, true);
	return;
	@NULL
	Item
	Item
	@NULL
}

function PlayerInspectedBySecurityCamera()
{
	local FactPattern Pattern;

	Pattern.Slot_1 = 'SecurityCameraLostPlayer';
	FactDatabase.RetractFact(Pattern, true);
	Pattern.Slot_1 = 'SecurityCameraSeesPlayer';
	FactDatabase.AssertFact(Pattern, false, true);
	return;
	@NULL
	Item
	Item
	@NULL
}

function PlayerEvadeSecurityCamera()
{
	local FactPattern Pattern;

	Pattern.Slot_1 = 'SecurityCameraSeesPlayer';
	FactDatabase.RetractFact(Pattern, true);
	Pattern.Slot_1 = 'SecurityCameraLostPlayer';
	FactDatabase.AssertFact(Pattern, false, true);
	return;
	@NULL
	Item
	Item
	@NULL
}

function PlayerTriggeredAlarm()
{
	local FactPattern Pattern;

	Pattern.Slot_1 = 'SecurityCameraLostPlayer';
	FactDatabase.RetractFact(Pattern, true);
	Pattern.Slot_1 = 'SecurityCameraSeesPlayer';
	FactDatabase.RetractFact(Pattern, true);
	Pattern.Slot_1 = 'AlarmExpired';
	FactDatabase.RetractFact(Pattern, true);
	Pattern.Slot_1 = 'AlarmCancelled';
	FactDatabase.RetractFact(Pattern, true);
	Pattern.Slot_1 = 'AlarmSetOff';
	FactDatabase.AssertFact(Pattern, false, true);
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function PlayerTriggeredAlarmTimedOut()
{
	local FactPattern Pattern;

	Pattern.Slot_1 = 'AlarmSetOff';
	FactDatabase.RetractFact(Pattern, true);
	Pattern.Slot_1 = 'AlarmExpired';
	FactDatabase.AssertFact(Pattern, false, true);
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function PlayerTriggeredAlarmCancelled()
{
	local FactPattern Pattern;

	Pattern.Slot_1 = 'AlarmSetOff';
	FactDatabase.RetractFact(Pattern, true);
	Pattern.Slot_1 = 'AlarmCancelled';
	FactDatabase.AssertFact(Pattern, false, true);
	return;
	@NULL
	Item
	Item
	@NULL
}

function PlayerDamaged(ShockPlayer Player, float Damage, Actor Damager)
{
	local FactPattern Pattern;

	Pattern.Slot_1 = 'LastDamagedBy';
	Pattern.Slot_2 = "?";
	FactDatabase.RetractFact(Pattern, true);
	Pattern.Slot_2 = string(Damager.Class.Name);
	FactDatabase.AssertFact(Pattern, false, true);
	return;
	@NULL
	Item
	Item
	@NULL
}

function PlayerDealtDamage(float Damage, Actor Damagee)
{
	local FactPattern Pattern;
	local ShockPawn Pawn;


	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x174
	/*@Error*/
	Pattern.Slot_1 = 'LastDealtDamageTo';
	Pattern.Slot_2 = "?";
	Pattern.Slot_3 = "?";
	FactDatabase.RetractFact(Pattern, true);
	Pattern.Slot_2 = string(Damagee.Class.Name);
	Pawn = ShockPawn(Damagee);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x135
	/*@Error*/
	Pattern.Slot_3 = string(Pawn.LastAcquiredState);
	goto J0x152;
	Pattern.Slot_3 = "";
	FactDatabase.AssertFact(Pattern, false, true);
	return;
	@NULL
	Item
	Item
	@NULL
}

function PlayerDirectHit(Actor Damagee)
{
	local FactPattern Pattern;
	local ShockPawn GathererEscort;
	local IPotentialAimTarget Target;
	local ShockPawn targetPawn;

	// End:0x1ED
	if(Damagee.__NFUN_303__('Gatherer'))
	{
		Pattern.Slot_1 = 'HarmGatherer';
		Pattern.Slot_2 = "?";
		FactDatabase.RetractFact(Pattern, true);
		GathererEscort = BaseShockAI(Damagee).GetShockPawnEscort();
		// End:0xE0
		if(__NFUN_114__(GathererEscort, none))
		{
			Pattern.Slot_2 = "NoEscort";
			goto J0x1CB;
			// End:0x186
			if(GathererEscort.__NFUN_303__('Protector'))
			{
				// End:0x153
				if(Class'Engine.Pawn'.static.checkAlive(GathererEscort))
				{
					Pattern.Slot_2 = "AliveProtectorEscort";
				}
				goto J0x183;
				Pattern.Slot_2 = "DeadProtectorEscort";
				goto J0x1CB;
				// End:0x1CB
				if(GathererEscort.__NFUN_303__('ShockPlayer'))
				{
					Pattern.Slot_2 = "PlayerEscort";
				}
				FactDatabase.AssertFact(Pattern, false, true);
				Target = IPotentialAimTarget(Damagee);
				targetPawn = ShockPawn(Damagee);
			}
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x38C
			/*@Error*/
		}
	}
	Pattern.Slot_1 = 'HarmNonHostile';
	Pattern.Slot_2 = "?";
	FactDatabase.RetractFact(Pattern, true);
	Pattern.Slot_2 = string(Damagee.Class.Name);
	FactDatabase.AssertFact(Pattern, false, true);
	return;
	@NULL
	Item
	Item
	@NULL
}

function PlayerDealtState(name StateName, Actor Damagee)
{
	local FactPattern Pattern;
	local ShockPawn Pawn;

	Pattern.Slot_1 = 'LastDealtStateTo';
	Pattern.Slot_2 = "?";
	Pattern.Slot_3 = "?";
	FactDatabase.RetractFact(Pattern, true);
	Pattern.Slot_2 = string(StateName);
	Pawn = ShockPawn(Damagee);
	// End:0x108
	if(__NFUN_119__(Pawn, none))
	{
		Pattern.Slot_3 = string(Pawn.LastAcquiredState);
		goto J0x125;
		Pattern.Slot_3 = "";
		FactDatabase.AssertFact(Pattern, false, true);
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x205
		/*@Error*/
		Pattern.Slot_1 = 'PlayerShocked';
	}
	Pattern.Slot_2 = "Turret";
	Pattern.Slot_3 = "";
	FactDatabase.AssertFact(Pattern, false, true);
	goto J0x2C8;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x2C8
	/*@Error*/
	Pattern.Slot_1 = 'PlayerShocked';
	Pattern.Slot_2 = "SecurityCamera";
	Pattern.Slot_3 = "";
	FactDatabase.AssertFact(Pattern, false, true);
	return;
	@NULL
	Item
	Item
	@NULL
}

function FrozenShattered()
{
	local FactPattern Pattern;

	Pattern.Slot_1 = 'FrozenTimedOut';
	FactDatabase.RetractFact(Pattern, true);
	Pattern.Slot_1 = 'FrozenShattered';
	FactDatabase.AssertFact(Pattern, false, true);
	return;
	@NULL
	Item
	Item
	@NULL
}

function FrozenTimedOut()
{
	local FactPattern Pattern;

	Pattern.Slot_1 = 'FrozenShattered';
	FactDatabase.RetractFact(Pattern, true);
	Pattern.Slot_1 = 'FrozenTimedOut';
	FactDatabase.AssertFact(Pattern, false, true);
	return;
	@NULL
	Item
	Item
	@NULL
}

function PlayerHitTarget(ShockPlayer Player, Actor Target, IProvideDamageData DamageData)
{
	local FactPattern Pattern;
	local float ResistanceFactor;
	local bool OKAmmoFound, GoodAmmoFound;
	local Weapon Weapon;
	local int i;

	Weapon = Player.GetWeaponFromDamageData(DamageData);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x884
	/*@Error*/
	ResistanceFactor = ShockPawn(Target).GetDamageResistanceTo(DamageData.Class);
	// End:0x211
	if(__NFUN_177__(ResistanceFactor, 1.0000000))
	{
		log('PlayerStats', 4, __NFUN_112__("Weak against ", string(DamageData.Class.Name)));
		Pattern.Slot_1 = 'BadAmmoUsed';
		FactDatabase.RetractFact(Pattern, true);
		Pattern.Slot_1 = 'OKAmmoUsed';
		FactDatabase.RetractFact(Pattern, true);
		Pattern.Slot_1 = 'GoodAmmoUsed';
		FactDatabase.AssertFact(Pattern, false, true);
		GoodAmmoFound = __NFUN_153__(Player.GetNumberOfItems(Weapon.GetCurrentAmmoSelection()), Weapon.GetMagazineSize());
		goto J0x5F4;
		// End:0x33F
		if(__NFUN_176__(ResistanceFactor, 1.0000000))
		{
			log('PlayerStats', 4, __NFUN_112__("Strong against ", string(DamageData.Class.Name)));
			Pattern.Slot_1 = 'GoodAmmoUsed';
			FactDatabase.RetractFact(Pattern, true);
			Pattern.Slot_1 = 'OKAmmoUsed';
		}
		FactDatabase.RetractFact(Pattern, true);
		Pattern.Slot_1 = 'BadAmmoUsed';
		FactDatabase.AssertFact(Pattern, false, true);
		goto J0x5F4;
		log('PlayerStats', 4, __NFUN_112__("Neutral against ", string(DamageData.Class.Name)));
		// End:0x4D2
		if(__NFUN_119__(DamageData.Class, Weapon.GetDefaultAmmoSelection()))
		{
			log('PlayerStats', 4, __NFUN_112__("Wasted ammo ", string(DamageData.Class.Name)));
			Pattern.Slot_1 = 'GoodAmmoUsed';
			FactDatabase.RetractFact(Pattern, true);
			Pattern.Slot_1 = 'OKAmmoUsed';
		}
		FactDatabase.RetractFact(Pattern, true);
		Pattern.Slot_1 = 'BadAmmoUsed';
		FactDatabase.AssertFact(Pattern, false, true);
		goto J0x5F4;
		Pattern.Slot_1 = 'GoodAmmoUsed';
		FactDatabase.RetractFact(Pattern, true);
		Pattern.Slot_1 = 'BadAmmoUsed';
		FactDatabase.RetractFact(Pattern, true);
		Pattern.Slot_1 = 'OKAmmoUsed';
		FactDatabase.AssertFact(Pattern, false, true);
		OKAmmoFound = __NFUN_153__(Player.GetNumberOfItems(Weapon.GetCurrentAmmoSelection()), Weapon.GetMagazineSize());
		i = 0;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x74E
		/*@Error*/
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x740
		/*@Error*/
	}
	ResistanceFactor = ShockPawn(Target).GetDamageResistanceTo(Weapon.AvailableAmmoTypes[i]);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x721
	/*@Error*/
	OKAmmoFound = true;
	goto J0x740;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x740
	/*@Error*/
	GoodAmmoFound = true;
	__NFUN_163__(i);
	goto J0x5FF;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x7A4
	/*@Error*/
	Pattern.Slot_1 = 'OKAmmoAvailable';
	FactDatabase.AssertFact(Pattern, false, true);
	goto J0x7E9;
	Pattern.Slot_1 = 'OKAmmoAvailable';
	FactDatabase.RetractFact(Pattern, true);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x83F
	/*@Error*/
	Pattern.Slot_1 = 'GoodAmmoAvailable';
	FactDatabase.AssertFact(Pattern, false, true);
	goto J0x884;
	Pattern.Slot_1 = 'GoodAmmoAvailable';
	FactDatabase.RetractFact(Pattern, true);
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function KilledByPlayer(Actor Killed)
{
	local FactPattern Pattern;

	Pattern.Slot_1 = 'LastPlayerKill';
	Pattern.Slot_2 = "?";
	FactDatabase.RetractFact(Pattern, true);
	Pattern.Slot_2 = string(Killed.Class.Name);
	FactDatabase.AssertFact(Pattern, false, true);
	return;
	@NULL
	Item
	Item
	@NULL
}

function PlayerDied(Actor Killer)
{
	local FactPattern Pattern;
	local IPhotographTarget ResearchTarget;

	Pattern.Slot_1 = 'PlayerDied';
	Pattern.Slot_2 = "?";
	FactDatabase.RetractFact(Pattern, true);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x114
	/*@Error*/
	ResearchTarget = IPhotographTarget(Killer);
	// End:0xD4
	if(__NFUN_119__(ResearchTarget, none))
	{
		Pattern.Slot_2 = string(ResearchTarget.GetPhotographLabel());
		goto J0x114;
		Pattern.Slot_2 = string(Killer.Class.Name);
		FactDatabase.AssertFact(Pattern, false, true);
		return;
	}
	@NULL
	Item
	Item
	@NULL
}

function PlayerWeaponEquipped(ShockPlayer Player, Weapon Weapon)
{
	local FactPattern Pattern;

	AvailableAmmoStateChanged(Player, Weapon);
	ClipStateChanged(Weapon);
	Pattern.Slot_1 = 'EquippedWeapon';
	Pattern.Slot_2 = "?";
	FactDatabase.RetractFact(Pattern, true);
	Pattern.Slot_2 = string(Weapon.Class.Name);
	FactDatabase.AssertFact(Pattern, false, true);
	return;
	@NULL
	Item
	Item
	@NULL
}

function PlayerWeaponReloaded(ShockPlayer Player, Weapon Weapon)
{
	AvailableAmmoStateChanged(Player, Weapon);
	ClipStateChanged(Weapon);
	return;
	@NULL
	Item
	Item
}

function PlayerWeaponFired(ShockPlayer Player, Weapon Weapon)
{
	local FactPattern Pattern;

	ClipStateChanged(Weapon);
	Pattern.Slot_1 = 'FiredWeapon';
	Pattern.Slot_2 = string(Weapon.Class.Name);
	FactDatabase.AssertFact(Pattern, false, true);
	Pattern.Slot_1 = 'DryFiredWeapon';
	Pattern.Slot_2 = "";
	FactDatabase.RetractFact(Pattern, true);
	return;
	@NULL
	Item
	Item
	@NULL
}

function SelectedAbility(ShockPlayer Player, Ability Ability)
{
	CanUseAbility(Player, Ability);
	return;
	@NULL
	Item
}

function PlayerPlasmidEquipped(ShockPlayer Player, Plasmid Plasmid)
{
	local FactPattern Pattern;
	local int GeneTonicSlots, GeneTonicEquipped, ActiveSlots, ActiveEquipped, TotalSlots, TotalEquipped;

	Pattern.Slot_1 = 'EquippedPlasmid';
	Pattern.Slot_2 = "?";
	FactDatabase.RetractFact(Pattern, true);
	Pattern.Slot_2 = string(Plasmid.Class.Name);
	FactDatabase.AssertFact(Pattern, false, true);
	Pattern.Slot_2 = "";
	TotalSlots = Player.NumUnlockedTrackSlots(0);
	TotalEquipped = Player.NumEquippedPlasmids(0);
	// End:0x184
	if(__NFUN_154__(TotalEquipped, TotalSlots))
	{
		Pattern.Slot_1 = 'HasEmptyPlasmidSlot';
		FactDatabase.RetractFact(Pattern, true);
		ActiveSlots = Player.NumUnlockedTrackSlots(1);
		ActiveEquipped = Player.NumEquippedPlasmids(1);
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x239
		/*@Error*/
		Pattern.Slot_1 = 'HasFourActivePlasmids';
		FactDatabase.AssertFact(Pattern, false, true);
	}
	GeneTonicSlots = __NFUN_147__(TotalSlots, ActiveSlots);
	GeneTonicEquipped = __NFUN_147__(TotalEquipped, ActiveEquipped);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x2D1
	/*@Error*/
	Pattern.Slot_1 = 'HasEmptyGeneTonicSlot';
	FactDatabase.RetractFact(Pattern, true);
	return;
	@NULL
	Item
	Item
	@NULL
}

function PlayerPlasmidUnEquipped(ShockPlayer Player, Plasmid Plasmid)
{
	local FactPattern Pattern;

	Pattern.Slot_1 = 'UnEquippedPlasmid';
	Pattern.Slot_2 = "?";
	FactDatabase.RetractFact(Pattern, true);
	Pattern.Slot_2 = string(Plasmid.Class.Name);
	FactDatabase.AssertFact(Pattern, false, true);
	Pattern.Slot_1 = 'HasEmptyPlasmidSlot';
	Pattern.Slot_2 = "";
	FactDatabase.AssertFact(Pattern, false, true);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x18F
	/*@Error*/
	Pattern.Slot_1 = 'HasEmptyGeneTonicSlot';
	FactDatabase.AssertFact(Pattern, false, true);
	return;
	@NULL
	Item
	Item
	@NULL
}

function PlayerAbilityFired(ShockPlayer Player, Ability Ability)
{
	local FactPattern Pattern;

	Pattern.Slot_1 = 'FiredAbility';
	Pattern.Slot_2 = string(Ability.Class.Name);
	FactDatabase.AssertFact(Pattern, false, true);
	return;
	@NULL
	Item
	Item
	@NULL
}

function CraftedItem(ShockPlayer Player)
{
	AssertCompleteFormulas(Player);
	return;
	@NULL
}

function PlayerPickedUpInventory(ShockPlayer Player, Class<Item> ItemClass, int Amount)
{
	local Weapon Weapon;
	local FactPattern Pattern;

	Weapon = Weapon(Player.GetActiveHoldable());
	// End:0x6F
	if(__NFUN_130__(__NFUN_119__(Weapon, none), __NFUN_258__(ItemClass, Class'ShockGame.Ammunition')))
	{
		AvailableAmmoStateChanged(Player, Weapon);
		// End:0x104
		if(__NFUN_130__(__NFUN_258__(ItemClass, Class'ShockGame.Plasmid'), __NFUN_129__(Player.IsPlasmidAvailable(ItemClass.Name))))
		{
		}
		Pattern.Slot_1 = 'NewPlasmidAcquired';
		FactDatabase.AssertFact(Pattern, false, true);
		goto J0x1A3;
		// End:0x178
		if(__NFUN_258__(ItemClass, Class'ShockGame.CraftingComponent'))
		{
			Pattern.Slot_1 = 'PickedUpCraftingComponent';
			FactDatabase.AssertFact(Pattern, false, true);
			AssertCompleteFormulas(Player);
		}
		goto J0x1A3;
		// End:0x1A3
		if(__NFUN_258__(ItemClass, Class'ShockGame.CraftingFormula'))
		{
			AssertCompleteFormulas(Player);
			Pattern.Slot_1 = 'PlayerPickedUpInventory';
			Pattern.Slot_2 = "?";
			FactDatabase.RetractFactNotAssertedThisFrame(Pattern, true);
			Pattern.Slot_2 = string(ItemClass.Name);
		}
		FactDatabase.AssertFact(Pattern, false, true);
	}
	return;
	@NULL
	Item
	Item
	@NULL
}

function PlayerUse(ICanBeUsed used)
{
	local FactPattern Pattern;

	Pattern.Slot_1 = 'LastPlayerUse';
	Pattern.Slot_2 = "?";
	FactDatabase.RetractFact(Pattern, true);
	Pattern.Slot_2 = string(used.Class.Name);
	FactDatabase.AssertFact(Pattern, false, true);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x19E
	/*@Error*/
	Pattern.Slot_1 = 'SearchedAContainer';
	Pattern.Slot_2 = "?";
	FactDatabase.RetractFact(Pattern, true);
	Pattern.Slot_2 = string(Actor(used).Label);
	FactDatabase.AssertFact(Pattern, false, true);
	return;
	@NULL
	Item
	Item
	@NULL
}

function PlayerMaxHealthUpdated(ShockPlayer Player)
{
	PlayerHealthChanged(Player);
	return;
	@NULL
}

function PlayerAddHealth(ShockPlayer Player)
{
	PlayerHealthChanged(Player);
	return;
	@NULL
}

function PlayerRemoveHealth(ShockPlayer Player)
{
	PlayerHealthChanged(Player);
	return;
	@NULL
}

function PlayerMaxBioAmmoUpdated(ShockPlayer Player)
{
	PlayerBioAmmoChanged(Player);
	return;
	@NULL
}

function PlayerAddBioAmmo(ShockPlayer Player)
{
	PlayerBioAmmoChanged(Player);
	return;
	@NULL
}

function PlayerRemoveBioAmmo(ShockPlayer Player)
{
	PlayerBioAmmoChanged(Player);
	return;
	@NULL
}

function PlayerCrouched(ShockPlayer Player)
{
	local FactPattern Pattern;

	Pattern.Slot_1 = 'IsNotCrouching';
	FactDatabase.RetractFact(Pattern, true);
	Pattern.Slot_1 = 'IsCrouching';
	FactDatabase.AssertFact(Pattern, false, true);
	return;
	@NULL
	Item
	Item
	@NULL
}

function PlayerUnCrouched(ShockPlayer Player)
{
	local FactPattern Pattern;

	Pattern.Slot_1 = 'IsCrouching';
	FactDatabase.RetractFact(Pattern, true);
	Pattern.Slot_1 = 'IsNotCrouching';
	FactDatabase.AssertFact(Pattern, false, true);
	return;
	@NULL
	Item
	Item
	@NULL
}

function PlayerHasSpentEPPs(ShockPlayer Player, int Amount)
{
	local FactPattern Pattern;

	Pattern.Slot_1 = 'PlayerHasSpentEPPs';
	FactDatabase.AssertFact(Pattern, false, true);
	return;
	@NULL
	Item
	Item
	@NULL
}

function LookedAtMap()
{
	local FactPattern Pattern;

	Pattern.Slot_1 = 'LookedAtMap';
	FactDatabase.AssertFact(Pattern, false, true);
	return;
	@NULL
	Item
	Item
	@NULL
}

function LookedAtHelp()
{
	local FactPattern Pattern;

	Pattern.Slot_1 = 'LookedAtHelp';
	FactDatabase.AssertFact(Pattern, false, true);
	return;
	@NULL
	Item
	Item
	@NULL
}

function LookedAtLogs()
{
	local FactPattern Pattern;

	Pattern.Slot_1 = 'LookedAtLogs';
	FactDatabase.AssertFact(Pattern, false, true);
	return;
	@NULL
	Item
	Item
	@NULL
}

function LookedAtRadios()
{
	local FactPattern Pattern;

	Pattern.Slot_1 = 'LookedAtRadios';
	FactDatabase.AssertFact(Pattern, false, true);
	return;
	@NULL
	Item
	Item
	@NULL
}

function LookedAtQuests()
{
	local FactPattern Pattern;

	Pattern.Slot_1 = 'LookedAtQuests';
	FactDatabase.AssertFact(Pattern, false, true);
	return;
	@NULL
	Item
	Item
	@NULL
}

function SavedGame()
{
	local FactPattern Pattern;

	Pattern.Slot_1 = 'SavedGame';
	FactDatabase.AssertFact(Pattern, false, true);
	return;
	@NULL
	Item
	Item
	@NULL
}

function PickedUpUnplayedLog()
{
	local FactPattern Pattern;

	Pattern.Slot_1 = 'UnreadLogs';
	FactDatabase.AssertFact(Pattern, false, true);
	return;
	@NULL
	Item
	Item
	@NULL
}

function PlayedAllLogs()
{
	local FactPattern Pattern;

	Pattern.Slot_1 = 'UnreadLogs';
	FactDatabase.RetractFact(Pattern, true);
	return;
	@NULL
	Item
	Item
	@NULL
}

function HandsModeChanged(name NewMode)
{
	local FactPattern Pattern;

	// End:0x83
	if(__NFUN_254__(NewMode, 'Weapon'))
	{
		Pattern.Slot_1 = 'InPlasmidMode';
		FactDatabase.RetractFact(Pattern, true);
		Pattern.Slot_1 = 'InWeaponMode';
		goto J0x103;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x103
		/*@Error*/
		Pattern.Slot_1 = 'InWeaponMode';
	}
	FactDatabase.RetractFact(Pattern, true);
	Pattern.Slot_1 = 'InPlasmidMode';
	FactDatabase.AssertFact(Pattern, false, true);
	return;
	@NULL
	Item
	Item
	@NULL
}

function FinishedHacking(ICanBeHacked HackedObject, string HackResult)
{
	local FactPattern Pattern;

	Pattern.Slot_1 = 'HackedMachine';
	Pattern.Slot_2 = "?";
	Pattern.Slot_3 = "?";
	FactDatabase.RetractFact(Pattern, true);
	Pattern.Slot_2 = string(HackedObject.Class.Name);
	Pattern.Slot_3 = HackResult;
	FactDatabase.AssertFact(Pattern, false, true);
	return;
	@NULL
	Item
	Item
	@NULL
}

function SavedGatherer()
{
	local FactPattern Pattern;

	Pattern.Slot_1 = 'SavedGatherer';
	FactDatabase.AssertFact(Pattern, false, true);
	return;
	@NULL
	Item
	Item
	@NULL
}

function AggressorGoingToHealthStation(ShockPawn AI)
{
	local FactPattern Pattern;

	Pattern.Slot_1 = 'AggressorGoingToHealthStation';
	Pattern.Slot_2 = "?";
	FactDatabase.RetractFact(Pattern, true);
	Pattern.Slot_2 = string(AI.Label);
	FactDatabase.AssertFact(Pattern, false, true);
	return;
	@NULL
	Item
	Item
	@NULL
}

function AggressorKilledGoingToHealthStation()
{
	local FactPattern Pattern;

	Pattern.Slot_1 = 'AggressorKilledGoingToHealthStation';
	FactDatabase.AssertFact(Pattern, false, true);
	return;
	@NULL
	Item
	Item
	@NULL
}

function AggressorHealedAtHealthStation()
{
	local FactPattern Pattern;

	Pattern.Slot_1 = 'AggressorHealedAtHealthStation';
	FactDatabase.AssertFact(Pattern, false, true);
	return;
	@NULL
	Item
	Item
	@NULL
}

function AggressorPoisonedAtHealthStation()
{
	local FactPattern Pattern;

	Pattern.Slot_1 = 'AggressorPoisonedAtHealthStation';
	FactDatabase.AssertFact(Pattern, false, true);
	return;
	@NULL
	Item
	Item
	@NULL
}

function ZoomModeChanged(bool Zoom)
{
	local FactPattern Pattern;

	// End:0x9B
	if(Zoom)
	{
		Pattern.Slot_1 = 'NotInZoomMode';
		FactDatabase.RetractFact(Pattern, true);
		Pattern.Slot_1 = 'InZoomMode';
		FactDatabase.AssertFact(Pattern, false, true);
		goto J0x126;
		Pattern.Slot_1 = 'InZoomMode';
		FactDatabase.RetractFact(Pattern, true);
	}
	Pattern.Slot_1 = 'NotInZoomMode';
	FactDatabase.AssertFact(Pattern, false, true);
	return;
	@NULL
	Item
	Item
	@NULL
}

function CanUseVitaChamber(bool CanUse)
{
	local FactPattern Pattern;

	// End:0x9B
	if(CanUse)
	{
		Pattern.Slot_1 = 'VitaChamberOff';
		FactDatabase.RetractFact(Pattern, true);
		Pattern.Slot_1 = 'VitaChamberOn';
		FactDatabase.AssertFact(Pattern, false, true);
		goto J0x126;
		Pattern.Slot_1 = 'VitaChamberOn';
		FactDatabase.RetractFact(Pattern, true);
	}
	Pattern.Slot_1 = 'VitaChamberOff';
	FactDatabase.AssertFact(Pattern, false, true);
	return;
	@NULL
	Item
	Item
	@NULL
}

function PlayerUsedTelekineses(float HeldTime)
{
	local FactPattern Pattern;

	// End:0xC2
	if(__NFUN_177__(HeldTime, TelekinesisFlubTime))
	{
		Pattern.Slot_1 = 'TelekinesisUsed';
		Pattern.Slot_2 = "Bad";
		FactDatabase.RetractFact(Pattern, true);
		Pattern.Slot_2 = "Good";
		FactDatabase.AssertFact(Pattern, false, true);
		goto J0x16A;
		Pattern.Slot_1 = 'TelekinesisUsed';
		Pattern.Slot_2 = "Good";
		FactDatabase.RetractFact(Pattern, true);
	}
	Pattern.Slot_2 = "Bad";
	FactDatabase.AssertFact(Pattern, false, true);
	return;
	@NULL
	Item
	Item
	@NULL
}

function PlayerChangedAmmo()
{
	local FactPattern Pattern;

	Pattern.Slot_1 = 'ChangedAmmo';
	FactDatabase.AssertFact(Pattern, false, true);
	return;
	@NULL
	Item
	Item
	@NULL
}

function PlasmidTrackSlotUnlocked(Plasmid.ePlasmidTrack Track)
{
	local FactPattern Pattern;

	Pattern.Slot_1 = 'HasEmptyPlasmidSlot';
	FactDatabase.AssertFact(Pattern, false, true);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xA0
	/*@Error*/
	Pattern.Slot_1 = 'HasEmptyGeneTonicSlot';
	FactDatabase.AssertFact(Pattern, false, true);
	return;
	@NULL
	Item
	Item
	@NULL
}

function PlasmidTrackSlotLocked(ShockPlayer Player, Plasmid.ePlasmidTrack Track, int NumSlots)
{
	local FactPattern Pattern;
	local int GeneTonicSlots, GeneTonicEquipped, ActiveSlots, ActiveEquipped, TotalSlots, TotalEquipped;

	TotalSlots = Player.NumUnlockedTrackSlots(0);
	TotalEquipped = Player.NumEquippedPlasmids(0);
	// End:0xA2
	if(__NFUN_154__(TotalEquipped, TotalSlots))
	{
		Pattern.Slot_1 = 'HasEmptyPlasmidSlot';
		FactDatabase.RetractFact(Pattern, true);
		ActiveSlots = Player.NumUnlockedTrackSlots(1);
		ActiveEquipped = Player.NumEquippedPlasmids(1);
	}
	GeneTonicSlots = __NFUN_147__(TotalSlots, ActiveSlots);
	GeneTonicEquipped = __NFUN_147__(TotalEquipped, ActiveEquipped);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x180
	/*@Error*/
	Pattern.Slot_1 = 'HasEmptyGeneTonicSlot';
	FactDatabase.RetractFact(Pattern, true);
	return;
	@NULL
	Item
	Item
	@NULL
}

function OpenWeaponMenu()
{
	local FactPattern Pattern;

	Pattern.Slot_1 = 'WeaponMenuOpen';
	FactDatabase.AssertFact(Pattern, false, true);
	return;
	@NULL
	Item
	Item
	@NULL
}

function CloseWeaponMenu()
{
	local FactPattern Pattern;

	Pattern.Slot_1 = 'WeaponMenuOpen';
	FactDatabase.RetractFact(Pattern, true);
	return;
	@NULL
	Item
	Item
	@NULL
}

function OpenPCWeaponSelectionMenu()
{
	local FactPattern Pattern;

	Pattern.Slot_1 = 'WeaponMenuOpen';
	FactDatabase.AssertFact(Pattern, false, true);
	Pattern.Slot_1 = 'AbilityMenuOpen';
	FactDatabase.AssertFact(Pattern, false, true);
	return;
	@NULL
	Item
	Item
	@NULL
}

function ClosePCWeaponSelectionMenu()
{
	local FactPattern Pattern;

	return;
}

function OpenAbilityMenu(ShockPlayer Player)
{
	local FactPattern Pattern;

	Pattern.Slot_1 = 'AbilityMenuOpen';
	FactDatabase.AssertFact(Pattern, false, true);
	// End:0xAE
	if(__NFUN_154__(Player.NumEquippedPlasmids(1), 0))
	{
		Pattern.Slot_1 = 'NoAbilitiesEquipped';
		FactDatabase.AssertFact(Pattern, false, true);
		goto J0xF3;
		Pattern.Slot_1 = 'NoAbilitiesEquipped';
		FactDatabase.RetractFact(Pattern, true);
	}
	return;
	@NULL
	Item
	Item
	@NULL
}

function CloseAbilityMenu()
{
	local FactPattern Pattern;

	Pattern.Slot_1 = 'AbilityMenuOpen';
	FactDatabase.RetractFact(Pattern, true);
	return;
	@NULL
	Item
	Item
	@NULL
}

function GPSUsed()
{
	local FactPattern Pattern;

	Pattern.Slot_1 = 'DirectionalArrowUsed';
	FactDatabase.AssertFact(Pattern, false, true);
	return;
	@NULL
	Item
	Item
	@NULL
}

function GPSCleared()
{
	local FactPattern Pattern;

	Pattern.Slot_1 = 'DirectionalArrowUsed';
	FactDatabase.RetractFact(Pattern, true);
	return;
	@NULL
	Item
	Item
	@NULL
}

function WeakButRich(string Category)
{
	local FactPattern Pattern;

	Pattern.Slot_1 = 'WeakButRich';
	Pattern.Slot_2 = Category;
	FactDatabase.AssertFact(Pattern, false, true);
	return;
	@NULL
	Item
	Item
	@NULL
}

function NotWeakButRich(string Category)
{
	local FactPattern Pattern;

	Pattern.Slot_1 = 'WeakButRich';
	Pattern.Slot_2 = Category;
	FactDatabase.RetractFact(Pattern, true);
	return;
	@NULL
	Item
	Item
	@NULL
}

function ChangedMapUIRegion(name MapUIRegion)
{
	local FactPattern Pattern;

	Pattern.Slot_1 = 'PlayerChangedMapUIRegion';
	Pattern.Slot_2 = "?";
	FactDatabase.RetractFact(Pattern, true);
	Pattern.Slot_1 = 'PlayerChangedMapUIRegion';
	Pattern.Slot_2 = string(MapUIRegion);
	FactDatabase.AssertFact(Pattern, false, true);
	return;
	@NULL
	Item
	Item
	@NULL
}

function DryFire()
{
	local FactPattern Pattern;

	Pattern.Slot_1 = 'DryFiredWeapon';
	FactDatabase.AssertFact(Pattern, false, true);
	return;
	@NULL
	Item
	Item
	@NULL
}

function PlayerLookingAt(ICanBeFocused Focus)
{
	local FactPattern Pattern;

	Pattern.Slot_1 = 'LookingAt';
	Pattern.Slot_2 = "?";
	FactDatabase.RetractFact(Pattern, true);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xF8
	/*@Error*/
	Pattern.Slot_1 = 'LookingAt';
	Pattern.Slot_2 = string(Focus.Class.Name);
	FactDatabase.AssertFact(Pattern, false, true);
	return;
	@NULL
	Item
	Item
	@NULL
}

function PlayerLeaned()
{
	local FactPattern Pattern;

	Pattern.Slot_1 = 'PlayerLeaned';
	FactDatabase.AssertFact(Pattern, false, true);
	return;
	@NULL
	Item
	Item
	@NULL
}

function PictureTaken(TrainingMessageManager.EPhotoRejectReason RejectReason)
{
	local FactPattern Pattern;

	Pattern.Slot_1 = 'PictureTaken';
	switch(RejectReason)
	{
		// End:0x5B
		case 0:
			Pattern.Slot_2 = "Success";
			// End:0x13F
			break;
			// End:0x86
			case 2:
				Pattern.Slot_2 = "Hacked";
			// End:0x13F
			break;
			// End:0xB4
			case 1:
				Pattern.Slot_2 = "Offscreen";
				// End:0x13F
				break;
				// End:0xE1
				case 4:
					Pattern.Slot_2 = "LowScore";
				// End:0x13F
				break;
				// End:0x10E
				case 5:
					Pattern.Slot_2 = "Complete";
				// End:0x13F
				break;
				// End:0x13C
				case 3:
					Pattern.Slot_2 = "NoSubject";
				// End:0x13F
				break;
				// End:0xFFFF
				default:
					FactDatabase.AssertFact(Pattern, false, true);
					return;
					break;
			}/* !MISMATCHING REMOVE, tried Switch got Type:Case Position:0x05E! */
			@NULL
			Item
			Item
		@NULL
	// Failed to format remaining nests!:System.ArgumentOutOfRangeException: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
   at System.Collections.Generic.List`1.get_Item(Int32 index)
   at UELib.Core.UStruct.UByteCodeDecompiler.DecompileNests(Boolean outputAllRemainingNests) in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 849
   at UELib.Core.UStruct.UByteCodeDecompiler.Decompile() in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 724
	// 1 & Type:Switch Position:0x13F
}

function BefriendUsed(string Result)
{
	local FactPattern Pattern;

	Pattern.Slot_1 = 'Befriend';
	Pattern.Slot_2 = "?";
	FactDatabase.RetractFact(Pattern, true);
	Pattern.Slot_2 = Result;
	FactDatabase.AssertFact(Pattern, false, true);
	return;
	@NULL
	Item
	Item
	@NULL
}

function SecurityBeaconUsed(float BeaconTimeLeft)
{
	local FactPattern Pattern;

	Pattern.Slot_1 = 'SecurityBeacon';
	Pattern.Slot_2 = "?";
	FactDatabase.RetractFact(Pattern, true);
	Pattern.Slot_2 = string(BeaconTimeLeft);
	FactDatabase.AssertFact(Pattern, false, true);
	return;
	@NULL
	Item
	Item
	@NULL
}

function ChangedDifficulty(ShockPlayer Player)
{
	local FactPattern Pattern;

	Pattern.Slot_1 = 'Difficulty';
	Pattern.Slot_2 = "?";
	FactDatabase.RetractFact(Pattern, true);
	switch(Player.CurrentDifficultySetting)
	{
		// End:0xA4
		case 2:
			Pattern.Slot_2 = "Hard";
			// End:0xFB
			break;
			// End:0xCF
			case 1:
				Pattern.Slot_2 = "Normal";
				// End:0xFB
				break;
				// End:0xF8
				case 0:
					Pattern.Slot_2 = "Easy";
				// End:0xFB
				break;
				// End:0xFFFF
				default:
					FactDatabase.AssertFact(Pattern, false, true);
					return;
					break;
			}/* !MISMATCHING REMOVE, tried Switch got Type:Case Position:0x070! */
			@NULL
		Item
		Item
		@NULL
	// Failed to format remaining nests!:System.ArgumentOutOfRangeException: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
   at System.Collections.Generic.List`1.get_Item(Int32 index)
   at UELib.Core.UStruct.UByteCodeDecompiler.DecompileNests(Boolean outputAllRemainingNests) in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 849
   at UELib.Core.UStruct.UByteCodeDecompiler.Decompile() in C:\Users\Jack\Documents\BioshockHavok\Unreal-Library-master\src\ByteCodeDecompiler.cs:line 724
	// 1 & Type:Switch Position:0x0FB
}

function PlayerInDoor(ShockDoor Door)
{
	local FactPattern Pattern;

	Pattern.Slot_1 = 'ApproachedLockedDoor';
	// End:0xD5
	if(__NFUN_130__(__NFUN_130__(__NFUN_119__(Door, none), Door.IsLocked()), Door.IsOpenable()))
	{
		FactDatabase.AssertFact(Pattern, false, true);
		Pattern.Slot_1 = 'NotApproachedLockedDoor';
		FactDatabase.RetractFact(Pattern, true);
		goto J0x13C;
		FactDatabase.RetractFact(Pattern, true);
		Pattern.Slot_1 = 'NotApproachedLockedDoor';
		FactDatabase.AssertFact(Pattern, false, true);
	}
	return;
	@NULL
	Item
	Item
	@NULL
}

function EnrageFailure(BaseShockAI AI)
{
	local FactPattern Pattern;

	Pattern.Slot_1 = 'EnrageFailure';
	Pattern.Slot_2 = "?";
	FactDatabase.RetractFact(Pattern, true);
	// End:0xA8
	if(AI.__NFUN_303__('Protector'))
	{
		Pattern.Slot_2 = "Protector";
		goto J0xCE;
		Pattern.Slot_2 = "Aggressor";
		FactDatabase.AssertFact(Pattern, false, true);
	}
	return;
	@NULL
	Item
	Item
	@NULL
}

function EnrageSuccess(BaseShockAI AI)
{
	local FactPattern Pattern;

	Pattern.Slot_1 = 'EnrageFailure';
	Pattern.Slot_2 = "?";
	FactDatabase.RetractFact(Pattern, true);
	return;
	@NULL
	Item
	Item
	@NULL
}

function ResearchedTrack(ShockPlayer Player, name ResearchTrack)
{
	local FactPattern Pattern;

	Pattern.Slot_1 = 'Researched';
	Pattern.Slot_2 = string(ResearchTrack);
	// End:0xDC
	if(Player.IsResearchComplete(ResearchTrack))
	{
		Pattern.Slot_3 = "?";
		FactDatabase.RetractFact(Pattern, true);
		Pattern.Slot_3 = "ResearchComplete";
		goto J0x104;
		Pattern.Slot_3 = "Researching";
		FactDatabase.AssertFact(Pattern, true, true);
		return;
		@NULL
		Item
		Item
	}
	@NULL
}

function IneffectiveElectricBolt()
{
	local FactPattern Pattern;

	Pattern.Slot_1 = 'Resistant';
	Pattern.Slot_2 = "ElectricBolt";
	FactDatabase.AssertFact(Pattern, false, true);
	return;
	@NULL
	Item
	Item
	@NULL
}

function IneffectiveIcicleAssault()
{
	local FactPattern Pattern;

	Pattern.Slot_1 = 'Resistant';
	Pattern.Slot_2 = "IcicleAssault";
	FactDatabase.AssertFact(Pattern, false, true);
	return;
	@NULL
	Item
	Item
	@NULL
}

defaultproperties
{
	TrainingMessages[0]=(Name="Movement",Text="Use <img src=Button_LS> to MOVE.",TextPC="Press <Mapping=MoveForward>, <Mapping=MoveBackward>, <Mapping=StrafeLeft> and <Mapping=StrafeRight>  to MOVE.",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=true,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[1]=(Name="Crouch",Text="Click <img src=Button_LS> to CROUCH.",TextPC="Press <Mapping=Duck> to CROUCH",HelpTag="None",QueuePriority=4,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=true,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[2]=(Name="UnCrouch",Text="Click <img src=Button_LS> to STAND UP.",TextPC="Press <Mapping=Duck> to STAND UP.",HelpTag="None",QueuePriority=0,RepeatDelay=60.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=true,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[3]=(Name="UnCrouch_2",Text="Click <img src=Button_LS> to STAND UP.",TextPC="Press <Mapping=Duck> to STAND UP.",HelpTag="None",QueuePriority=0,RepeatDelay=300.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=true,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[4]=(Name="Jump",Text="Press <img src=Button_Y> to JUMP.",TextPC="Press <Mapping=Jump> to JUMP.",HelpTag="None",QueuePriority=4,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=true,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[5]=(Name="Look",Text="Use <img src=Button_RS> to LOOK around.",TextPC="Use the MOUSE to LOOK around.",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=true,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[6]=(Name="CrouchIncineration",Text="Click <img src=Button_LS> to CROUCH and crawl through small passages.",TextPC="Press <Mapping=Duck> to CROUCH and crawl through small passages.",HelpTag="None",QueuePriority=0,RepeatDelay=60.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[7]=(Name="SecurityIntroSeen",Text="Hide from the SECURITY CAMERA!",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=true,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[8]=(Name="SecurityIntroLost",Text="You have hidden from the SECURITY CAMERA.",TextPC="",HelpTag="None",QueuePriority=4,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[9]=(Name="SecurityIntroAlarm",Text="ALARM activated!",TextPC="",HelpTag="None",QueuePriority=4,RepeatDelay=0.0000000,ShowInCombat=true,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[10]=(Name="SecurityCancel",Text="Cancel the alarm at a BOT SHUTDOWN MACHINE.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=true,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[11]=(Name="FireWeapon",Text="Pull <img src=Button_RT> to swing your WRENCH.",TextPC="Press <Mapping=Fire> to swing your WRENCH.",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=true,IsModal=false,NotAdaptive=true,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[12]=(Name="WeaponsCycle",Text="Press <img src=Button_RB> for NEXT WEAPON.",TextPC="Use <Mapping=NextWeaponOrPlasmid> to select NEXT WEAPON.",HelpTag="None",QueuePriority=2,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=true,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[13]=(Name="WeaponsRadial",Text="Hold <img src=Button_RB> to CHOOSE WEAPON from menu.",TextPC="Press <Mapping=LaunchPCWeaponSelection> to CHOOSE WEAPON from menu.",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=true,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[14]=(Name="Reload",Text="Press <img src=Button_X> to LOAD your weapon.",TextPC="Press <Mapping=Reload> to LOAD your weapon.",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=true,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[15]=(Name="OtherAmmo",Text="Use <img src=Button_DPad> to CHANGE AMMO when in WEAPON MODE.",TextPC="Use <Mapping=AmmoSelectionUp> and <Mapping=AmmoSelectionDown> to CHANGE AMMO when in WEAPON MODE.",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=true,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[16]=(Name="UseZoom",Text="Click <img src=Button_RS> to ZOOM.",TextPC="Press <Mapping=ZoomCycle> to ZOOM.",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=true,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[17]=(Name="UnZoom",Text="Click <img src=Button_RS> to EXIT ZOOM.",TextPC="Press <Mapping=ZoomCycle> to EXIT ZOOM.",HelpTag="None",QueuePriority=0,RepeatDelay=60.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[18]=(Name="WeaponMode",Text="Press <img src=Button_RB> to EQUIP WEAPON.",TextPC="Press <Mapping=SwitchWeaponsOrPlasmids> to EQUIP WEAPON.",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=true,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[19]=(Name="DryFire",Text="OUT of AMMO (press <img src=Button_RB> for NEXT WEAPON)",TextPC="OUT of AMMO (use <Mapping=NextWeaponOrPlasmid> to select NEXT WEAPON)",HelpTag="None",QueuePriority=4,RepeatDelay=0.0000000,ShowInCombat=true,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[20]=(Name="ChangeAmmo",Text="\\n\\nYou got SPECIAL AMMO!\\n\\nPress <img src=Button_DPad> to CHANGE AMMO type.\\n\\nPick the right ammo for the right enemy!",TextPC="\\n\\nYou got SPECIAL AMMO!\\n\\nUse <Mapping=AmmoSelectionUp> and <Mapping=AmmoSelectionDown> to CHANGE AMMO type.\\n\\nPick the right ammo for the right enemy!",HelpTag="None",QueuePriority=4,RepeatDelay=288000.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=true,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[21]=(Name="GrenadePickup",Text="This GRENADE can only be fired from a GRENADE LAUNCHER.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[22]=(Name="GotNewAmmoPistolArmorPiercing",Text="Use Armor Piercing Pistol ammo against armored targets.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=60.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[23]=(Name="GotNewAmmoPistolAP",Text="Use Antipersonnel Pistol ammo against unarmored targets.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=60.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[24]=(Name="GotNewAmmoShotgunIonicBuck",Text="Use Electric Buck Shotgun ammo\\nagainst targets vulnerable to electricity.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=60.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[25]=(Name="GotNewAmmoShotgunHEBuck",Text="Use Exploding Buck Shotgun ammo to damage multiple targets.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=60.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[26]=(Name="GotNewAmmoCrossbowTrapBolt",Text="Use Trap Bolt Crossbow ammo to set electrified tripwires.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=60.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[27]=(Name="GotNewAmmoCrossbowSHBolt",Text="Use Incendiary Crossbow ammo against targets vulnerable to fire.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=60.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[28]=(Name="GotNewAmmoGrenRPG",Text="Use Heat-Seeking Grenade ammo against moving targets.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=60.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[29]=(Name="GotNewAmmoGrenSticky",Text="Use Proximity Mine Grenade ammo to mine an area.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=60.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[30]=(Name="GotNewAmmoChemLN",Text="Use Liquid Nitrogen Chemical Thrower ammo\\nagainst targets vulnerable to cold.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=60.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[31]=(Name="GotNewAmmoChemIonicGel",Text="Use Electric Gel Chemical Thrower ammo\\nagainst targets vulnerable to electricity.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=60.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[32]=(Name="GotNewAmmoMGFrozenBullet",Text="Use Antipersonnel Machine Gun ammo against unarmored targets.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=60.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[33]=(Name="GotNewAmmoMGArmorPiercing",Text="Use Armor Piercing Machine Gun ammo against armored targets.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=60.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[34]=(Name="ElectroShock_1",Text="ELECTRO bolt STUNS but does NO DAMAGE.",TextPC="",HelpTag="None",QueuePriority=4,RepeatDelay=0.0000000,ShowInCombat=true,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[35]=(Name="WaterShock",Text="Hit WATER with ELECTRO bolt to FRY anyone in it!",TextPC="",HelpTag="None",QueuePriority=4,RepeatDelay=0.0000000,ShowInCombat=true,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[36]=(Name="ElectroShock_2",Text="Equip and fire weapon (hold <img src=Button_RT>) to kill a STUNNED enemy.",TextPC="Equip and fire weapon (press <Mapping=Fire>) to kill a STUNNED enemy.",HelpTag="None",QueuePriority=4,RepeatDelay=0.0000000,ShowInCombat=true,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=true,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[37]=(Name="ElectroShock_3",Text="Equip and fire weapon (hold <img src=Button_RT>) to kill a STUNNED enemy.",TextPC="Equip and fire weapon (press <Mapping=Fire>) to kill a STUNNED enemy.",HelpTag="None",QueuePriority=4,RepeatDelay=30.0000000,ShowInCombat=true,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[38]=(Name="FrozenIntro",Text="SHATTER enemies QUICKLY before they THAW.",TextPC="",HelpTag="None",QueuePriority=4,RepeatDelay=0.0000000,ShowInCombat=true,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=true,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[39]=(Name="CryoShards_3",Text="Target already FROZEN.",TextPC="",HelpTag="None",QueuePriority=4,RepeatDelay=60.0000000,ShowInCombat=true,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[40]=(Name="CryoShards_4",Text="FROZEN enemies can be easily killed, but they SHATTER leaving no loot.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=true,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[41]=(Name="Incinerate_2",Text="Target already ON FIRE.",TextPC="",HelpTag="None",QueuePriority=4,RepeatDelay=0.0000000,ShowInCombat=true,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[42]=(Name="Berserk_1",Text="DON'T enrage SOLITARY enemies.",TextPC="",HelpTag="None",QueuePriority=4,RepeatDelay=0.0000000,ShowInCombat=true,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[43]=(Name="Berserk_2",Text="Target already ENRAGED.",TextPC="",HelpTag="None",QueuePriority=4,RepeatDelay=0.0000000,ShowInCombat=true,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[44]=(Name="onetwopunch_1",Text="Press <img src=Button_RB> to equip a WEAPON.",TextPC="Press <Mapping=SwitchWeaponsOrPlasmids> to equip a WEAPON.",HelpTag="None",QueuePriority=4,RepeatDelay=0.0000000,ShowInCombat=true,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=true,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[45]=(Name="onetwopunch_2",Text="Pull <img src=Button_RT> to kill the STUNNED enemy.",TextPC="Press <Mapping=Fire> to kill the STUNNED enemy.",HelpTag="None",QueuePriority=4,RepeatDelay=0.0000000,ShowInCombat=true,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=true,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[46]=(Name="onetwopunch_4",Text="Pull <img src=Button_LT> to STUN the enemy.",TextPC="Press <Mapping=Fire> to STUN the enemy.",HelpTag="None",QueuePriority=4,RepeatDelay=0.0000000,ShowInCombat=true,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=true,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[47]=(Name="GetBetterPlasmidsMessage",Text="If your plasmids are losing effectiveness against tougher enemies,\\nfind the improved versions of those Plasmids.",TextPC="",HelpTag="None",QueuePriority=4,RepeatDelay=60.0000000,ShowInCombat=true,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[48]=(Name="PlasmidsRadial",Text="Hold <img src=Button_LB> to CHOOSE PLASMID from menu.",TextPC="Press <Mapping=LaunchPCWeaponSelection> to CHOOSE PLASMID from menu.",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=true,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[49]=(Name="FirePlasmid",Text="Pull <img src=Button_LT> to use PLASMID.",TextPC="Press <Mapping=Fire> to use PLASMID.",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=true,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[50]=(Name="PlasmidMode",Text="Press <img src=Button_LB> to EQUIP PLASMID.",TextPC="Press <Mapping=SwitchWeaponsOrPlasmids> to EQUIP PLASMID.",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=true,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[51]=(Name="PlasmidCycle",Text="Press <img src=Button_LB> for NEXT PLASMID.",TextPC="Use <Mapping=NextWeaponOrPlasmid> to select NEXT PLASMID.",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=true,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[52]=(Name="PlasmidNONE",Text="NO PLASMIDS to equip.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=true,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[53]=(Name="TelekinesisPlasmidIntro",Text="\\n\\nHold <img src=Button_LT> to GRAB objects.\\n\\nRelease <img src=Button_LT> to THROW them or press <img src=Button_X> to DROP.\\n\\nHold <img src=Button_LT> to CATCH grenades or tennis balls.",TextPC="\\n\\nHold <Mapping=Fire> to GRAB objects.\\n\\nRelease <Mapping=Fire>\\nto THROW them or press <Mapping=Hack> to DROP.\\n\\nHold <Mapping=Fire> to CATCH grenades or tennis balls.",HelpTag="None",QueuePriority=4,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=true,NotAdaptive=true,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[54]=(Name="TeleportationPlasmidIntro",Text="Hold <img src=Button_LT> to MARK your location.\\n\\nPress <img src=Button_LT> to RETURN to it.",TextPC="Hold <Mapping=Fire> to MARK your location.\\n\\nPress <Mapping=Fire> to RETURN to it.",HelpTag="None",QueuePriority=4,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=true,NotAdaptive=true,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[55]=(Name="UseAllSlots",Text="WARNING: you have EMPTY Gene Tonic Slots.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[56]=(Name="UseAllPlasmidSlots",Text="WARNING: You have an EMPTY SLOT that you could put\\na PLASMID or GENE TONIC into.",TextPC="",HelpTag="None",QueuePriority=4,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[57]=(Name="SecurityBeaconMisuse",Text="The enemy is already tagged with SECURITY BULLSEYE.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=60.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[58]=(Name="SummonProtectorMisuseRedo",Text="This Big Daddy is already your friend.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=60.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[59]=(Name="SummonProtectorMisuseNot",Text="Befriend will only work on a Big Daddy.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=60.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[60]=(Name="HealthHyposFirst",Text="You got a FIRST AID kit. When hurt, press <img src=Button_B> to use it to HEAL.",TextPC="You got a FIRST AID kit. When hurt, press <Mapping=MedHypo> to use it to HEAL.",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=true,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=true,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[61]=(Name="HealthHypos",Text="Press <img src=Button_B> to use FIRST AID.",TextPC="Press <Mapping=MedHypo> to use FIRST AID.",HelpTag="None",QueuePriority=0,RepeatDelay=30.0000000,ShowInCombat=true,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[62]=(Name="FindHealthHypos",Text="You are WOUNDED! Find a FIRST AID kit.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=30.0000000,ShowInCombat=true,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[63]=(Name="FindHealthHypos_2",Text="You are WOUNDED! Find a HEALTH STATION.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=30.0000000,ShowInCombat=true,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[64]=(Name="DryFirePlasmid",Text="Out of EVE. Press <img src=Button_RB> to EQUIP WEAPON.",TextPC="Out of EVE. Press <Mapping=SwitchWeaponsOrPlasmids> to EQUIP WEAPON.",HelpTag="None",QueuePriority=4,RepeatDelay=30.0000000,ShowInCombat=true,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[65]=(Name="cigarettes",Text="HEALTH LOST but EVE GAINED from smoking.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[66]=(Name="Twinkie",Text="HEALTH GAINED from cake.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[67]=(Name="chips",Text="HEALTH GAINED from chips.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[68]=(Name="Booze",Text="HEALTH GAINED but EVE LOST from drinking.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[69]=(Name="Coffee",Text="EVE GAINED from coffee.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[70]=(Name="Powerbar",Text="HEALTH and EVE GAINED from Pep Bar.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[71]=(Name="bandages",Text="HEALTH GAINED from bandages.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[72]=(Name="SearchContainers",Text="SEARCH containers for LOOT.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=true,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[73]=(Name="SearchBodies",Text="SEARCH corpses for LOOT.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=true,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[74]=(Name="AutoHackTool",Text="You got an AUTO HACK TOOL. Use it to HACK FOR FREE!",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=true,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[75]=(Name="SpendMoney",Text="Spend your MONEY at a VENDING station.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[76]=(Name="SpendMoneyHealth",Text="You are low on health but wealthy.\\nBuy some FIRST AID at a VENDING station.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=360.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[77]=(Name="SpendMoneyEVE",Text="You are low on EVE but wealthy.\\nBuy some EVE HYPOS at a VENDING station.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=360.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[78]=(Name="SpendMoneyAmmo",Text="You are low on AMMO but wealthy.\\nBuy some AMMO at a VENDING station.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=360.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[79]=(Name="SpendMoneyFilm",Text="You are low on FILM. Buy more FILM\\nat a VENDING station.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=240.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[80]=(Name="WeaponToPlasmid",Text="Switch between weapons and plasmids using <img src=Button_LB> and <img src=Button_RB>.",TextPC="Switch between weapons and plasmids using <Mapping=SwitchWeaponsOrPlasmids>.",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=true,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[81]=(Name="DontHurtFriends",Text="The machine you just damaged\\nis HACKED and FRIENDLY to you.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=60.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=true,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[82]=(Name="SpendADAM",Text="Spend ADAM for new POWERS at a GATHERER'S GARDEN!",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=60.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[83]=(Name="ExtraPresent",Text="The TEDDY BEAR is not EMPTY yet! Check it again.",TextPC="",HelpTag="None",QueuePriority=4,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=true,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[84]=(Name="GathererInvulnerable",Text="LITTLE SISTERS cannot be harvested while the BIG DADDY is alive.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[85]=(Name="GathererInvulnerable_2",Text="You can only RESCUE or HARVEST the LITTLE SISTER.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[86]=(Name="HarvestNoGatherers",Text="\\nYou have not RESCUED or HARVESTED\\nany LITTLE SISTERS on this deck.\\n\\nYou need ADAM from them to become\\nmore powerful.\\n\\nYou should NOT leave without getting more ADAM.",TextPC="",HelpTag="None",QueuePriority=4,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=true,NotAdaptive=true,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[87]=(Name="HarvestSomeGatherers",Text="\\nYou have not RESCUED or HARVESTED\\nall the LITTLE SISTERS on this deck.\\n\\nYou need ADAM from them to become\\nmore powerful.\\n\\nIt will be very DIFFICULT to survive\\nwithout getting more ADAM.",TextPC="",HelpTag="None",QueuePriority=4,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=true,NotAdaptive=true,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[88]=(Name="PresentLocationModal",Text="\\n\\n\\nTenenbaum wants to reward you.\\n\\nThe reward will be inside a TEDDY BEAR\\nat a GATHERER'S GARDEN.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=true,NotAdaptive=true,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[89]=(Name="PresentLocation",Text="Your reward will be inside a TEDDY BEAR at a GATHERER'S GARDEN.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[90]=(Name="FirstPresent",Text="\\n\\n\\nCongratulations!\\n\\nYou have found your first REWARD from Tenenbaum for SAVING LITTLE SISTERS.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=true,NotAdaptive=true,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[91]=(Name="ResStationDeath",Text="\\n\\n\\n\\nYou are being REVIVED at a Vita-Chamber.",TextPC="",HelpTag="None",QueuePriority=4,RepeatDelay=0.0000000,ShowInCombat=true,DoNotShowWhenHasFocus=false,IsModal=true,NotAdaptive=true,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[92]=(Name="AggHealthStation",Text="BEWARE! A splicer is trying to HEAL at a Health Station!",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=60.0000000,ShowInCombat=true,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[93]=(Name="TakePictures",Text="Don't forget to RESEARCH enemies with your CAMERA.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[94]=(Name="DeathResearch",Text="If you have trouble defeating an enemy, RESEARCH them to get combat bonuses.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=60.0000000,ShowInCombat=true,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[95]=(Name="EarlyCraftingTraining",Text="You got a Component! Collect components\\nto make things at a U-Invent.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=true,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[96]=(Name="CraftingReminder",Text="You have enough components to INVENT an item.\\nFind a U-Invent machine.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=300.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[97]=(Name="CraftMPR",Text="LAZARUS VECTOR now inventable.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[98]=(Name="CraftAPBullet",Text="ANTIPERSONNEL bullets now inventable.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[99]=(Name="CraftHEBuckshot",Text="HIGH EXPLOSIVE ammo now inventable.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[100]=(Name="CraftIonicGel",Text="IONIC GEL now inventable.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[101]=(Name="CraftTrapBolt",Text="TRAP BOLTS now inventable.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[102]=(Name="CraftRPGrenade",Text="ROCKET PROPELLED grenades now inventable.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[103]=(Name="CraftAPMachinegun",Text="ARMOR-PIERCING bullets now inventable.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[104]=(Name="CraftAutohack",Text="AUTO-HACK device now inventable.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[105]=(Name="CraftBloodlust",Text="BLOODLUST gene tonic now inventable.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[106]=(Name="CraftBoozehound",Text="BOOZEHOUND gene tonic now inventable.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[107]=(Name="CraftGenetichacker",Text="HACKER'S DELIGHT gene tonic now inventable.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[108]=(Name="SaveGame",Text="Press <img src=Button_Start> to SAVE your game.",TextPC="Press <Mapping=SecondaryAliasPauseGame> to SAVE your game.",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[109]=(Name="Map",Text="Press <img src=Button_Back> to check your MAP and get hints for your ACTIVE GOAL.",TextPC="Press <Mapping=ShowContextHelp> to check your MAP and get hints for your ACTIVE GOAL.",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=true,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[110]=(Name="Quests",Text="\\nYou got an OPTIONAL GOAL.\\n\\nYou can review your GOALS by pressing <img src=Button_Back>\\nand going to the GOALS tab.\\n\\nIf you want to pursue another GOAL,\\nyou can set it to be ACTIVE on the GOALS tab.",TextPC="\\nYou got an OPTIONAL GOAL.\\n\\nYou can review your GOALS by pressing <Mapping=ShowContextHelp>.\\n\\nIf you want to pursue another GOAL,\\nyou can set it to be ACTIVE on the GOALS tab.",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=true,NotAdaptive=true,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[111]=(Name="ChangeYourDifficulty",Text="Change your difficulty at any time in the OPTIONS.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[112]=(Name="QuestMultiPart",Text="\\nYou have a MULTI-PART GOAL.\\n\\nPress <img src=Button_Back> and go to the GOAL tab to see all parts of the goal and switch which one is ACTIVE.\\n\\nThe ARROW and MAP will\\nguide you to your ACTIVE goal.",TextPC="\\nYou have a MULTI-PART GOAL.\\n\\nPress <Mapping=ShowContextHelp> to see all parts of the goal and switch which one is ACTIVE.\\n\\nThe ARROW and MAP will\\nguide you to your ACTIVE goal.",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=true,NotAdaptive=true,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[113]=(Name="DoorIsLocked",Text="This door is locked from the other side.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[114]=(Name="HackingHelper",Text="You can override a hack with money, or use an auto-hack tool.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[115]=(Name="HintReminder",Text="Hold <img src=Button_Dpad_Right> to get a hint if you are stuck.",TextPC="Hold <Mapping=HintButtonAlias> to get a hint if you are stuck.",HelpTag="None",QueuePriority=1,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[116]=(Name="GetRadio",Text="Pick up the RADIO.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[117]=(Name="GetRadio_2",Text="Pick up the RADIO from the slot on the wall.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[118]=(Name="FindWrench",Text="FIND a WEAPON. Look near the broken door.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[119]=(Name="SmashDebris",Text="SMASH the DEBRIS blocking the door.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[120]=(Name="SmashDebris_2",Text="The BLOCKED DOOR is near where you picked up the WRENCH. Smash the DEBRIS to move on.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[121]=(Name="StayInPlasmidMode",Text="Press <img src=Button_LB> to EQUIP PLASMID.",TextPC="Press <Mapping=SwitchWeaponsOrPlasmids> to EQUIP PLASMID.",HelpTag="None",QueuePriority=4,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=true,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[122]=(Name="ZapDoor",Text="Use ELECTRO BOLT on the door SWITCH to OVERRIDE it.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[123]=(Name="FindEVEHypos",Text="EVE is used to power PLASMIDS. Find an Eve HYPO.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[124]=(Name="FindEVEHypos_2",Text="Find an EVE HYPO to power your PLASMID.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[125]=(Name="FindEVEPneumo",Text="EVE is used to power PLASMIDS. Search the PNEUMO TUBE for an EVE HYPO.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=true,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[126]=(Name="LockTooStrongForWrench",Text="This lock is too strong to break with your wrench.",TextPC="",HelpTag="None",QueuePriority=4,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[127]=(Name="ScroungeBullet",Text="Find AMMO for your pistol.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[128]=(Name="GoalFollowArrow",Text="Follow the compass ARROW to your GOAL.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=true,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[129]=(Name="KashmirBackway",Text="Find a back way through the restaurant to continue.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[130]=(Name="KashmirMoney",Text="Gather money to unlock the toilet stall in the men's room.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[131]=(Name="KashmirProceed",Text="Shoot the lock to proceed downstairs.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[132]=(Name="WelcomeGoToMedical",Text="Go down the corridor marked Medical Pavilion.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[133]=(Name="GoalUseCredits",Text="Spend your money at the bathroom stall to move on.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[134]=(Name="NeedMoney",Text="Not enough money to open stall.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[135]=(Name="GrenadeDebris",Text="Use your Telekinesis Plasmid to catch grenades and throw them at the blocked door.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[136]=(Name="GathererIntroFull",Text="CHOOSE whether to RESCUE the Little Sister\\nor HARVEST her.\\n\\nIf you harvest her, you get MAXIMUM ADAM to spend on plasmids, but she will NOT SURVIVE the process.\\n\\nIf you rescue her, you get LESS ADAM, but Tenenbaum has promised to make it\\nWORTH YOUR WHILE.",TextPC="",HelpTag="None",QueuePriority=4,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=true,NotAdaptive=true,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[137]=(Name="GathererInvulnerableIntro",Text="\\n\\n\\nThere is another LITTLE SISTER ahead.\\n\\nTo get the ADAM from her,\\nyou must deal with her BIG DADDY first.",TextPC="",HelpTag="None",QueuePriority=4,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=true,NotAdaptive=true,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[138]=(Name="HackTurret",Text="HACK this TURRET to make it your ALLY.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[139]=(Name="HackZapped",Text="HACK a SHOCKED machine while it is disabled.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[140]=(Name="IncinerateOilSlick",Text="INCINERATE the nearby OIL SLICK.",TextPC="",HelpTag="None",QueuePriority=4,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[141]=(Name="ChompersKeyFailure",Text="You need the CHOMPERS DENTAL OFFICE KEY.",TextPC="",HelpTag="None",QueuePriority=4,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=true,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[142]=(Name="GoToFontaineFisheries",Text="Seek Fontaine Fisheries to find the hidden Sub Bay.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[143]=(Name="KnockNow",Text="Press <img src=Button_A> to knock on the door.",TextPC="Press <Mapping=Use> to knock on the door.",HelpTag="None",QueuePriority=4,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=true,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[144]=(Name="GetTheCamera",Text="Find the Camera in the Harbor Master's office.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[145]=(Name="ResearchSplicers",Text="Use the Camera to take pictures of Splicers.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[146]=(Name="ResearchSplicers_2",Text="Remember to take photos of splicers to complete your goal.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[147]=(Name="GetFilm",Text="You can buy more film in the 13th Muse.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[148]=(Name="DeliverPhotos",Text="Return to Fontaine Fisheries with the Splicer research.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[149]=(Name="IceMelt",Text="Icy blockages can be melted by heat sources.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[150]=(Name="IceMelt_2",Text="Use Incinerate to melt icy blockages.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[151]=(Name="CameraTutFilmBackup",Text="You need film to take pictures. Try looking for more in the desk.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[152]=(Name="CameraTut",Text="Take pictures of enemies with the Camera\\nto RESEARCH them.\\n\\nEach type of enemy has a unique set\\nof research BONUSES.\\n\\nTry TAKING A PICTURE of the splicer\\non the other side of the window,\\nkeeping the subject centered and nearby.",TextPC="",HelpTag="None",QueuePriority=4,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=true,NotAdaptive=true,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[153]=(Name="CameraTut_1",Text="\\n\\nTAKE A PICTURE of the splicer\\non the other side of the window.\\n\\nThe nearer the subject and the closer\\nto the centre of the frame, the better the picture.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=true,NotAdaptive=true,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[154]=(Name="CameraTut_3",Text="Only the first photo of any enemy gives research benefits, so find another enemy to photograph now.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[155]=(Name="CameraDead",Text="You can take photos of DEAD ENEMIES,\\nbut you'll earn fewer research points.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[156]=(Name="PneumoNoWeapons",Text="You now have no weapons except your wrench.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[157]=(Name="CraftLazarusVector",Text="Go to a U-Invent to craft the Lazarus Vector.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[158]=(Name="CraftLazarusVector_2",Text="You have all the components needed to craft the Lazarus Vector at a U-Invent machine.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[159]=(Name="GoToDeck_5",Text="Take the Bathysphere to Hephaestus.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[160]=(Name="FindCohen",Text="Seek out Sander Cohen.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[161]=(Name="GoToGallery",Text="Check out Cohen's Gallery.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[162]=(Name="FindCronies",Text="Find Cohen's friends.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[163]=(Name="PhotoCronies",Text="Take a picture of the corpse of Cohen's friend.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[164]=(Name="FindFrame",Text="Find one of Cohen's picture frames.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[165]=(Name="ReplaceArtwork",Text="Swap your pictures for Cohen's artwork.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[166]=(Name="GoToGallery",Text="Check out Cohen's Gallery.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[167]=(Name="GoToProjectionBooth",Text="Go to the Projection Booth of the Theater.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[168]=(Name="UnlockBathysphere",Text="Flip the switch to unlock the bathysphere to Hephaestus.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[169]=(Name="CrossbowHasRisen",Text="Pick up the crossbow Cohen has rewarded you with.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[170]=(Name="GoToCentralControl",Text="Make your way to Ryan in Central Control.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[171]=(Name="FindDoorClue",Text="Search for a clue how to get through Ryan's door.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[172]=(Name="FindPabloClue",Text="Find Pablo's workspace in Heat Loss Monitoring.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[173]=(Name="FindEMPBomb",Text="Find Pablo's EMP Bomb.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[174]=(Name="FindBombParts",Text="Find and install the parts needed to complete the EMP Bomb.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[175]=(Name="RedirectSteam",Text="Pump the Magma Control Lever to clear the flood.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[176]=(Name="PlaceBomb",Text="Bring the completed EMP Bomb to the Core.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[177]=(Name="PickupBomb",Text="Pick up the completed EMP Bomb.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[178]=(Name="EMPNotEnough",Text="You do not have the necessary components. The items you need are listed in your journal.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[179]=(Name="EMPPartial",Text="The device seems incomplete. Find a diary that explains how to complete it.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[180]=(Name="MaxHealthLowered",Text="Fontaine's influence has lowered your maximum HEALTH.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[181]=(Name="MaxEVELowered",Text="Fontaine's influence has lowered your maximum EVE.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[182]=(Name="ExplainPlasmids",Text="\\n\\nLot 192 has caused some SIDE EFFECTS.\\n\\nYour plasmids have become UNSTABLE\\nand you are temporarily unable to choose\\nwhich one you have EQUIPPED.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=true,NotAdaptive=true,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[183]=(Name="SewerGateFindWheel",Text="The gate control is incomplete. Find the missing component.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[184]=(Name="BathysphereDisabled",Text="\\n\\n\\n\\nThis bathysphere is temporarily unavailable,\\nplease try again later.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=true,DoNotShowWhenHasFocus=false,IsModal=true,NotAdaptive=true,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[185]=(Name="SearchProtector",Text="Search the body of the Big Daddy near the door to the Proving Grounds.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[186]=(Name="FindPheromones",Text="You need to find Gatherer Pheromone Samples.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[187]=(Name="UsePheromoneMachine",Text="Use the Pheromone Injector Machine in the Autopsy Room.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[188]=(Name="UseVoicebox",Text="Find the Voicebox Modification Machine in Live Subject Testing.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[189]=(Name="FindSuitPieces",Text="Find the pieces of a Big Daddy Suit.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[190]=(Name="FindBoots_1",Text="Find a pair of Big Daddy Boots.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[191]=(Name="FindBoots_2",Text="Search the libraries for a pair of Big Daddy Boots.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[192]=(Name="FindTorso",Text="Search Failsafe Armored Escorts for a Bodysuit.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[193]=(Name="BodysuitInfo",Text="\\n\\n\\nThe Big Daddy bodysuit gives you\\na 25% resistance to all damage!\\n\\nSomething tells you that you'll need it.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=true,DoNotShowWhenHasFocus=false,IsModal=true,NotAdaptive=true,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[194]=(Name="FindHelmet",Text="Search Failsafe Armored Escorts for a Helmet.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[195]=(Name="GoToGathererLabs",Text="Go to the Little Wonders Educational Facility to modify your smell.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[196]=(Name="GoToPlasmidLabs",Text="Go to Optimized Eugenics to modify your voice.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[197]=(Name="GoToProtectorLabs",Text="Go to Failsafe Armored Escorts to get an armored suit.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[198]=(Name="ReturnToProvingGroundsEntrance",Text="Return to the Proving Grounds entrance.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[199]=(Name="SummonFirstPEG",Text="Bang on the nearby vent with your Wrench to summon a Little Sister.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[200]=(Name="GetANewGatherer",Text="Go to any glowing vent and bang your Wrench on it to summon a new Little Sister.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=true,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[201]=(Name="NoSummonAlive",Text="You have already summoned a Little Sister. Protect her!",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=true,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=true,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[202]=(Name="NoSummonInactive",Text="This vent has not yet been activated by a Little Sister. Go back to a glowing vent to summon a new Little Sister.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=true,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=true,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[203]=(Name="PickUpTool",Text="Take the ADAM Harvesting Tool. You will need it to defeat Fontaine!",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[204]=(Name="GoToBossFight",Text="Take the elevator up to confront Fontaine!",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[205]=(Name="DrainAdamAtlas",Text="Atlas is vulnerable in his chair. Drain ADAM from him NOW!",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[206]=(Name="NoResStations",Text="You are now unable to Save the game and there are no Vita-Chambers nearby.  If you die, you must Continue from saved progress.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=true,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=true,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[207]=(Name="MapMedicalFoyer",Text="Medical Foyer",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[208]=(Name="MapMedicalEmergencyAccess",Text="Emergency Access",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[209]=(Name="MapMedicalSurgicalFoyer",Text="Surgical Foyer",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[210]=(Name="MapMedicalSurgicalSavings",Text="Surgical Savings",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[211]=(Name="MapMedicalAestheticIdeals",Text="Aesthetic Ideals",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[212]=(Name="MapMedicalKureAll",Text="Kure All",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[213]=(Name="MapMedicalDandyDental",Text="Dandy Dental",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[214]=(Name="MapMedicalPainlessDental",Text="Painless Dental",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[215]=(Name="MapMedicalEternalFlame",Text="Eternal Flame",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[216]=(Name="MapMedicalTwilightFields",Text="Twilight Fields",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[217]=(Name="DLCVitaChambersAlwaysOn",Text="Vita-Chambers are always active in the puzzle rooms.",TextPC="",HelpTag="None",QueuePriority=4,RepeatDelay=9999.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[218]=(Name="CRCRoomOneDone",Text="\\n\\nYou've beaten your first challenge, but the next one is harder. You now have all your weapons, but you'll need to buy some ammunition.",TextPC="",HelpTag="None",QueuePriority=4,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=true,NotAdaptive=true,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[219]=(Name="CRCAnyOrder",Text="\\n\\n\\nYou can attempt the remaining arenas in any order you like. Some are more difficult than others.",TextPC="",HelpTag="None",QueuePriority=4,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=true,NotAdaptive=true,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[220]=(Name="CRCHackingCounts",Text="\\n\\nHacking an enemy counts as defeating it for purposes of this Challenge Room.",TextPC="",HelpTag="None",QueuePriority=4,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=true,NotAdaptive=true,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[221]=(Name="CREFailure",Text="\\n\\nAlas, you've squandered too much electricity to get the Little Sister down safely now.\\n\\nPlease restart, load a save or press <img src=Button_A> to continue exploring.",TextPC="",HelpTag="None",QueuePriority=4,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=true,NotAdaptive=true,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[222]=(Name="CRDTargetDummyMisuse",Text="You can only have one Target Dummy at a time.  If you make a new one, the existing one will be destroyed.",TextPC="",HelpTag="None",QueuePriority=4,RepeatDelay=9999.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[223]=(Name="CRETelekinesisDrop",Text="Press <img src=Button_X> to DROP an object held with Telekinesis.",TextPC="",HelpTag="None",QueuePriority=4,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[224]=(Name="CRCRez",Text="\\n\\nThis Vita-Chamber will not be present in the final level.  Please load a save game to continue.",TextPC="",HelpTag="None",QueuePriority=4,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=true,NotAdaptive=true,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[225]=(Name="CRCHackingTonics",Text="If you are having trouble hacking, try purchasing Tonics to help you at the Gatherer's Garden.",TextPC="",HelpTag="None",QueuePriority=0,RepeatDelay=300.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=false,NotAdaptive=false,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[226]=(Name="CRCIntro",Text="\\nThe Little Sister wants to be rescued, but this area is crawling with hostile creatures! Clear out all eight combat arenas and she will let you in.\\n\\nNo puzzles here, and no Vita-Chamber - it's kill or be killed!",TextPC="",HelpTag="None",QueuePriority=4,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=true,NotAdaptive=true,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[227]=(Name="CREIntro",Text="\\nThe Little Sister is trapped at the top of a malfunctioning Ferris wheel!   To bring her down safely, you will need to find ways to electrify the Ferris wheel controls.\\n\\nCan you solve this shocking puzzle?",TextPC="",HelpTag="None",QueuePriority=4,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=true,NotAdaptive=true,SpokenDialog="None",GlowHudItem="None")
	TrainingMessages[228]=(Name="CRDIntro",Text="\\nRescuing the Little Sister means eliminating her Big Daddy - but how?\\n\\nWith no weapons or damage-dealing plasmids, it'll take cunning and creativity to solve this puzzle.",TextPC="",HelpTag="None",QueuePriority=4,RepeatDelay=0.0000000,ShowInCombat=false,DoNotShowWhenHasFocus=false,IsModal=true,NotAdaptive=true,SpokenDialog="None",GlowHudItem="None")
	TrainingTips[0]=(Name="Save",Text="You can SAVE your game at any time\\nfrom the PAUSE menu.",TextPC="",QueuePriority=0,PlayOnce=false)
	TrainingTips[1]=(Name="CM_1",Text="CM1",TextPC="Use <Mapping=Fire>\\nto fire a WEAPON or use a PLASMID.",QueuePriority=0,PlayOnce=false)
	TrainingTips[2]=(Name="CM_2",Text="CM2",TextPC="Use <Mapping=SwitchWeaponsOrPlasmids>\\nto toggle between WEAPONS and PLASMIDS.",QueuePriority=0,PlayOnce=false)
	TrainingTips[3]=(Name="Quests",Text="Press <img src=Button_Back> to see your GOAL and the MAP.\\nYou can also get a HINT if you're stuck.",TextPC="Press <Mapping=ShowContextHelp> to see your GOAL and the MAP.\\nYou can also get a HINT if you're stuck.",QueuePriority=0,PlayOnce=false)
	TrainingTips[4]=(Name="Shocked_2",Text="Hit WATER with an ELECTRIC attack to FRY everyone in the water.",TextPC="",QueuePriority=0,PlayOnce=false)
	TrainingTips[5]=(Name="ManualEVE",Text="Press <img src=Button_X> to use an EVE hypo.",TextPC="With a PLASMID equipped,\\npress <Mapping=Reload> to use an EVE hypo.",QueuePriority=0,PlayOnce=false)
	TrainingTips[6]=(Name="HeadShots",Text="Aim for the head! You will do more damage.",TextPC="",QueuePriority=0,PlayOnce=false)
	TrainingTips[7]=(Name="Jump",Text="Press <img src=Button_Y> button to JUMP.",TextPC="Press <Mapping=Jump> button to JUMP.",QueuePriority=0,PlayOnce=false)
	TrainingTips[8]=(Name="CrouchSneak",Text="Click <img src=Button_LS> to CROUCH.\\nCrouching makes it easier to SNEAK up on enemies.",TextPC="Press <Mapping=Duck> to CROUCH.\\nCrouching makes it easier to SNEAK up on enemies.",QueuePriority=0,PlayOnce=false)
	TrainingTips[9]=(Name="Shadows",Text="AVOID enemies by hiding in the SHADOWS.",TextPC="",QueuePriority=0,PlayOnce=false)
	TrainingTips[10]=(Name="PlasmidsAmmo",Text="If LOW ON AMMO, remember to use your PLASMIDS.",TextPC="",QueuePriority=0,PlayOnce=false)
	TrainingTips[11]=(Name="SplicerExplanation",Text="'Splicer' is the term used to describe inhabitants of Rapture whose excessive use of Plasmids has wrecked their minds.",TextPC="",QueuePriority=0,PlayOnce=false)
	TrainingTips[12]=(Name="PullAndHold",Text="HOLD a trigger down\\nto equip and fire a PLASMID or WEAPON.",TextPC="Press <Mapping=SwitchWeaponsOrPlasmids> to switch between PLASMIDS and WEAPONS.",QueuePriority=0,PlayOnce=false)
	TrainingTips[13]=(Name="ActiveGoal",Text="Press <img src=Button_Back> to view your current GOAL\\nin the Goals tab. The compass ARROW will guide you to it if possible.",TextPC="Press <Mapping=ShowContextHelp> to view your current GOAL\\nin the Goals tab. The compass ARROW will guide you to it if possible.",QueuePriority=0,PlayOnce=false)
	TrainingTips[14]=(Name="LogsAndRadios",Text="Press <img src=Button_Back> and go to the MESSAGES tab\\nto replay radio messages and diaries.",TextPC="Press <Mapping=ShowContextHelp> and go to the MESSAGES tab\\nto replay radio messages and diaries.",QueuePriority=0,PlayOnce=false)
	TrainingTips[15]=(Name="HackTurrets",Text="HACK a turret to make it shoot enemies instead of you!",TextPC="",QueuePriority=0,PlayOnce=false)
	TrainingTips[16]=(Name="HackVending",Text="HACK a VENDING machine to get better prices\\nand special items!",TextPC="",QueuePriority=0,PlayOnce=false)
	TrainingTips[17]=(Name="HackCamera",Text="HACK a security CAMERA to send BOTS against enemies instead of you!",TextPC="",QueuePriority=0,PlayOnce=false)
	TrainingTips[18]=(Name="HackHealthStation",Text="HACK a Health Station to reduce its COST and HURT splicers who try to heal from it!",TextPC="",QueuePriority=0,PlayOnce=false)
	TrainingTips[19]=(Name="Buying",Text="Spend your MONEY at a VENDING machine to get AMMO, FIRST-AID KITS, HYPOS and other items.",TextPC="",QueuePriority=0,PlayOnce=false)
	TrainingTips[20]=(Name="HealthStation",Text="Spend money to HEAL yourself at any HEALTH station.",TextPC="",QueuePriority=0,PlayOnce=false)
	TrainingTips[21]=(Name="Fire",Text="FIRE can SPREAD to nearby objects and enemies.",TextPC="",QueuePriority=0,PlayOnce=false)
	TrainingTips[22]=(Name="DamageTypes_1",Text="ANTIPERSONNEL ammo does\\nEXTRA DAMAGE against Splicers.",TextPC="",QueuePriority=0,PlayOnce=false)
	TrainingTips[23]=(Name="DamageTypes_2",Text="ARMOR PIERCING ammo does extra damage against BIG DADDIES, TURRETS, CAMERAS and SECURITY BOTS.",TextPC="",QueuePriority=0,PlayOnce=false)
	TrainingTips[24]=(Name="EnemyHealthStations",Text="Wounded Splicers can HEAL at a Health Station.",TextPC="",QueuePriority=0,PlayOnce=false)
	TrainingTips[25]=(Name="Frozen",Text="Enemies who are FROZEN can be SHATTERED if you damage them before they THAW.",TextPC="",QueuePriority=0,PlayOnce=false)
	TrainingTips[26]=(Name="Frozen_2",Text="If you SHATTER a FROZEN enemy, they will leave behind no body for you to LOOT.",TextPC="",QueuePriority=0,PlayOnce=false)
	TrainingTips[27]=(Name="TelekinesisExplosives",Text="Use TELEKINESIS to throw gas cylinders\\nand other EXPLOSIVE OBJECTS at your enemies.",TextPC="",QueuePriority=0,PlayOnce=false)
	TrainingTips[28]=(Name="TelekinesisAmmo",Text="When LOW ON AMMO, you can always use TELEKINESIS to throw objects at your enemies.",TextPC="",QueuePriority=0,PlayOnce=false)
	TrainingTips[29]=(Name="FindThoseTonics",Text="Many GENE TONICS are scattered around Rapture\\nand can be picked up for free.",TextPC="",QueuePriority=0,PlayOnce=false)
	TrainingTips[30]=(Name="HackBots",Text="After shutting down a Security Alarm, you can hack the disabled Security Bots to be friendly to you.",TextPC="",QueuePriority=0,PlayOnce=false)
	TrainingTips[31]=(Name="DontShootCameras",Text="Don't shoot Security CAMERAS - make them work for you with the SECURITY BULLSEYE Plasmid\\nor by HACKING them.",TextPC="",QueuePriority=0,PlayOnce=false)
	TrainingTips[32]=(Name="Research",Text="Take photos and RESEARCH tough enemies\\nfor COMBAT BONUSES against them.",TextPC="",QueuePriority=0,PlayOnce=false)
	TrainingTips[33]=(Name="Research_2",Text="You get more RESEARCH points for good PHOTOS.\\nA good photo has the subject CENTERED\\nand fully VISIBLE.",TextPC="",QueuePriority=0,PlayOnce=false)
	TrainingTips[34]=(Name="WeaponUpgrades",Text="Upgrade your weapons\\nat a POWER TO THE PEOPLE station.",TextPC="",QueuePriority=0,PlayOnce=false)
	TrainingTips[35]=(Name="FreezeHack",Text="FREEZE something which can be HACKED, to slow down the fluid, making the HACK EASIER.",TextPC="",QueuePriority=0,PlayOnce=false)
	TrainingTips[36]=(Name="DestroyHealthStation",Text="Destroy a HEALTH station\\nand you will get a free Health Pack!",TextPC="",QueuePriority=0,PlayOnce=false)
	TrainingTips[37]=(Name="ProximityGrenades",Text="You can walk through your own PROXIMITY MINES\\nwithout setting them off.",TextPC="",QueuePriority=0,PlayOnce=false)
	TrainingTips[38]=(Name="PlasmidUpgrades",Text="You can splice MULTIPLE VERSIONS of the same\\ngene tonic to get BOOSTED EFFECTS.",TextPC="",QueuePriority=0,PlayOnce=false)
	TrainingTips[39]=(Name="ResearchAdvice01",Text="Taking close-up pictures of enemies earns you more RESEARCH POINTS. Pictures of enemies in combat\\nearn extra points.",TextPC="",QueuePriority=0,PlayOnce=false)
	TrainingTips[40]=(Name="ResearchAdvice02",Text="Taking Research Photos can give you\\npermanent damage bonuses, unique Gene Tonics,\\nand other rewards.",TextPC="",QueuePriority=0,PlayOnce=false)
	TrainingTips[41]=(Name="EnemiesImmune",Text="Some enemies are IMMUNE to some attacks. Match the right attacks to the right enemies.",TextPC="",QueuePriority=0,PlayOnce=false)
	TrainingTips[42]=(Name="ChangeDifficulty",Text="You can change the game's DIFFICULTY\\nat any time in the OPTIONS.",TextPC="",QueuePriority=0,PlayOnce=false)
	TrainingTips[43]=(Name="Crafting",Text="Use U-Invent Stations to make\\nSPECIAL AMMO and new TONICS.",TextPC="",QueuePriority=0,PlayOnce=false)
	TrainingTips[44]=(Name="HackCrafting",Text="HACK a U-Invent to reduce the number\\nof components required to invent items!",TextPC="",QueuePriority=0,PlayOnce=false)
	TrainingTips[45]=(Name="EnragingEnemies",Text="Only use ENRAGE on a group of enemies.\\nA solo enemy will just attack you!",TextPC="",QueuePriority=0,PlayOnce=false)
	TrainingTips[46]=(Name="TelekinesisFireballs",Text="You can use TELEKINESIS to CATCH FIREBALLS\\nand throw them back.",TextPC="",QueuePriority=0,PlayOnce=false)
	TrainingTips[47]=(Name="GeneTonicStacking",Text="You can equip MULTIPLES of the same GENE TONIC.",TextPC="",QueuePriority=0,PlayOnce=false)
	TrainingTips[48]=(Name="TrapBoltHelp",Text="TRAP BOLTS can be disarmed using TELEKINESIS,\\nor detonated with explosives.",TextPC="",QueuePriority=0,PlayOnce=false)
	TrainingTips[49]=(Name="TurnOffAdaptive",Text="You can turn off TRAINING messages\\nin the OPTIONS.",TextPC="",QueuePriority=0,PlayOnce=false)
	TrainingTips[50]=(Name="GetBetterPlasmids",Text="If your plasmids are losing effectiveness against tougher enemies, find the improved versions of those Plasmids.",TextPC="",QueuePriority=0,PlayOnce=false)
	TrainingTips[51]=(Name="ZoomReminder",Text="Click <img src=Button_RS> to zoom with\\nthe Pistol, Machine Gun and Crossbow.",TextPC="Press <Mapping=ZoomCycle> to zoom with\\nthe Pistol, Machine Gun and Crossbow.",QueuePriority=0,PlayOnce=false)
	TrainingTips[52]=(Name="Quote01",Text="''A city in the ocean's deep, a promise we will\\nalways keep... so, rise! Rise! Rise!''\\n- Lyrics to Sander Cohen's Rise Rapture, Rise!",TextPC="",QueuePriority=1,PlayOnce=false)
	TrainingTips[53]=(Name="Quote02",Text="''A gun in every home, peace on every street.''\\n- Frank Fontaine at the installation of the first\\nPower to the People machine, 1/22/57",TextPC="",QueuePriority=1,PlayOnce=false)
	TrainingTips[54]=(Name="Quote03",Text="''It was not impossible to build Rapture at the bottom of the sea. It was impossible to build it anywhere else.''\\n- Andrew Ryan ",TextPC="",QueuePriority=2,PlayOnce=false)
	TrainingTips[55]=(Name="Quote04",Text="''This city is not built with concrete and steel...\\nit is built with ideas!''\\n- Anton Kinkaide, Founder, Rapture Metro",TextPC="",QueuePriority=1,PlayOnce=false)
	TrainingTips[56]=(Name="Quote05",Text="''A star, mama! Mr. Ryan said\\nhe's going to make me a star!''\\n- Mary-Catherine (Jasmine) Jolene",TextPC="",QueuePriority=1,PlayOnce=false)
	TrainingTips[57]=(Name="Quote06",Text="''Adam is the canvas of genetic modification...\\nbut plasmids are the paint.''\\n- Dr. Suchong",TextPC="",QueuePriority=2,PlayOnce=false)
	TrainingTips[58]=(Name="Quote07",Text="''Commerce is the life blood of the City. If we are not careful, government will become the cancer.''\\n- Andrew Ryan",TextPC="",QueuePriority=1,PlayOnce=false)
	TrainingTips[59]=(Name="Quote08",Text="''Darling, you really MUST go see Steinman...\\neveryone goes to Steinman!''\\n- Marianne Dellahunt, Resident, Mercury Suites",TextPC="",QueuePriority=1,PlayOnce=false)
	TrainingTips[60]=(Name="Quote09",Text="''Do we gouge the suckers a little? Maybe.\\nBut where else they gonna go?''\\n- Lloyd Webster, President, Circus of Values Vending",TextPC="",QueuePriority=1,PlayOnce=false)
	TrainingTips[61]=(Name="Quote_10",Text="''In Washington you can see them everywhere:\\nthe Parasites and baby Stalins sucking the life\\nout of a once-great nation.'' - Andrew Ryan",TextPC="",QueuePriority=1,PlayOnce=false)
	TrainingTips[62]=(Name="Quote_11",Text="''It's like I don't even recognize Rapture no more. I hear they've been rounding up people in Apollo Square...''\\n- Diane McClintock",TextPC="",QueuePriority=2,PlayOnce=false)
	TrainingTips[63]=(Name="Quote_12",Text="''Leaks. Lunatics. Rebellion. And now bleeding ghosts. Ain't life in Rapture grand?''\\n- Bill McDonagh",TextPC="",QueuePriority=2,PlayOnce=false)
	TrainingTips[64]=(Name="Quote_13",Text="''Me? They brought me down to this here utopia to cook hamburgers. Even supermen gotta eat, right?''\\n- Albert Milonakis",TextPC="",QueuePriority=1,PlayOnce=false)
	TrainingTips[65]=(Name="Quote_14",Text="''My city was betrayed by the weak...''\\n- Andrew Ryan",TextPC="",QueuePriority=1,PlayOnce=false)
	TrainingTips[66]=(Name="Quote_15",Text="''Now the eggs are in the scramble. Ryan'll be taking down Fontaine, or Fontaine'll be taking down Ryan.''\\n- Security Chief Sullivan",TextPC="",QueuePriority=2,PlayOnce=false)
	TrainingTips[67]=(Name="Quote_16",Text="''Fontaine fellow... he's a crook... but he's got the ADAM, and that makes him the guv'nor.''\\n- Bill McDonagh",TextPC="",QueuePriority=2,PlayOnce=false)
	TrainingTips[68]=(Name="Quote_17",Text="''Ryan takes down smuggling operation...\\nFontaine and thugs killed in fiery shootout!''\\n- Headline, Rapture Standard, 9/12/58",TextPC="",QueuePriority=2,PlayOnce=false)
	TrainingTips[69]=(Name="Quote_18",Text="''Sander Cohen is two parts suck-up\\nand ten parts hack. And that's being charitable.''\\n- Anna Culpepper",TextPC="",QueuePriority=1,PlayOnce=false)
	TrainingTips[70]=(Name="Quote_19",Text="''Sure, the boys in Ryan's labs can make it hack-proof. But that don't mean we ain't gonna hack it.''\\n- Pablo Navarro",TextPC="",QueuePriority=2,PlayOnce=false)
	TrainingTips[71]=(Name="Quote_20",Text="''Until Adam, you could no more\\ndomesticate a child than a boa constrictor...''\\n- Dr. Suchong",TextPC="",QueuePriority=2,PlayOnce=false)
	TrainingTips[72]=(Name="Quote_21",Text="''We laid the foundations of Rapture at the end of\\nthe last war... but before the final, terrible war\\nthat is to come...'' - Andrew Ryan",TextPC="",QueuePriority=1,PlayOnce=false)
	TrainingTips[73]=(Name="Quote_22",Text="''What would the Russian Bear and the American Eagle do if they discovered our paradise? Our secrecy\\nis our shield!'' - Andrew Ryan",TextPC="",QueuePriority=1,PlayOnce=false)
	TrainingTips[74]=(Name="Quote_23",Text="''Why children take so long to grow? They eat and drink like pig and give nothing back. Must find way to accelerate process...'' - Dr. Suchong",TextPC="",QueuePriority=2,PlayOnce=false)
	TrainingTips[75]=(Name="Quote_24",Text="''Who can forget their first view of the city?  Amazing what a man can create once he gets government\\nand God off his back.'' - Bill McDonagh",TextPC="",QueuePriority=1,PlayOnce=false)
	TrainingTips[76]=(Name="Quote_25",Text="''Why not spend your holiday in Arcadia?\\nFun for the whole family!''\\n- Ad in the Rapture Standard, 9/1/53.",TextPC="",QueuePriority=1,PlayOnce=false)
	TrainingTips[77]=(Name="Quote_26",Text="''Why worship a flag or a God, when we can worship\\nthat which is best in us: our will to be great.''\\n- Andrew Ryan ",TextPC="",QueuePriority=1,PlayOnce=false)
	TrainingTips[78]=(Name="Quote_27",Text="''Yeah, Rapture's full of fancy pants and lots of other stuffed shirts. But so long as they tip all right, I'm happy to rub elbows with 'em.'' - Albert Milonakis",TextPC="",QueuePriority=1,PlayOnce=false)
	TrainingTips[79]=(Name="Quote_28",Text="''You know that nine out of ten ladies\\nprefer the athletic man?''\\n- Advertisement, SportBoost Gene Tonic",TextPC="",QueuePriority=2,PlayOnce=false)
	TrainingTips[80]=(Name="CRCCM_1",Text="CM1",TextPC="",QueuePriority=0,PlayOnce=true)
	TrainingTips[81]=(Name="CRCCM_2",Text="CM2",TextPC="",QueuePriority=0,PlayOnce=true)
	TrainingTips[82]=(Name="CRCRoom",Text="If you are having difficulty in one arena, consider trying another one.",TextPC="",QueuePriority=0,PlayOnce=false)
	TrainingTips[83]=(Name="CRCPlasmid",Text="If your weapons aren't getting the job done, try using plasmids.",TextPC="",QueuePriority=0,PlayOnce=false)
	TrainingTips[84]=(Name="CRCWeapon",Text="If your plasmids aren't getting the job done, try using weapons.",TextPC="",QueuePriority=0,PlayOnce=false)
	TrainingTips[85]=(Name="CRCSave",Text="Save your game often, using different slots.",TextPC="",QueuePriority=0,PlayOnce=false)
	TrainingTips[86]=(Name="CRCAny",Text="If your current strategy isn't working, consider trying something else.",TextPC="",QueuePriority=0,PlayOnce=false)
	TrainingTips[87]=(Name="CRCAny_2",Text="There are many different ways to defeat each arena.",TextPC="",QueuePriority=0,PlayOnce=false)
	TrainingTips[88]=(Name="CRCHack",Text="If you're having trouble with hacking, try buying some Engineering tonics.",TextPC="",QueuePriority=0,PlayOnce=false)
	TrainingTips[89]=(Name="CRCResearch",Text="The Research Camera can make many fights easier.",TextPC="",QueuePriority=0,PlayOnce=false)
	TrainingTips[90]=(Name="CRCScout",Text="Scouting an arena from above may suggest useful tactics.",TextPC="",QueuePriority=0,PlayOnce=false)
	TrainingTips[91]=(Name="CRCUpgrade",Text="Remember to upgrade your weapons.",TextPC="",QueuePriority=0,PlayOnce=false)
	TrainingTips[92]=(Name="CRCIndirect",Text="Sometimes turning your enemies against each other is the best strategy.",TextPC="",QueuePriority=0,PlayOnce=false)
	TrainingTips[93]=(Name="CRCFinal",Text="When you are approaching the last arena, spend all your resources. There's no more point in saving them!",TextPC="",QueuePriority=0,PlayOnce=false)
	TipRepeatDelay=7200.0000000
	TipDisplayTime=14.0000000
	MinTipDisplayTime=5.0000000
	MessageSuppressionTime=2.5000000
	MessageCombatSuppressionTime=5.0000000
	EnableTrainingScripts=true
	EnableAdaptiveMessages=true
	TrainingMessageBaseDuration=3.5000000
	TrainingMessageCharacterMultiplier=0.0500000
	NearnessChecks[0]=(ClassName="SecurityCamera",Distance=1000.0000000,AssertedThisFrame=false)
	NearnessChecks[1]=(ClassName="SecurityStation",Distance=1000.0000000,AssertedThisFrame=false)
	NearnessChecks[2]=(ClassName="CraftingStation",Distance=350.0000000,AssertedThisFrame=false)
	NearnessChecks[3]=(ClassName="HealthStation",Distance=350.0000000,AssertedThisFrame=false)
	NearnessChecks[4]=(ClassName="VendingStation",Distance=350.0000000,AssertedThisFrame=false)
	NearnessChecks[5]=(ClassName="SpawnedMinimumSecurityBot",Distance=350.0000000,AssertedThisFrame=false)
	NearnessChecks[6]=(ClassName="SpawnedMediumSecurityBot",Distance=350.0000000,AssertedThisFrame=false)
	NearnessChecks[7]=(ClassName="SpawnedMinimumSecurityTurret",Distance=350.0000000,AssertedThisFrame=false)
	NearnessChecks[8]=(ClassName="SpawnedMedumSecurityTurret",Distance=350.0000000,AssertedThisFrame=false)
	NearnessChecks[9]=(ClassName="SpawnedMaximumSecurityTurret",Distance=350.0000000,AssertedThisFrame=false)
	NearnessChecks[10]=(ClassName="SpawnedMinimumSecurityCameraWall",Distance=350.0000000,AssertedThisFrame=false)
	NearnessChecks[11]=(ClassName="SpawnedMediumSecurityCameraWall",Distance=350.0000000,AssertedThisFrame=false)
	NearnessChecks[12]=(ClassName="SpawnedMaximumSecurityCameraWall",Distance=350.0000000,AssertedThisFrame=false)
	NearnessChecks[13]=(ClassName="SpawnedMinimumSecurityCamera",Distance=350.0000000,AssertedThisFrame=false)
	NearnessChecks[14]=(ClassName="SpawnedMediumSecurityCamera",Distance=350.0000000,AssertedThisFrame=false)
	NearnessChecks[15]=(ClassName="SpawnedMaximumSecurityCamera",Distance=350.0000000,AssertedThisFrame=false)
	NearnessChecks[16]=(ClassName="TrainingMarker",Distance=350.0000000,AssertedThisFrame=false)
	NearnessChecks[17]=(ClassName="ResurrectionStationModel",Distance=350.0000000,AssertedThisFrame=false)
	NearnessChecks[18]=(ClassName="Container",Distance=200.0000000,AssertedThisFrame=false)
	TelekinesisFlubTime=0.2000000
	TimeToConsiderEnrageFailure=1.0000000
}