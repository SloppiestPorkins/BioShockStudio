class AIWeapon extends Weapon implements IHaveAContainer, IAffectedByTelekinesis, IDamagee
	native
	config(Weapons)
	hidecategories(DrawScale3D,DisplayAdvanced);

enum EWeaponFireStartOffsetType
{
	kNoOffset,                      // 0
	kUseWeaponAimPoseOffset,        // 1
	kUseWeaponOffset,               // 2
	kUseAttachSocketInAnimationOffset,// 3
	kUseMeleeWeaponOffset           // 4
};

enum EWeaponFireStartRotationType
{
	kUseWeaponRotation,             // 0
	kUseAIRotation,                 // 1
	kUseRotationToTarget            // 2
};

struct native atomic AttackAnimationInfo
{
	var config name AttackAnimation;
	var config float Weight;
	var config name SourceSocketName;
	var config Range AttackAnimationRange;
	var config bool bCheckFullAnimationMotion;
	var config bool bIsCeilingAttackAnimation;
	var config bool bUseInitiateDamageRotation;
	var config bool bPlayerOnlyAttack;
	var config bool bDoNotUseForProjectedTests;
	var config Range TimeBetweenUsageOverride;

	structdefaultproperties
	{
		CheckpointTypePadding=7602293
	}
};

struct native atomic WeaponAttackInfo
{
	var name AIAttackAnimation;
	var float AIAttackAnimationAttackTime;
	var Range AttackRange;
	var float Weight;
	var bool bIsCeilingAttackAnimation;
	var Vector AIAttackTranslation;
	var bool bCheckFullAnimationMotion;
	var bool bUseInitiateDamageRotation;
	var bool bPlayerOnlyAttack;
	var bool bDoNotUseForProjectedTests;
	var Vector FullAnimationTranslation;
	var float AIAttackDeltaYaw;
	var Vector WeaponAttackOffset;
	var Range TimeBetweenUsageOverride;

	structdefaultproperties
	{
		CheckpointTypePadding=7602293
	}
};

struct native atomic UsableWeaponAttackInfo
{
	structcpptext
	{

		FUsableWeaponAttackInfo()
		{
		}

		FUsableWeaponAttackInfo(FName inAIAttackAnimation, FLOAT inAIAttackAnimationAttackTime, FVector inFireStartOffset, FRotator inFireStartRotation, FLOAT inWeight, AShockPawn* inTarget, FRange inTimeBetweenUsageOverride)
			: AIAttackAnimation(inAIAttackAnimation), AIAttackAnimationAttackTime(inAIAttackAnimationAttackTime), FireStartOffset(inFireStartOffset), FireStartRotation(inFireStartRotation), Weight(inWeight), Target(inTarget), TimeBetweenUsageOverride(inTimeBetweenUsageOverride), bIsValid(true)
		{
		}
	
	}

	var name AIAttackAnimation;
	var float AIAttackAnimationAttackTime;
	var Vector FireStartOffset;
	var Rotator FireStartRotation;
	var float Weight;
	var ShockPawn Target;
	var Range TimeBetweenUsageOverride;
	var bool bIsValid;

	structdefaultproperties
	{
		CheckpointTypePadding=7602293
	}
};

struct native atomic LocomotionKeywordInfo
{
	var config name keyword;
	var config int KeywordPriority;

	structdefaultproperties
	{
		CheckpointTypePadding=7602293
	}
};

var array<WeaponAttackInfo> WeaponAttackInfos;
var config array<AttackAnimationInfo> AttackAnimationInfos;
var private AIWeapon.EWeaponFireStartOffsetType WeaponFireStartOffsetType;
var private AIWeapon.EWeaponFireStartRotationType WeaponFireStartRotationType;
var private bool bUseTargetTrackingLocation;
var private bool bUseCachedCanHitRotation;
var private bool bProjectTargetPosition;
var private bool bUseForProjectedAttackTests;
var private bool bVerifyAIOriginToWeaponSourceOrigin;
var private bool bUseAIRotationAlways;
var config Vector WeaponFireStartOffset;
var config name BaseAnimationForSocketOffsets;
var config float WeightCutoff;
var config float MinTravelPercentageForFullAnimation;
var config float MinTravelPercentageForAttack;
var private Range AttackAnimationsTranslationRange;
var private float AverageAttackAnimationInitiateDamageTime;
var private float TotalAttackAnimationInitiateDamageTime;
var private int NumWeaponAttackInfosWithZeroTranslation;
var private bool bUseCanHitCaching;
var private bool bLastCanHitResult;
var private float LastCanHitTestTime;
var private Vector LastCanHitAILocation;
var private bool bLastCanHitQuickTestResult;
var private float LastCanHitQuickTestTime;
var config string FireEffectLocationSocketName;
var config bool bCanBeInterrupted;
var private UsableWeaponAttackInfo NextWeaponAttackInfo;
var private config float BaseMinTimeBetweenUsage;
var private config float BaseMaxTimeBetweenUsage;
var private float ReadyToUseTime;
var private float ReadyToUseSetTime;
var private config bool bGetReadyToUseMultiplierFromHolder;
var config array<LocomotionKeywordInfo> WeaponHolderAnimationKeywords;
var private config localized string FriendlyName;
var private config localized string UseVerbText;
var private config bool bCanBeAFocus;
var private export editinline Container Container;
var private config bool bUseAsContainer;
var private config bool ShouldTreatAsAPickup;
var private config name LootSlot0TableName;
var private config name LootSlot1TableName;
var private config name LootSlot2TableName;

function PreBeginPlay()
{
	super(Actor).PreBeginPlay();
	InitializeContainer();
	return;
	@NULL
}

function InitializeContainer()
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0xD2
	/*@Error*/
	Container = Class'ShockGame.Container'.static.Allocate(self, Level).;
	Construct_Void();
	// End:0x6E
	if(__NFUN_119__(Container, none))
	{
		Container.SetOwner(self);
		Container.SetLootSlotTableName(0, LootSlot0TableName);
	}
	Container.SetLootSlotTableName(1, LootSlot1TableName);
	Container.SetLootSlotTableName(2, LootSlot2TableName);
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function BaseChange()
{
	super(Actor).BaseChange();
	// End:0x34
	if(__NFUN_114__(Base, Owner))
	{
		TriggerEffectEvent('AttachedToOwner');
		return;
		@NULL
		CommanderAction
	}
	stop;
	default.@NULL
}

function Destroyed()
{
	super.Destroyed();
	DestroyManagedAIWeaponObjects();
	return;
	@NULL
}

// Export UAIWeapon::execDestroyManagedAIWeaponObjects(FFrame&, void* const)
native function DestroyManagedAIWeaponObjects();

function UsableWeaponAttackInfo GetNextWeaponAttackInfo()
{
	return NextWeaponAttackInfo;
	return;
	@NULL
}

function PostLoadGame()
{
	super(Actor).PostLoadGame();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x24
	/*@Error*/
	SetupAttackInfos();
	return;
	@NULL
	CommanderAction
}

function PlayWeaponAnimations(optional name HandsAnim, optional name WeaponAnim, optional name HolderAnim, optional name AltFireAttachmentAnim, optional name StrictlySuperiorAttachmentAnim, optional float Rate, optional int AnimationEndBehavior, optional float EaseInTime)
{
	// End:0x1B
	if(__NFUN_154__(AnimationEndBehavior, 0))
	{
		AnimationEndBehavior = 4;
		assert(__NFUN_119__(Holder, none));
	}
	HolderAnimationHandle = Holder.PlayAnimationOnChannel(Holder.GetAnimationChannelForWeapon(self), HolderAnim, 1);
	Holder.SetAnimationPlaybackRate(HolderAnimationHandle, __NFUN_171__(Rate, Holder.GetAnimationPlaybackRate(HolderAnimationHandle)));
	SetHolderAnimationMotionModifier(HolderAnimationHandle);
	AnimationHandle = PlayAnimationOnChannel(0, WeaponAnim, AnimationEndBehavior);
	SetAnimationPlaybackRate(AnimationHandle, __NFUN_171__(Rate, GetAnimationPlaybackRate(AnimationHandle)));
	return;
	@NULL
	EcologyAI
	CommanderAction
	@NULL
}

function SetHolderAnimationMotionModifier(int HolderAnimationHandle)
{
	return;
}

function SetupAttackInfos()
{
	local ShockAI OwnerAI;
	local int i;

	OwnerAI = ShockAI(Owner);
	assert(__NFUN_119__(OwnerAI, none));
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xE7
	/*@Error*/
	AttackAnimationsTranslationRange.Min = 1000000.0000000;
	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xB2
	/*@Error*/
	CreateAttackInfo(OwnerAI, AttackAnimationInfos[i]);
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x66;
	SortWeaponAttackInfos();
	AverageAttackAnimationInitiateDamageTime = __NFUN_172__(TotalAttackAnimationInitiateDamageTime, float(AttackAnimationInfos.Length));
	SaveAttackInfoIntoDefault();
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function SaveAttackInfoIntoDefault()
{
	default.WeaponAttackInfos = WeaponAttackInfos;
	default.AverageAttackAnimationInitiateDamageTime = AverageAttackAnimationInitiateDamageTime;
	default.NumWeaponAttackInfosWithZeroTranslation = NumWeaponAttackInfosWithZeroTranslation;
	default.AttackAnimationsTranslationRange = AttackAnimationsTranslationRange;
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

// Export UAIWeapon::execSortWeaponAttackInfos(FFrame&, void* const)
private native function SortWeaponAttackInfos();

function Vector GetWeaponAttackOffset(ShockAI OwnerAI, name AnimationName, float InitiateDamageTime, name SourceSocketName)
{
	local name AttachSocketName;

	// End:0xB4
	if(__NFUN_154__(int(WeaponFireStartOffsetType), int(3)))
	{
		// End:0x41
		if(__NFUN_255__(SourceSocketName, 'None'))
		{
			AttachSocketName = SourceSocketName;
			goto J0x5E;
			AttachSocketName = GetAttachBone(OwnerAI);
		}
		assert(__NFUN_255__(AttachSocketName, 'None'));
		return OwnerAI.GetSocketOffsetInAnimation(AttachSocketName, AnimationName, BaseAnimationForSocketOffsets, InitiateDamageTime);
		goto J0x154;
		// End:0xD5
		if(__NFUN_154__(int(WeaponFireStartOffsetType), int(2)))
		{
			return WeaponFireStartOffset;
			goto J0x154;
			// End:0x104
			if(__NFUN_154__(int(WeaponFireStartOffsetType), int(1)))
			{
				return OwnerAI.GetWeaponAimPoseOriginOffset();
			}
			goto J0x154;
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x132
			/*@Error*/
			return OwnerAI.MeleeWeaponOffset;
		}
		goto J0x154;
		assert(__NFUN_154__(int(WeaponFireStartOffsetType), int(0)));
		return vect(0.0000000, 0.0000000, 0.0000000);
	}
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function float GetInitiateDamageTimeForAnimation(Actor tester, AIWeapon Weapon, name AttackAnimationName)
{
	local array<AnimNotify> AttackAnimationAnimNotifies;
	local float InitiateDamageTime;

	assert(__NFUN_119__(tester, none));
	tester.GetAnimationAnimNotifies(AttackAnimationName, AttackAnimationAnimNotifies, Class'ShockGame.AnimNotify_InitiateDamage');
	// End:0x89
	if(__NFUN_151__(AttackAnimationAnimNotifies.Length, 0))
	{
		InitiateDamageTime = tester.GetAnimationAnimNotifyTime(AttackAnimationName, AttackAnimationAnimNotifies[0]);
		goto J0x11B;
		AssertWithDescription(false, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("AIWeapon::GetInitiateDamageTimeForAnimation - ", string(AttackAnimationName)), " does not have any initiate damage anim notifies on "), string(tester)), "!"));
	}
	return InitiateDamageTime;
	return;
	@NULL
	CommanderAction
	Class'ShockAI.CommanderAction'
	@NULL
}

function float GetAppropriateInitiateDamageTimeForAnimation(ShockAI OwnerAI, name AnimationName)
{
	log('AI', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("Animation: ", string(AnimationName)), ", Owner: "), string(OwnerAI)), " Mesh: "), string(Mesh)), " Owner.Mesh: "), string(Owner.Mesh)));
	// End:0xCB
	if(OwnerAI.IsAnimationValid(AnimationName))
	{
		return GetInitiateDamageTimeForAnimation(OwnerAI, self, AnimationName);
		goto J0x180;
		AssertWithDescription(IsAnimationValid(AnimationName), __NFUN_112__(__NFUN_112__("AIWeapon::GetAppropriateInitiateDamageTimeForAnimation - ", string(AnimationName)), " not found on the Owner's Mesh or on the Weapon's Mesh"));
	}
	return GetInitiateDamageTimeForAnimation(self, self, AnimationName);
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function CreateAttackInfo(ShockAI OwnerAI, AttackAnimationInfo AttackAnimationInfo)
{
	local WeaponAttackInfo WeaponAttackInfo;
	local float AnimLength, FullAnimationDeltaYaw;

	WeaponAttackInfo.AIAttackAnimation = AttackAnimationInfo.AttackAnimation;
	WeaponAttackInfo.AttackRange = AttackAnimationInfo.AttackAnimationRange;
	WeaponAttackInfo.Weight = AttackAnimationInfo.Weight;
	WeaponAttackInfo.bIsCeilingAttackAnimation = AttackAnimationInfo.bIsCeilingAttackAnimation;
	WeaponAttackInfo.bCheckFullAnimationMotion = AttackAnimationInfo.bCheckFullAnimationMotion;
	WeaponAttackInfo.bUseInitiateDamageRotation = AttackAnimationInfo.bUseInitiateDamageRotation;
	WeaponAttackInfo.bPlayerOnlyAttack = AttackAnimationInfo.bPlayerOnlyAttack;
	WeaponAttackInfo.bDoNotUseForProjectedTests = AttackAnimationInfo.bDoNotUseForProjectedTests;
	WeaponAttackInfo.TimeBetweenUsageOverride = AttackAnimationInfo.TimeBetweenUsageOverride;
	// End:0x232
	if(__NFUN_254__(WeaponAttackInfo.AIAttackAnimation, 'NoAttackAnimation'))
	{
		WeaponAttackInfo.AIAttackAnimationAttackTime = 0.0000000;
		goto J0x27A;
		WeaponAttackInfo.AIAttackAnimationAttackTime = GetAppropriateInitiateDamageTimeForAnimation(OwnerAI, WeaponAttackInfo.AIAttackAnimation);
		WeaponAttackInfo.WeaponAttackOffset = GetWeaponAttackOffset(OwnerAI, AttackAnimationInfo.AttackAnimation, WeaponAttackInfo.AIAttackAnimationAttackTime, AttackAnimationInfo.SourceSocketName);
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x699
		/*@Error*/
		OwnerAI.GetAnimationAbsoluteMotion(AttackAnimationInfo.AttackAnimation, WeaponAttackInfo.AIAttackAnimationAttackTime, WeaponAttackInfo.AIAttackTranslation, WeaponAttackInfo.AIAttackDeltaYaw);
		log('AI', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(Name), " CreateAttackInfo - Owner: "), string(Owner)), " Anim: "), string(WeaponAttackInfo.AIAttackAnimation)), " Translation Size: "), string(__NFUN_225__(WeaponAttackInfo.AIAttackTranslation))));
	}
	AssertWithDescription(__NFUN_132__(__NFUN_180__(__NFUN_225__(WeaponAttackInfo.AIAttackTranslation), 0.0000000), OwnerAI.IsRootMotionUnweighted(AttackAnimationInfo.AttackAnimation)), __NFUN_112__(string(AttackAnimationInfo.AttackAnimation), " has motion but does not have the root Motion unweighted flag in the Anim Browser set to true!  Bug Shawn!"));
	AttackAnimationsTranslationRange.Max = __NFUN_245__(__NFUN_225__(WeaponAttackInfo.AIAttackTranslation), AttackAnimationsTranslationRange.Max);
	AttackAnimationsTranslationRange.Min = __NFUN_244__(__NFUN_225__(WeaponAttackInfo.AIAttackTranslation), AttackAnimationsTranslationRange.Min);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x699
	/*@Error*/
	AnimLength = OwnerAI.GetAnimationLength(AttackAnimationInfo.AttackAnimation);
	OwnerAI.GetAnimationAbsoluteMotion(AttackAnimationInfo.AttackAnimation, AnimLength, WeaponAttackInfo.FullAnimationTranslation, FullAnimationDeltaYaw);
	__NFUN_184__(TotalAttackAnimationInitiateDamageTime, WeaponAttackInfo.AIAttackAnimationAttackTime);
	AddWeaponAttackInfo(WeaponAttackInfo);
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
	@NULL
}

function AddWeaponAttackInfo(WeaponAttackInfo NewWeaponAttackInfo)
{
	WeaponAttackInfos[WeaponAttackInfos.Length] = NewWeaponAttackInfo;
	return;
	@NULL
	CommanderAction
	EcologyFighterCommanderAction
}

function bool CanHitTarget(ShockPawn Target, bool bTestUsingCurrentRotation, bool bStopAtFirstHit)
{
	//native.Target;
	//native.bTestUsingCurrentRotation;
	//native.bStopAtFirstHit;	
	@NULL
	@NULL
	return default.@NULL;
}

function float GetAverageAttackAnimationInitiateDamageTime()
{
	return AverageAttackAnimationInitiateDamageTime;
	return;
	@NULL
}

function Range GetAttackAnimationsTranslationRange()
{
	return AttackAnimationsTranslationRange;
	return;
	@NULL
}

function SetNextUsableAttackInfo(int WeaponAttackInfoTemplateIndex, Rotator FireStartRotation, ShockPawn Target)
{
	assert(__NFUN_150__(WeaponAttackInfoTemplateIndex, WeaponAttackInfos.Length));
	log('AI', 4, __NFUN_112__("Set Next Delay = ", string(WeaponAttackInfos[WeaponAttackInfoTemplateIndex].AIAttackAnimationAttackTime)));
	NextWeaponAttackInfo.AIAttackAnimation = WeaponAttackInfos[WeaponAttackInfoTemplateIndex].AIAttackAnimation;
	NextWeaponAttackInfo.AIAttackAnimationAttackTime = WeaponAttackInfos[WeaponAttackInfoTemplateIndex].AIAttackAnimationAttackTime;
	NextWeaponAttackInfo.FireStartOffset = WeaponAttackInfos[WeaponAttackInfoTemplateIndex].WeaponAttackOffset;
	NextWeaponAttackInfo.FireStartRotation = FireStartRotation;
	NextWeaponAttackInfo.Weight = WeaponAttackInfos[WeaponAttackInfoTemplateIndex].Weight;
	NextWeaponAttackInfo.Target = Target;
	NextWeaponAttackInfo.bIsValid = true;
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function InterruptCurrentAnimations(optional float TweenOutTime)
{
	Holder.PauseAnimation(HolderAnimationHandle);
	PauseAnimation(AnimationHandle);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x8E
	/*@Error*/
	Holder.FlatEaseOutAnimation(HolderAnimationHandle, TweenOutTime);
	FlatEaseOutAnimation(AnimationHandle, TweenOutTime);
	goto J0xC1;
	Holder.SmartPerTrackEaseOutAnimation(HolderAnimationHandle);
	SmartPerTrackEaseOutAnimation(AnimationHandle);
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
	@NULL
}

function name GetFiringHolderAnim(float Rate)
{
	// End:0x69
	if(__NFUN_132__(__NFUN_254__(NextWeaponAttackInfo.AIAttackAnimation, 'None'), __NFUN_254__(NextWeaponAttackInfo.AIAttackAnimation, 'NoAttackAnimation')))
	{
		return super.GetFiringHolderAnim(Rate);
		goto J0x84;
		return NextWeaponAttackInfo.AIAttackAnimation;
		return;
		@NULL
		CommanderAction
		CommanderAction
	}
	@NULL
}

function name GetAltFiringHolderAnim(float Rate)
{
	assert(false);
	return 'None';
	return;
}

function OnFiringFinished()
{
	super.OnFiringFinished();
	SetReadyToUseTime();
	return;
	@NULL
}

// Export UAIWeapon::execIsReadyToUse(FFrame&, void* const)
native function bool IsReadyToUse();

function SetReadyToUseTime()
{
	assert(Holder.__NFUN_303__('ShockAI'));
	ReadyToUseTime = RandRange(GetMinTimeBetweenUsage(), GetMaxTimeBetweenUsage());
	ReadyToUseSetTime = Level.TimeSeconds;
	log('AI', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(Name), " set it's ready to use time to "), string(__NFUN_174__(ReadyToUseTime, ReadyToUseSetTime))), " (Current Time: "), string(Level.TimeSeconds)), " )"));
	return;
	@NULL
	CommanderAction
	BioshockMovementAction
	@NULL
}

function float GetMinTimeBetweenUsage()
{
	local float MinTimeBetweenUsage;

	// End:0x8D
	if(__NFUN_130__(NextWeaponAttackInfo.bIsValid, __NFUN_177__(NextWeaponAttackInfo.TimeBetweenUsageOverride.Max, 0.0000000)))
	{
		MinTimeBetweenUsage = NextWeaponAttackInfo.TimeBetweenUsageOverride.Min;
		goto J0xA0;
		MinTimeBetweenUsage = BaseMinTimeBetweenUsage;
		return Holder.ModifyStat(string(__NFUN_112__(string(Class.Name), "MinTimeBetweenUsage_Bonus")), MinTimeBetweenUsage);
	}
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function float GetMaxTimeBetweenUsage()
{
	local float MaxTimeBetweenUsage;

	// End:0x8D
	if(__NFUN_130__(NextWeaponAttackInfo.bIsValid, __NFUN_177__(NextWeaponAttackInfo.TimeBetweenUsageOverride.Max, 0.0000000)))
	{
		MaxTimeBetweenUsage = NextWeaponAttackInfo.TimeBetweenUsageOverride.Max;
		goto J0xA0;
		MaxTimeBetweenUsage = BaseMaxTimeBetweenUsage;
		return Holder.ModifyStat(string(__NFUN_112__(string(Class.Name), "MaxTimeBetweenUsage_Bonus")), MaxTimeBetweenUsage);
	}
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function bool CanBeFocusedNow()
{
	return __NFUN_130__(__NFUN_130__(__NFUN_130__(__NFUN_129__(bHidden), bCanBeAFocus), __NFUN_114__(Base, none)), __NFUN_132__(__NFUN_119__(Mesh, none), __NFUN_119__(StaticMesh, none)));
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function string GetFocusDisplayName()
{
	return FriendlyName;
	return;
	@NULL
}

function string GetHUDMessageForFocusAttained()
{
	local string feedbackString;

	feedbackString = GetFocusDisplayName();
	// End:0x41
	if(CanBeUsedNow())
	{
		Container.ModifyHudMessage(feedbackString);
		return feedbackString;
		return;
		@NULL
	}
	CommanderAction
	CommanderAction
	@NULL
}

function bool ShouldHighlightWhenFocused()
{
	return true;
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

function bool CanBeUsedNow()
{
	local ShockPlayer thePlayer;

	thePlayer = ShockPlayer(Level.GetLocalPlayerController().Pawn);
	return __NFUN_130__(__NFUN_130__(bUseAsContainer, thePlayer.CanUseContainer(Container)), CanBeFocusedNow());
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

function bool GetRequiredPlacementForUse(out Vector WorldSpaceLocation, out Rotator WorldSpaceRotation)
{
	return false;
	return;
}

function OnUsed(Pawn Pawn)
{
	local ItemStack stack;
	local int i;
	local bool AnythingPickedUp;

	AssertWithDescription(Pawn.__NFUN_303__('ShockPlayer'), __NFUN_112__(string(Class.Name), " was used by someone other than a ShockPlayer."));
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x16E
	/*@Error*/
	// End:0xB6
	if(__NFUN_129__(Container.HasEverBeenRolled()))
	{
		Container.RollLoot(Level);
		i = 0;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x15B
		/*@Error*/
		stack = Container.GetItem(i);
	}
	// End:0x14D
	if(__NFUN_119__(stack, none))
	{
		AnythingPickedUp = __NFUN_132__(AnythingPickedUp, ShockPlayer(Pawn).AddStackToInventory(stack));
		__NFUN_163__(i);
		// [Loop Continue]
		goto J0xC1;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x16B
		/*@Error*/
		__NFUN_279__();
		goto J0x1A1;
		ShockPlayer(Pawn).OpenContainer(Container, GetCurrentMaterial());
		return;
		@NULL
		CommanderAction
		CommanderAction
	}
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

function Container GetContainer()
{
	return Container;
	return;
	@NULL
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

function bool ActionBlockedByPawns()
{
	return true;
	return;
}

function float GetUseDistance()
{
	return 0.0000000;
	return;
}

event OnTelekinesisStartedPulling(TelekinesisAbility Telekinesis)
{
	return;
}

event OnTelekinesisStartedThrowing(TelekinesisAbility Telekinesis)
{
	return;
}

event OnTelekinesisStartedHolding(TelekinesisAbility Telekinesis)
{
	return;
}

event OnTelekinesisStartedDroping(TelekinesisAbility Telekinesis)
{
	return;
}

event Actor GetAffectedActor()
{
	return self;
	return;
}

function PreTelekinesis()
{
	return;
}

function bool IsAffectedByTelekinesis()
{
	return __NFUN_130__(__NFUN_129__(bHidden), __NFUN_154__(int(Physics), int(1)));
	return;
	@NULL
	CommanderAction
}

function TakeDamage(DamageStimuliSet DamageStimuli, float CritChance, Actor Damager, Vector HitLocation, Vector HitNormal, Vector HitImpulseDirection, name EffectEventName, float DamageAttenuation, name HitHighBone, name HitLowBone, bool WasMeleeAttack)
{
	//native.DamageStimuli;
	//native.CritChance;
	//native.Damager;
	//native.HitLocation;
	//native.HitNormal;
	//native.HitImpulseDirection;
	//native.EffectEventName;
	//native.DamageAttenuation;
	//native.HitHighBone;
	//native.HitLowBone;
	//native.WasMeleeAttack;	
	@NULL
	@NULL
	return default.@NULL;
}

function TakeScriptedDamage(DamageStimuliSet.DamageStimulusType DamageType, float DamageAmount, float DamageChance, optional Actor Damager)
{
	return;
}

defaultproperties
{
	bUseCachedCanHitRotation=true
	bUseForProjectedAttackTests=true
	WeightCutoff=0.0100000
	MinTravelPercentageForFullAnimation=0.7500000
	MinTravelPercentageForAttack=0.5000000
	FriendlyName="Default AIWeapon Name"
	UseVerbText="PICK UP"
	bCanBeAFocus=true
	bUseAsContainer=true
	ShouldTreatAsAPickup=true
	AttachBone="None"
	bCastSimpleShadow=true
	bIsHavokPhysicsEventually=true
	bCastShadowMapShadow=true
}