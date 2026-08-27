class PlayerWeapon extends Weapon
	abstract
	native
	config(Weapons)
	notplaceable
	hidecategories(DrawScale3D,DisplayAdvanced);

var private config Class<WeaponModAttachment> AltFireModAttachmentClass;
var private config Class<WeaponModAttachment> StrictlySuperiorModAttachmentClass;
var private config name AltFireModAttachmentSocket;
var private config name StrictlySuperiorModAttachmentSocket;
var private travel WeaponModAttachment AltFireModAttachment;
var private travel WeaponModAttachment StrictlySuperiorModAttachment;
var private config travel name IdlingAltFireAttachmentAnim;
var private config travel name IdlingStrictlySuperiorAttachmentAnim;
var private config travel name EmptyIdlingHandsAnim;
var config bool CanBeZoomed;
var config float ZoomedFOVAngle;
var config float ZoomedForegroundFOVAngle;
var bool ZoomedFiring;
var private config name ZoomingInHandsAnim;
var private config name ZoomingOutHandsAnim;
var private config name ZoomedIdlingHandsAnim;
var config array<AnimRateRange> ZoomedFiringHandsAnim;
var config array<AnimRateRange> ZoomedFiringAnim;
var config array<AnimRateRange> ZoomedFiringAltFireAttachmentAnim;
var config array<AnimRateRange> ZoomedFiringStrictlySuperiorAttachmentAnim;
var bool ReleasedFiringTrigger;
var bool ReleasedPendingFiringTrigger;
var private config bool WaitForFireReleaseTrigger;
var private config bool ShouldUseThreePartReloading;
var config array<AnimRateRange> LoopFiringAltFireAttachmentAnim;
var config array<AnimRateRange> LoopFiringStrictlySuperiorAttachmentAnim;
var config array<AnimRateRange> LoopFiringHandsAnim;
var config array<AnimRateRange> LoopFiringHolderAnim;
var config array<AnimRateRange> LoopFiringAnim;
var config array<AnimRateRange> FinishFiringAltFireAttachmentAnim;
var config array<AnimRateRange> FinishFiringStrictlySuperiorAttachmentAnim;
var config array<AnimRateRange> FinishFiringHandsAnim;
var config array<AnimRateRange> FinishFiringHolderAnim;
var config array<AnimRateRange> FinishFiringAnim;
var config array<AnimRateRange> ReloadingEmptyWeaponAltFireAttachmentAnim;
var config array<AnimRateRange> ReloadingEmptyWeaponStrictlySuperiorAttachmentAnim;
var config array<AnimRateRange> ReloadingEmptyWeaponHandsAnim;
var config array<AnimRateRange> ReloadingNotEmptyWeaponAltFireAttachmentAnim;
var config array<AnimRateRange> ReloadingNotEmptyWeaponStrictlySuperiorAttachmentAnim;
var config array<AnimRateRange> ReloadingNotEmptyWeaponHandsAnim;
var config array<AnimRateRange> ReloadingLoopAltFireAttachmentAnim;
var config array<AnimRateRange> ReloadingLoopStrictlySuperiorAttachmentAnim;
var config array<AnimRateRange> ReloadingLoopHandsAnim;
var config array<AnimRateRange> ReloadingLoopHolderAnim;
var config array<AnimRateRange> ReloadingLoopAnim;
var config array<AnimRateRange> ReloadingFinishAltFireAttachmentAnim;
var config array<AnimRateRange> ReloadingFinishStrictlySuperiorAttachmentAnim;
var config array<AnimRateRange> ReloadingFinishHandsAnim;
var config array<AnimRateRange> ReloadingFinishHolderAnim;
var config array<AnimRateRange> ReloadingFinishAnim;
var config array<AnimRateRange> FiringAltFireAttachmentAnim;
var config array<AnimRateRange> FiringStrictlySuperiorAttachmentAnim;
var config array<AnimRateRange> FiringHandsAnim;
var config array<AnimRateRange> FiringFinalShotAltFireAttachmentAnim;
var config array<AnimRateRange> FiringFinalShotStrictlySuperiorAttachmentAnim;
var config array<AnimRateRange> FiringFinalShotHandsAnim;
var config array<AnimRateRange> ZoomedFiringFinalShotAltFireAttachmentAnim;
var config array<AnimRateRange> ZoomedFiringFinalShotStrictlySuperiorAttachmentAnim;
var config array<AnimRateRange> ZoomedFiringFinalShotHandsAnim;
var config array<AnimRateRange> ZoomedFiringFinalShotAnim;
var config array<AnimRateRange> FiringEmptyShotAltFireAttachmentAnim;
var config array<AnimRateRange> FiringEmptyShotStrictlySuperiorAttachmentAnim;
var config array<AnimRateRange> FiringEmptyShotHandsAnim;
var int HandsAnimationHandle;
var int AltFireAttachmentAnimationHandle;
var int StrictlySuperiorAttachmentAnimationHandle;
var private travel Class<Ammunition> LastAmmoSelection;
var const config float PendingFireDelayTime;
var float PendingFirePressedTime;
var bool PendingAltFire;
var bool PendingCeaseAltFire;
var config float InitialInaccuracyPercent;
var config float InaccuracyPenaltyPerRoundSpent;

function PostBeginPlay()
{
	local int i;
	local ShockPlayer thePlayer;

	super.PostBeginPlay();
	// End:0xAA
	if(__NFUN_255__(AltFireModAttachmentSocket, 'None'))
	{
		AltFireModAttachment = __NFUN_278__(AltFireModAttachmentClass);
		assert(__NFUN_119__(AltFireModAttachment, none));
		AttachToBone(AltFireModAttachment, AltFireModAttachmentSocket);
		AltFireModAttachment.DrawPriority = 1;
		AltFireModAttachment.UpdateRenderRevision();
		AltFireModAttachment.SetHidden(true);
		// End:0x15B
		if(__NFUN_130__(__NFUN_255__(StrictlySuperiorModAttachmentSocket, 'None'), __NFUN_119__(StrictlySuperiorModAttachmentClass, none)))
		{
			StrictlySuperiorModAttachment = __NFUN_278__(StrictlySuperiorModAttachmentClass);
			assert(__NFUN_119__(StrictlySuperiorModAttachment, none));
		}
		AttachToBone(StrictlySuperiorModAttachment, StrictlySuperiorModAttachmentSocket);
		StrictlySuperiorModAttachment.DrawPriority = 1;
		StrictlySuperiorModAttachment.UpdateRenderRevision();
		StrictlySuperiorModAttachment.SetHidden(true);
		thePlayer = ShockPlayer(Level.GetLocalPlayerController().Pawn);
		i = 0;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x2E3
		/*@Error*/
		UpgradeStats[i] = Class'ShockGame.UpgradeableWeaponStat'.static.Allocate(self,, string(UpgradeStatName[i])).;
		Construct_Void();
	}
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x2D5
	/*@Error*/
	UpgradeStats[i].PointsAllocated = 1;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x2CB
	/*@Error*/
	GiveAltFireMod();
	goto J0x2D5;
	GiveStrictlySuperiorMod();
	__NFUN_165__(i);
	// [Loop Continue]
	goto J0x19D;
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function TravelPostAccept()
{
	super(Actor).TravelPostAccept();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x2C
	/*@Error*/
	CurrentAmmoSelection = LastAmmoSelection;
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function PostLoadGame()
{
	super(Actor).PostLoadGame();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x2C
	/*@Error*/
	CurrentAmmoSelection = LastAmmoSelection;
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function name GetIdlingAltFireAttachmentAnim()
{
	return IdlingAltFireAttachmentAnim;
	return;
	@NULL
}

function name GetIdlingStrictlySuperiorAttachmentAnim()
{
	return IdlingStrictlySuperiorAttachmentAnim;
	return;
	@NULL
}

function float GetIdlingHandsAnimTweenTime()
{
	// End:0x14
	if(IsEmpty(false))
	{
		return 0.2000000;
	}
	return super(Holdable).GetIdlingHandsAnimTweenTime();
	return;
	@NULL
}

function name GetIdlingHandsAnim()
{
	// End:0x18
	if(IsEmpty(false))
	{
		return EmptyIdlingHandsAnim;
		return super(Holdable).GetIdlingHandsAnim();
	}
	return;
	@NULL
	Item
}

function name GetZoomingInHandsAnim()
{
	return ZoomingInHandsAnim;
	return;
	@NULL
}

function name GetZoomingOutHandsAnim()
{
	return ZoomingOutHandsAnim;
	return;
	@NULL
}

function name GetZoomedIdlingHandsAnim()
{
	return ZoomedIdlingHandsAnim;
	return;
	@NULL
}

function BeginFiring(optional bool inAltFire)
{
	local bool weaponIsEmpty;

	weaponIsEmpty = IsEmpty(false);
	assert(Holder.__NFUN_303__('ShockPlayer'));
	ShockPlayer(Holder).dispatchMessage(Class'ShockGame.MessagePlayerFiredWeapon'.static.Allocate(self)., construct_WeaponClassBool(self, CurrentAmmoSelection, weaponIsEmpty));
	PendingFirePressedTime = 0.0000000;
	// End:0x14A
	if(weaponIsEmpty)
	{
		// End:0xDC
		if(__NFUN_151__(Holder.GetNumberOfItems(CurrentAmmoSelection), 0))
		{
			Reload();
			goto J0x147;
			ShockPlayerController(Holder.Controller).GetPlayerStatsManager().DryFire();
		}
		TriggerEffectEvent('DryFiring',,,,,,,, CurrentAmmoSelection.Name);
		goto J0x193;
		Holder.Controller.bHoldingFireWeapon = 0;
		ReleasedFiringTrigger = false;
		Hands.FireWeapon();
		return;
		@NULL
		Item
	}
	Item
	@NULL
}

function PendingFire(optional bool inAltFire)
{
	PendingFirePressedTime = Level.TimeSeconds;
	PendingAltFire = inAltFire;
	ReleasedPendingFiringTrigger = false;
	return;
	@NULL
	Item
	Item
	@NULL
}

function CeaseFiring(optional bool AltFire, optional bool bInterruptBurst)
{
	super.CeaseFiring(AltFire, bInterruptBurst);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x4C
	/*@Error*/
	PendingCeaseAltFire = AltFire;
	ReleasedPendingFiringTrigger = true;
	ReleasedFiringTrigger = true;
	return;
	@NULL
	Item
	Item
	@NULL
}

function Reload()
{
	// End:0x11
	if(__NFUN_129__(UsesAmmo()))
	{
		return;
	}
	// End:0x8C
	if(__NFUN_132__(__NFUN_119__(CurrentAmmoSelection, PendingAmmoSelection), __NFUN_130__(__NFUN_155__(RoundsRemaining, GetMagazineSize()), __NFUN_155__(RoundsRemaining, Holder.GetNumberOfItems(PendingAmmoSelection)))))
	{
		Hands.ReloadWeapon();
		goto J0x138;
		assert(Holder.__NFUN_303__('ShockPlayer'));
		Level.GetFlashGUIController().GetPlayingMovie('HUD').CallMethodString("SelectAmmo", string(CurrentAmmoSelection.Name));
	}
	TriggerEffectEvent('DryReloading',,,,,,,, CurrentAmmoSelection.Name);
	return;
	@NULL
	Item
	Item
	@NULL
}

function PostFired()
{
	// End:0x1B
	if(IsEmpty(false))
	{
		Reload();		
	}
	else
	{
		// End:0xF0
		if(__NFUN_130__(CanPendingFire, __NFUN_177__(__NFUN_174__(PendingFirePressedTime, PendingFireDelayTime), Level.TimeSeconds)))
		{
			PendingFirePressedTime = 0.0000000;
			log('Weapons', 3, __NFUN_112__(__NFUN_112__(string(self), " is trying to Pending Firing "), string(self)));
			// End:0xD9
			if(ReleasedPendingFiringTrigger)
			{
				BeginFiring(PendingAltFire);
				CeaseFiring(PendingCeaseAltFire);
				goto J0xED;
				BeginFiring(PendingAltFire);
				goto J0x161;
				/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
					
				*/

				// End:0x161
				/*@Error*/
			}
			Holder.Controller.bHoldingFireWeapon = 0;
		}
		BeginFiring(PendingAltFire);
		return;
		@NULL
		Item
		Item
		@NULL
	}
}

function OnFiringInterrupted()
{
	UnTriggerEffectEvent('Fired', CurrentAmmoSelection.Name);
	UnTriggerEffectEvent('IsFiring', CurrentAmmoSelection.Name);
	// End:0x78
	if(__NFUN_119__(CurrentDamageEmitter, none))
	{
		CurrentDamageEmitter.Kill();
		StopAnimation(AnimationHandle);
		super.OnFiringInterrupted();
		return;
		@NULL
	}
	Item
	stop;
	default.@NULL
}

function OnEquippingFinished()
{
	super.OnEquippingFinished();
	__NFUN_280__(0.0010000, false);
	return;
	@NULL
}

function Timer()
{
	// End:0x45
	if(__NFUN_132__(IsEmpty(false), __NFUN_130__(__NFUN_119__(PendingAmmoSelection, none), __NFUN_119__(PendingAmmoSelection, CurrentAmmoSelection))))
	{
		Reload();
		goto J0x18B;
		// End:0x11A
		if(__NFUN_130__(CanPendingFire, __NFUN_177__(__NFUN_174__(PendingFirePressedTime, PendingFireDelayTime), Level.TimeSeconds)))
		{
		}
		PendingFirePressedTime = 0.0000000;
		log('Weapons', 3, __NFUN_112__(__NFUN_112__(string(self), " is trying to Pending Firing "), string(self)));
		// End:0x103
		if(ReleasedPendingFiringTrigger)
		{
			BeginFiring(PendingAltFire);
			CeaseFiring(PendingCeaseAltFire);
			goto J0x117;
			BeginFiring(PendingAltFire);
			goto J0x18B;
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x18B
			/*@Error*/
		}
		Holder.Controller.bHoldingFireWeapon = 0;
	}
	BeginFiring(PendingAltFire);
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function OnReloadingFinished()
{
	super.OnReloadingFinished();
	// End:0xDF
	if(__NFUN_130__(CanPendingFire, __NFUN_177__(__NFUN_174__(PendingFirePressedTime, PendingFireDelayTime), Level.TimeSeconds)))
	{
		PendingFirePressedTime = 0.0000000;
		log('Weapons', 3, __NFUN_112__(__NFUN_112__(string(self), " is trying to Pending Firing "), string(self)));
		// End:0xC8
		if(ReleasedPendingFiringTrigger)
		{
			BeginFiring(PendingAltFire);
			CeaseFiring(PendingCeaseAltFire);
			goto J0xDC;
			BeginFiring(PendingAltFire);
			goto J0x150;
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x150
			/*@Error*/
		}
		Holder.Controller.bHoldingFireWeapon = 0;
	}
	BeginFiring(PendingAltFire);
	return;
	@NULL
	Item
	Item
	@NULL
}

function PlayWeaponAnimations(optional name HandsAnim, optional name WeaponAnim, optional name HolderAnim, optional name AltFireAttachmentAnim, optional name StrictlySuperiorAttachmentAnim, optional float Rate, optional int AnimationEndBehavior, optional float EaseInTime)
{
	ShockPlayerController(Holder.Controller).SetCameraAnimationRateChangeModifier(Rate);
	super.PlayWeaponAnimations(HandsAnim, WeaponAnim, HolderAnim, AltFireAttachmentAnim, StrictlySuperiorAttachmentAnim, Rate, AnimationEndBehavior, EaseInTime);
	// End:0xA3
	if(__NFUN_154__(AnimationEndBehavior, 0))
	{
		AnimationEndBehavior = 4;
		// End:0x13D
		if(__NFUN_119__(Hands, none))
		{
			HandsAnimationHandle = Hands.PlayAnimationOnChannelFlatEaseIn(0, HandsAnim, EaseInTime, AnimationEndBehavior);
			Hands.SetAnimationPlaybackRate(HandsAnimationHandle, __NFUN_171__(Rate, Hands.GetAnimationPlaybackRate(HandsAnimationHandle)));
		}
		goto J0x148;
		HandsAnimationHandle = 0;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x1FD
		/*@Error*/
		AltFireAttachmentAnimationHandle = AltFireModAttachment.PlayAnimationOnChannelFlatEaseIn(0, AltFireAttachmentAnim, EaseInTime, AnimationEndBehavior);
		AltFireModAttachment.SetAnimationPlaybackRate(AltFireAttachmentAnimationHandle, __NFUN_171__(Rate, AltFireModAttachment.GetAnimationPlaybackRate(AltFireAttachmentAnimationHandle)));
	}
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x2B2
	/*@Error*/
	StrictlySuperiorAttachmentAnimationHandle = StrictlySuperiorModAttachment.PlayAnimationOnChannelFlatEaseIn(0, StrictlySuperiorAttachmentAnim, EaseInTime, AnimationEndBehavior);
	StrictlySuperiorModAttachment.SetAnimationPlaybackRate(StrictlySuperiorAttachmentAnimationHandle, __NFUN_171__(Rate, StrictlySuperiorModAttachment.GetAnimationPlaybackRate(StrictlySuperiorAttachmentAnimationHandle)));
	return;
	@NULL
	Collectable
	Item
	@NULL
}

function FinishAnimations()
{
	super.FinishAnimations();
	// End:0x39
	if(__NFUN_119__(Hands, none))
	{
		Hands.FinishAnimation(HandsAnimationHandle);
		// End:0x86
		if(__NFUN_130__(__NFUN_119__(AltFireModAttachment, none), __NFUN_129__(AltFireModAttachment.bHidden)))
		{
		}
		AltFireModAttachment.FinishAnimation(AltFireAttachmentAnimationHandle);
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0xD3
		/*@Error*/
		StrictlySuperiorModAttachment.FinishAnimation(StrictlySuperiorAttachmentAnimationHandle);
	}
	ShockPlayerController(Holder.Controller).ClearCameraAnimationRateChangeModifier();
	return;
	@NULL
	Collectable
	Item
	@NULL
}

function InterruptCurrentAnimations(optional float TweenOutTime)
{
	super.InterruptCurrentAnimations(TweenOutTime);
	// End:0x10D
	if(__NFUN_177__(TweenOutTime, 0.0000000))
	{
		// End:0x5E
		if(__NFUN_119__(Hands, none))
		{
			Hands.FlatEaseOutAnimation(HandsAnimationHandle, TweenOutTime);
			// End:0xB4
			if(__NFUN_130__(__NFUN_119__(AltFireModAttachment, none), __NFUN_129__(AltFireModAttachment.bHidden)))
			{
			}
			AltFireModAttachment.FlatEaseOutAnimation(AltFireAttachmentAnimationHandle, TweenOutTime);
			// End:0x10A
			if(__NFUN_130__(__NFUN_119__(StrictlySuperiorModAttachment, none), __NFUN_129__(StrictlySuperiorModAttachment.bHidden)))
			{
				StrictlySuperiorModAttachment.FlatEaseOutAnimation(StrictlySuperiorAttachmentAnimationHandle, TweenOutTime);
				goto J0x1D6;
			}
			// End:0x13C
			if(__NFUN_119__(Hands, none))
			{
				Hands.StopAnimation(HandsAnimationHandle);
				/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
					
				*/

				// End:0x189
				/*@Error*/
				AltFireModAttachment.StopAnimation(AltFireAttachmentAnimationHandle);
				/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
					
				*/

				// End:0x1D6
				/*@Error*/
			}
		}
		StrictlySuperiorModAttachment.StopAnimation(StrictlySuperiorAttachmentAnimationHandle);
	}
	return;
	@NULL
	Item
	DifficultyAdjustment
	@NULL
}

function GetCurrentAnimationNames(out name HolderAnimationName, out name HandsAnimationName, out name WeaponAnimationName)
{
	super.GetCurrentAnimationNames(HolderAnimationName, HandsAnimationName, WeaponAnimationName);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x5E
	/*@Error*/
	HandsAnimationName = Hands.GetAnimationName(HandsAnimationHandle);
	return;
	@NULL
	Item
	DifficultyAdjustment
	@NULL
}

function PlayIdleAnimations()
{
	super.PlayIdleAnimations();
	// End:0x5B
	if(__NFUN_130__(__NFUN_119__(AltFireModAttachment, none), __NFUN_129__(AltFireModAttachment.bHidden)))
	{
		AltFireModAttachment.PlayAnimationOnChannel(0, GetIdlingAltFireAttachmentAnim(), 8);
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0xAC
		/*@Error*/
	}
	StrictlySuperiorModAttachment.PlayAnimationOnChannel(0, GetIdlingStrictlySuperiorAttachmentAnim(), 8);
	return;
	@NULL
	Item
	Item
	@NULL
}

latent function OnReleasedFiring()
{
	return;
}

function PlayWeaponFiringAnimations()
{
	local bool TriggeredIsFiring, FiredOnce;
	local int numRoundsFired;

	OnFiringStarted();
	log(,, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(self), "::PlayWeaponFiringAnimations() ... BurstShotsRemaining = "), string(BurstShotsRemaining)), ", RoundsRemaining = "), string(RoundsRemaining)));
	// End:0x137
	if(__NFUN_114__(CurrentAmmoSelection, none))
	{
		AssertWithDescription(false, __NFUN_112__(__NFUN_112__("CurrentAmmmoSelection was NULL when PlayWeaponFiringAnimations() was called for weapon '", string(self)), "'.  Please STOP and contact a programmer immediately."));
		return;
		// End:0x183
		if(__NFUN_129__(IsEmpty(false)))
		{
		}
		TriggerEffectEvent('IsFiring',,,,,,,, CurrentAmmoSelection.Name);
		TriggeredIsFiring = true;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x905
		/*@Error*/
	}
	FiredOnce = true;
	// End:0x1E9
	if(__NFUN_151__(BurstShotsRemaining, 0))
	{
		__NFUN_166__(BurstShotsRemaining);
		// End:0x25E
		if(bFullAuto)
		{
			ShockPlayerController(Holder.Controller).KickbackAlpha = __NFUN_246__(__NFUN_174__(InitialInaccuracyPercent, __NFUN_171__(float(numRoundsFired), InaccuracyPenaltyPerRoundSpent)), 0.0000000, 1.0000000);
		}
		__NFUN_165__(numRoundsFired);
		goto J0x290;
		ShockPlayerController(Holder.Controller).KickbackAlpha = 1.0000000;
		CurrentFireRate = GetFireRate();
		// End:0x38E
		if(IsEmpty(false))
		{
			TriggerEffectEvent('DryFiring',,,,,,,, CurrentAmmoSelection.Name);
		}
		PlayWeaponAnimations(GetAnimationForRate(CurrentFireRate, FiringEmptyShotHandsAnim), GetAnimationForRate(CurrentFireRate, FiringEmptyShotAnim), GetAnimationForRate(CurrentFireRate, FiringEmptyShotHolderAnim), GetAnimationForRate(CurrentFireRate, FiringEmptyShotAltFireAttachmentAnim), GetAnimationForRate(CurrentFireRate, FiringEmptyShotStrictlySuperiorAttachmentAnim), CurrentFireRate);
		FinishAnimations();
		goto J0x905;
		// End:0x504
		if(__NFUN_130__(__NFUN_151__(RoundsRemaining, 0), __NFUN_150__(RoundsRemaining, __NFUN_144__(2, GetNumRoundsToUse(false)))))
		{
			// End:0x462
			if(ZoomedFiring)
			{
				PlayWeaponAnimations(GetAnimationForRate(CurrentFireRate, ZoomedFiringFinalShotHandsAnim), GetAnimationForRate(CurrentFireRate, ZoomedFiringFinalShotAnim), GetFiringHolderAnim(CurrentFireRate), GetAnimationForRate(CurrentFireRate, ZoomedFiringFinalShotAltFireAttachmentAnim), GetAnimationForRate(CurrentFireRate, ZoomedFiringFinalShotStrictlySuperiorAttachmentAnim), CurrentFireRate);
				goto J0x501;
				PlayWeaponAnimations(GetAnimationForRate(CurrentFireRate, FiringFinalShotHandsAnim), GetAnimationForRate(CurrentFireRate, FiringFinalShotAnim), GetAnimationForRate(CurrentFireRate, FiringFinalShotHolderAnim), GetAnimationForRate(CurrentFireRate, FiringFinalShotAltFireAttachmentAnim), GetAnimationForRate(CurrentFireRate, FiringFinalShotStrictlySuperiorAttachmentAnim), CurrentFireRate);
			}
			goto J0x640;
			// End:0x5AA
			if(ZoomedFiring)
			{
				PlayWeaponAnimations(GetAnimationForRate(CurrentFireRate, ZoomedFiringHandsAnim), GetAnimationForRate(CurrentFireRate, ZoomedFiringAnim), GetFiringHolderAnim(CurrentFireRate), GetAnimationForRate(CurrentFireRate, ZoomedFiringAltFireAttachmentAnim), GetAnimationForRate(CurrentFireRate, ZoomedFiringStrictlySuperiorAttachmentAnim), CurrentFireRate);
			}
			goto J0x640;
			PlayWeaponAnimations(GetAnimationForRate(CurrentFireRate, FiringHandsAnim), GetAnimationForRate(CurrentFireRate, FiringAnim), GetFiringHolderAnim(CurrentFireRate), GetAnimationForRate(CurrentFireRate, FiringAltFireAttachmentAnim), GetAnimationForRate(CurrentFireRate, FiringStrictlySuperiorAttachmentAnim), CurrentFireRate);
			TriggerEffectEvent('Fired',,, Location, Rotation,,,, CurrentAmmoSelection.Name);
		}
		TriggerEffectEvent('FiredSound',,, Location, Rotation,,,, CurrentAmmoSelection.Name);
		RunOnFiredEmitters(CurrentAmmoSelection.Name);
		UseAmmo(false);
		FinishAnimations();
		PlayWeaponAnimations(GetAnimationForRate(CurrentFireRate, LoopFiringHandsAnim), GetAnimationForRate(CurrentFireRate, LoopFiringAnim), GetAnimationForRate(CurrentFireRate, LoopFiringHolderAnim), GetAnimationForRate(CurrentFireRate, LoopFiringAltFireAttachmentAnim), GetAnimationForRate(CurrentFireRate, LoopFiringStrictlySuperiorAttachmentAnim), CurrentFireRate, 8);
	}
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x809
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x7C4
	/*@Error*/
	CeaseFiring();
	goto J0x806;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x806
	/*@Error*/
	UseAmmo(false);
	__NFUN_256__(GetAmmoConsumptionRate());
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x803
	/*@Error*/
	CeaseFiring();
	goto J0x7C4;
	goto J0x83A;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x83A
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x830
	/*@Error*/
	__NFUN_256__(0.0100000);
	goto J0x816;
	OnReleasedFiring();
	UnTriggerEffectEvent('Fired', CurrentAmmoSelection.Name);
	PlayAndFinishHandAndWeaponAnimations(GetAnimationForRate(CurrentFireRate, FinishFiringHandsAnim), GetAnimationForRate(CurrentFireRate, FinishFiringAnim), GetAnimationForRate(CurrentFireRate, FinishFiringHolderAnim), GetAnimationForRate(CurrentFireRate, FinishFiringAltFireAttachmentAnim), GetAnimationForRate(CurrentFireRate, FinishFiringStrictlySuperiorAttachmentAnim), CurrentFireRate);
	// [Loop Continue]
	goto J0x183;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x93B
	/*@Error*/
	UnTriggerEffectEvent('IsFiring', CurrentAmmoSelection.Name);
	OnFiringFinished();
	return;
	@NULL
	Collectable
	Item
	@NULL
}

function PlayReloadingAnimations(optional float EaseInTime)
{
	local bool bIsEmpty;


	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x557
	/*@Error*/
	AddPersistentContext(string(__NFUN_112__("PendingAmmo_", string(PendingAmmoSelection.Name))));
	bIsEmpty = IsEmpty(false);
	LastAmmoSelection = CurrentAmmoSelection;
	// End:0xD5
	if(__NFUN_130__(ShouldUseThreePartReloading, __NFUN_119__(PendingAmmoSelection, CurrentAmmoSelection)))
	{
		RoundsRemaining = 0;
		LastAmmoSelection = PendingAmmoSelection;
		CurrentAmmoSelection = none;
		CurrentReloadRate = GetReloadRate();
		// End:0x1AD
		if(bIsEmpty)
		{
			PlayWeaponAnimations(GetAnimationForRate(CurrentReloadRate, ReloadingEmptyWeaponHandsAnim), GetAnimationForRate(CurrentReloadRate, ReloadingEmptyWeaponAnim), GetAnimationForRate(CurrentReloadRate, ReloadingEmptyWeaponHolderAnim), GetAnimationForRate(CurrentReloadRate, ReloadingEmptyWeaponAltFireAttachmentAnim), GetAnimationForRate(CurrentReloadRate, ReloadingEmptyWeaponStrictlySuperiorAttachmentAnim), CurrentReloadRate,, EaseInTime);
		}
		goto J0x256;
		PlayWeaponAnimations(GetAnimationForRate(CurrentReloadRate, ReloadingNotEmptyWeaponHandsAnim), GetAnimationForRate(CurrentReloadRate, ReloadingNotEmptyWeaponAnim), GetAnimationForRate(CurrentReloadRate, ReloadingNotEmptyWeaponHolderAnim), GetAnimationForRate(CurrentReloadRate, ReloadingNotEmptyWeaponAltFireAttachmentAnim), GetAnimationForRate(CurrentReloadRate, ReloadingNotEmptyWeaponStrictlySuperiorAttachmentAnim), CurrentReloadRate,, EaseInTime);
	}
	FinishAnimations();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x54D
	/*@Error*/
	log('Weapons', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(self), "::PlayReloadingAnimations().... ShouldUseThreePartReloading ... RoundsRemaining = "), string(RoundsRemaining)), ", GetMagazineSize() = "), string(GetMagazineSize())), ", PendingAmmoSelection = "), string(PendingAmmoSelection)), ", Holder.HasAmmoRemaining( PendingAmmoSelection ) = "), string(Holder.HasAmmoRemaining(PendingAmmoSelection))));
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x49E
	/*@Error*/
	PlayWeaponAnimations(GetAnimationForRate(CurrentReloadRate, ReloadingLoopHandsAnim), GetAnimationForRate(CurrentReloadRate, ReloadingLoopAnim), GetAnimationForRate(CurrentReloadRate, ReloadingLoopHolderAnim), GetAnimationForRate(CurrentReloadRate, ReloadingLoopAltFireAttachmentAnim), GetAnimationForRate(CurrentReloadRate, ReloadingLoopStrictlySuperiorAttachmentAnim), CurrentReloadRate,, 0.0000000);
	FinishAnimations();
	SetCurrentAmmoSelection(PendingAmmoSelection);
	// [Loop Continue]
	goto J0x391;
	PlayWeaponAnimations(GetAnimationForRate(CurrentReloadRate, ReloadingFinishHandsAnim), GetAnimationForRate(CurrentReloadRate, ReloadingFinishAnim), GetAnimationForRate(CurrentReloadRate, ReloadingFinishHolderAnim), GetAnimationForRate(CurrentReloadRate, ReloadingFinishAltFireAttachmentAnim), GetAnimationForRate(CurrentReloadRate, ReloadingFinishStrictlySuperiorAttachmentAnim), CurrentReloadRate,, 0.0000000);
	FinishAnimations();
	RemovePersistentAmmoContexts();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x579
	/*@Error*/
	SetCurrentAmmoSelection(PendingAmmoSelection);
	return;
	@NULL
	Collectable
	Item
	@NULL
}

function OnReloadInterrupted()
{
	RemovePersistentAmmoContexts();
	CurrentAmmoSelection = LastAmmoSelection;
	return;
	@NULL
	Item
}

function RemovePersistentAmmoContexts()
{
	local int i;

	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x6F
	/*@Error*/
	RemovePersistentContext(string(__NFUN_112__("PendingAmmo_", string(AvailableAmmoTypes[i].Name))));
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x0B;
	return;
	@NULL
	Item
	ShockPawn
	@NULL
}

function HideWeapon(bool Hide)
{
	super.HideWeapon(Hide);
	Hands.SetHidden(Hide);
	// End:0x81
	if(__NFUN_130__(__NFUN_119__(AltFireModAttachment, none), AltFireModAttachment.bGiven))
	{
		AltFireModAttachment.SetHidden(Hide);
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0xCD
		/*@Error*/
		StrictlySuperiorModAttachment.SetHidden(Hide);
	}
	return;
	@NULL
	Item
	DifficultyAdjustment
	@NULL
}

function UseAmmo(bool inAltFiring)
{
	local int NumRoundsUsed;


	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0xB3
	/*@Error*/
	NumRoundsUsed = GetNumRoundsToUse(inAltFiring);
	// End:0x77
	if(__NFUN_151__(RoundsRemaining, 0))
	{
		__NFUN_162__(RoundsRemaining, NumRoundsUsed);
		Holder.UseUpItem(CurrentAmmoSelection, NumRoundsUsed);
		assert(Holder.__NFUN_303__('ShockPlayer'));
		ShockPlayer(Holder).ResetUICurrentAmmo();
	}
	return;
	@NULL
	Item
	DifficultyAdjustment
	@NULL
}

function SetCurrentAmmoSelection(Class<Ammunition> AmmoClass)
{
	local int amountToRefill;

	// End:0x22
	if(__NFUN_114__(CurrentAmmoSelection, none))
	{
		CurrentAmmoSelection = LastAmmoSelection;
		// End:0x4F
		if(UsesAmmo())
		{
		}
		Holder.ReleaseAmmunition(CurrentAmmoSelection);
		// End:0xA1
		if(__NFUN_119__(CurrentAmmoSelection, AmmoClass))
		{
			ShockPlayerController(Holder.Controller).GetPlayerStatsManager().PlayerChangedAmmo();
		}
		UnTriggerEffectEvent('EquipAmmo', CurrentAmmoSelection.Name);
		TriggerEffectEvent('UnequipAmmo',,,,,,,, CurrentAmmoSelection.Name);
	}
	// End:0x17A
	if(HasAltFireMod())
	{
		AltFireModAttachment.UnTriggerEffectEvent('EquipAmmo', CurrentAmmoSelection.Name);
		AltFireModAttachment.TriggerEffectEvent('UnequipAmmo',,,,,,,, CurrentAmmoSelection.Name);
		// End:0x1FA
		if(HasStrictlySuperiorMod())
		{
			StrictlySuperiorModAttachment.UnTriggerEffectEvent('EquipAmmo', CurrentAmmoSelection.Name);
			StrictlySuperiorModAttachment.TriggerEffectEvent('UnequipAmmo',,,,,,,, CurrentAmmoSelection.Name);
		}
		CurrentAmmoSelection = AmmoClass;
		TriggerEffectEvent('EquipAmmo',,,,,,,, CurrentAmmoSelection.Name);
		// End:0x287
		if(HasAltFireMod())
		{
			AltFireModAttachment.TriggerEffectEvent('EquipAmmo',,,,,,,, CurrentAmmoSelection.Name);
		}
		// End:0x2D1
		if(HasStrictlySuperiorMod())
		{
			StrictlySuperiorModAttachment.TriggerEffectEvent('EquipAmmo',,,,,,,, CurrentAmmoSelection.Name);
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x34D
			/*@Error*/
			Level.GetFlashGUIController().GetPlayingMovie('HUD').CallMethodString("SelectAmmo", string(CurrentAmmoSelection.Name));
		}
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x3EA
		/*@Error*/
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x380
		/*@Error*/
		amountToRefill = __NFUN_146__(RoundsRemaining, 1);
		goto J0x394;
		amountToRefill = GetMagazineSize();
	}
	RoundsRemaining = Holder.FillWeaponClipWithAvailableAmmunition(CurrentAmmoSelection, amountToRefill);
	ShockPlayer(Holder).ResetUIHyposAndAmmos();
	goto J0x3F9;
	RoundsRemaining = -1;
	return;
	@NULL
	Item
	Item
	@NULL
}

function GiveAltFireMod()
{
	UnTriggerEffectEvent('UnHidden');
	log('Weapons', 4, __NFUN_112__(string(self), "::GiveAltFireMod()"));
	AssertWithDescription(__NFUN_119__(AltFireModAttachment, none), __NFUN_112__(__NFUN_112__("Attempted to apply the Alt Fire weapon mod for weapon ", string(self)), ", but there is no corresponding attachment."));
	AltFireModAttachment.SetHidden(false);
	AltFireModAttachment.bGiven = true;
	AltFireModAttachment.FadeInDuration = AltFireModAttachment.Class.default.FadeInDuration;
	AltFireModAttachment.PlayAnimationOnChannel(0, GetIdlingAltFireAttachmentAnim(), 8);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x1EC
	/*@Error*/
	Holder.TriggerEffectEvent('AppliedAltFireMod',,,,,,,, Class.Name);
	AltFireModAttachment.TriggerEffectEvent('AppliedAltFireMod',,,,,,,, Class.Name);
	RespawnOnFiredEmitters();
	RespawnTracerEmitters();
	TriggerEffectEvent('UnHidden');
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function GiveStrictlySuperiorMod()
{
	UnTriggerEffectEvent('UnHidden');
	AssertWithDescription(__NFUN_119__(StrictlySuperiorModAttachment, none), __NFUN_112__(__NFUN_112__("Attempted to apply the Strictly Superior weapon mod for weapon ", string(self)), ", but there is no corresponding attachment."));
	StrictlySuperiorModAttachment.SetHidden(false);
	StrictlySuperiorModAttachment.bGiven = true;
	StrictlySuperiorModAttachment.FadeInDuration = StrictlySuperiorModAttachment.Class.default.FadeInDuration;
	StrictlySuperiorModAttachment.PlayAnimationOnChannel(0, GetIdlingStrictlySuperiorAttachmentAnim(), 8);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x1CC
	/*@Error*/
	Holder.TriggerEffectEvent('AppliedStrictlySuperiorMod',,,,,,,, Class.Name);
	StrictlySuperiorModAttachment.TriggerEffectEvent('AppliedStrictlySuperiorMod',,,,,,,, Class.Name);
	RespawnOnFiredEmitters();
	RespawnTracerEmitters();
	TriggerEffectEvent('UnHidden');
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function bool HasAltFireMod()
{
	return __NFUN_130__(__NFUN_119__(AltFireModAttachment, none), AltFireModAttachment.bGiven);
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function bool HasStrictlySuperiorMod()
{
	return __NFUN_130__(__NFUN_119__(StrictlySuperiorModAttachment, none), StrictlySuperiorModAttachment.bGiven);
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

defaultproperties
{
	PendingFireDelayTime=0.2000000
	InaccuracyPenaltyPerRoundSpent=0.1000000
	CanPendingFire=true
	SortOffset=-100.0000000
}