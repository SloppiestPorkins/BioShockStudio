class Weapon extends Holdable implements IDamager
	abstract
	native
	config(Weapons)
	notplaceable
	hidecategories(DrawScale3D,DisplayAdvanced);

enum OnFiredEmitterAction
{
	EA_Reset,                       // 0
	EA_SpawnParticle                // 1
};

enum UpgradeStatus
{
	US_All,                         // 0
	US_NoUpgrade,                   // 1
	US_StrictlySuperior,            // 2
	US_AltFire,                     // 3
	US_BothUpgrades                 // 4
};

struct native atomic AnimRateRange
{
	var config name AnimationName;
	var config float minAnimRate;
	var config float maxAnimRate;

	structdefaultproperties
	{
		CheckpointTypePadding=7602293
	}
};

struct native atomic OnFiredEffectSpecification
{
	var config Class<Emitter> EmitterClass;
	var config Class<Light> LightClass;
	var config name AttachmentBone;
	var config Vector LocationOffset;
	var config Rotator RotationOffset;
	var config name AmmoType;
	var config Weapon.UpgradeStatus UpgradeType;
	var config Weapon.OnFiredEmitterAction EmitterAction;

	structdefaultproperties
	{
		CheckpointTypePadding=7602293
	}
};

struct native atomic LightEffectInstance
{
	var Light LightInstance;
	var float LightDisableTime;
	var name AmmoType;
	var Vector LocationOffset;
	var Matrix RotationOffset;
};

struct native atomic EmitterEffectInstance
{
	var Emitter EmitterInstance;
	var name AmmoType;
	var Weapon.OnFiredEmitterAction EmitterAction;
	var Vector LocationOffset;
	var Matrix RotationOffset;

	structdefaultproperties
	{
		CheckpointTypePadding=7602293
	}
};

struct native atomic TracerEffectSpecification
{
	var config Class<Emitter> EmitterClass;
	var config name AmmoType;
	var config Weapon.UpgradeStatus UpgradeType;

	structdefaultproperties
	{
		CheckpointTypePadding=7602293
	}
};

struct native atomic TracerEffectInstance
{
	var Emitter EmitterInstance;
	var name AmmoType;
};

var config localized string FriendlyName;
var config array< Class<Ammunition> > AllPossibleAmmoClasses;
var config travel array< Class<Ammunition> > AvailableAmmoTypes;
var private config Class<Ammunition> DefaultAmmoSelection;
var private travel Class<Ammunition> PendingAmmoSelection;
var private travel Class<Ammunition> CurrentAmmoSelection;
var private config bool UsesAmmunition;
var private travel int RoundsRemaining;
var private travel int BurstShotsRemaining;
var private travel bool bFullAuto;
var private travel bool EverBeenEquipped;
var config SkeletalMesh WeaponModel;
var config StaticMesh StaticWeaponModel;
var config Material OverrideSkin;
var config Class<HavokObject> StaticWeaponModelHavokDataClass;
var private config name DamageEmitterSocket;
var private DamageEmitter CurrentDamageEmitter;
var private bool DoNotAttachDamageEmitter;
var private config name AmmunitionModelSocket;
var travel VisibleAmmoModel AmmoModel;
var private Vector LastTraceFireStart;
var private Vector LastTraceFireEnd;
var const config float MagicBulletRadius;
var const config float MouseMagicBulletRadius;
var const config float MagicBulletChance;
var const config float EffectiveMagicBulletDistance;
var const config bool CanPendingFire;
var config bool bUseForDodgeTesting;
var private Vector PreviousLocation;
var private config float DroppedVelocityModifier;
var private config travel name IdlingHolderAnim;
var config array<AnimRateRange> ReloadingEmptyWeaponHolderAnim;
var config array<AnimRateRange> ReloadingEmptyWeaponAnim;
var config array<AnimRateRange> ReloadingNotEmptyWeaponHolderAnim;
var config array<AnimRateRange> ReloadingNotEmptyWeaponAnim;
var config array<AnimRateRange> FiringHolderAnim;
var config array<AnimRateRange> FiringAnim;
var config array<AnimRateRange> FiringFinalShotHolderAnim;
var config array<AnimRateRange> FiringFinalShotAnim;
var config array<AnimRateRange> FiringEmptyShotHolderAnim;
var config array<AnimRateRange> FiringEmptyShotAnim;
var private config float HandTweenTime;
var private config float TweenTime;
var int HolderAnimationHandle;
var int AnimationHandle;
var private float CurrentReloadRate;
var private float CurrentFireRate;
var private int FiringRandomSeed;
var private config int BaseMagazineSize;
var config float BaseAccuracy;
var private config float BaseReloadRate;
var private config float BaseFireRate;
var private config float BaseAmmoConsumptionRate;
var travel array<UpgradeableWeaponStat> UpgradeStats;
var config travel array<name> UpgradeStatName;
var private travel int NumberOfStatPointsUpgraded;
var private config int NumberOfStatPointsRequiredToApplyAltFireMod;
var private config int NumberOfStatPointsRequiredToApplyStrictlySuperiorMod;
var private config name AltFireModStatName;
var config array<OnFiredEffectSpecification> OnFiredEffects;
var array<EmitterEffectInstance> OnFiredEmitterEffectInstances;
var array<LightEffectInstance> OnFiredLightEffectInstances;
var config array<TracerEffectSpecification> TracerEffects;
var private config name TracerStartBone;
var array<TracerEffectInstance> TracerEffectInstances;

function LogOnFiredEffectSpecifications()
{
	local int i;

	log(,, __NFUN_112__(string(self.Name), ": Logging weapon effect specifications."));
	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xD6
	/*@Error*/
	log(,, __NFUN_112__(__NFUN_112__(__NFUN_112__("    ", string(OnFiredEffects[i].EmitterClass)), ", "), string(OnFiredEffects[i].LightClass)));
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x4D;
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function LogOnFiredEffectInstances()
{
	local int i;

	log(,, __NFUN_112__(string(self.Name), ": Logging weapon emitter instances."));
	i = 0;
	// End:0xA4
	if(__NFUN_150__(i, OnFiredEmitterEffectInstances.Length))
	{
		log(,, __NFUN_112__("    ", string(OnFiredEmitterEffectInstances[i].EmitterInstance)));
		__NFUN_163__(i);
		// [Loop Continue]
		goto J0x49;
		log(,, __NFUN_112__(string(self.Name), ": Logging weapon light instances."));
	}
	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x146
	/*@Error*/
	log(,, __NFUN_112__("    ", string(OnFiredLightEffectInstances[i].LightInstance)));
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0xEB;
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function LogTracerEffectSpecifications()
{
	local int i;

	log(,, __NFUN_112__(string(self.Name), ": Logging weapon tracer specifications."));
	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xA8
	/*@Error*/
	log(,, __NFUN_112__("    ", string(TracerEffects[i].EmitterClass)));
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x4D;
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function LogTracerEffectInstances()
{
	local int i;

	log(,, __NFUN_112__(string(self.Name), ": Logging weapon tracer instances."));
	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xA3
	/*@Error*/
	log(,, __NFUN_112__("    ", string(TracerEffectInstances[i].EmitterInstance)));
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x48;
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function PostBeginPlay()
{
	super(Actor).PostBeginPlay();
	// End:0x46
	if(__NFUN_119__(WeaponModel, none))
	{
		LinkMesh(WeaponModel);
		SetDrawType(2);
		SetStaticMesh(none);
		goto J0x9D;
		// End:0x9D
		if(__NFUN_119__(StaticWeaponModel, none))
		{
			AttachToBone(self, GetAttachBone(Holder));
		}
		SetStaticMesh(StaticWeaponModel);
		SetDrawType(8);
		LinkMesh(none);
		// End:0xC0
		if(__NFUN_119__(OverrideSkin, none))
		{
			SetSkin(0, OverrideSkin);
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x160
			/*@Error*/
			AmmoModel = __NFUN_278__(Class'ShockGame.VisibleAmmoModel');
		}
		assert(__NFUN_119__(AmmoModel, none));
		AttachToBone(AmmoModel, AmmunitionModelSocket);
		AmmoModel.DrawPriority = 1;
	}
	AmmoModel.UpdateRenderRevision();
	AmmoModel.SetHidden(true);
	CurrentAmmoSelection = DefaultAmmoSelection;
	SpawnOnFiredEmitters();
	SpawnTracerEmitters();
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

// Export UWeapon::execSpawnOnFiredEmitters(FFrame&, void* const)
private native function SpawnOnFiredEmitters();

// Export UWeapon::execCleanupOnFiredEmitters(FFrame&, void* const)
private native function CleanupOnFiredEmitters();

// Export UWeapon::execRespawnOnFiredEmitters(FFrame&, void* const)
native function RespawnOnFiredEmitters();

function RunOnFiredEmitters(name AmmoType)
{
	//native.AmmoType;	
	@NULL
}

// Export UWeapon::execSpawnTracerEmitters(FFrame&, void* const)
private native function SpawnTracerEmitters();

// Export UWeapon::execCleanupTracerEmitters(FFrame&, void* const)
private native function CleanupTracerEmitters();

// Export UWeapon::execRespawnTracerEmitters(FFrame&, void* const)
native function RespawnTracerEmitters();

function RunTracerEmitters(name AmmoType, Vector StartLocation, Vector EndLocation)
{
	//native.AmmoType;
	//native.StartLocation;
	//native.EndLocation;	
	@NULL
	@NULL
	return stop;
}

function PreLevelTravel()
{
	super(Actor).PreLevelTravel();
	CleanupOnFiredEmitters();
	CleanupTracerEmitters();
	return;
	@NULL
}

function PostLevelTravel()
{
	super(Actor).PostLevelTravel();
	RespawnOnFiredEmitters();
	RespawnTracerEmitters();
	return;
	@NULL
}

function OnSpawnedDamageEmitter(DamageEmitter Emitter)
{
	// End:0x9A
	if(__NFUN_119__(CurrentDamageEmitter, none))
	{
		log('Weapons', 3, __NFUN_112__(string(self.Name), " already has an emitter and is trying to add another one.  Removing old emitter."));
		CurrentDamageEmitter.Kill();
		CurrentDamageEmitter = Emitter;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0xF1
		/*@Error*/
	}
	AttachToBone(CurrentDamageEmitter, DamageEmitterSocket);
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function name GetAnimationForRate(float Rate, out array<AnimRateRange> AnimationList)
{
	local array<name> EligibleAnimations;
	local int i, randomSeed;

	i = 0;
	// End:0xD0
	if(__NFUN_150__(i, AnimationList.Length))
	{
		// End:0xC2
		if(__NFUN_130__(__NFUN_178__(AnimationList[i].minAnimRate, Rate), __NFUN_179__(AnimationList[i].maxAnimRate, Rate)))
		{
			EligibleAnimations[EligibleAnimations.Length] = AnimationList[i].AnimationName;
			__NFUN_163__(i);
			// [Loop Continue]
			goto J0x0B;
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0xEA
			/*@Error*/
			return 'None';
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x10D
			/*@Error*/
			randomSeed = __NFUN_167__(10000);
			goto J0x120;
			randomSeed = FiringRandomSeed;
			return EligibleAnimations[int(__NFUN_173__(float(randomSeed), float(EligibleAnimations.Length)))];
		}
	}
	return;
	@NULL
	Item
	Item
	@NULL
}

function name GetFiringHolderAnim(float Rate)
{
	return GetAnimationForRate(Rate, FiringHolderAnim);
	return;
	@NULL
	Item
}

function name GetIdlingHolderAnim()
{
	return IdlingHolderAnim;
	return;
	@NULL
}

function bool GetPerfectFireStart(out Vector StartLocation, out Rotator StartRotation, out Vector EffectStartLocation)
{
	//native.StartLocation;
	//native.StartRotation;
	//native.EffectStartLocation;	
	@NULL
	@NULL
	return default.@NULL;
}

function Rotator ApplyAimError(Rotator StartRotation)
{
	//native.StartRotation;	
	@NULL
}

function bool CanHit(Actor tester, Actor Target, Vector sourceLocation, out Rotator sourceRotation)
{
	//native.tester;
	//native.Target;
	//native.sourceLocation;
	//native.sourceRotation;	
	@NULL
	@NULL
	return default.@NULL;
}

function InitiateDamage(name EffectEventName)
{
	//native.EffectEventName;	
	@NULL
}

function Class<IProvideDamageData> GetDamageDataClass()
{
	return CurrentAmmoSelection;
	return;
	@NULL
}

function bool HasAvailableAmmo(Class<Ammunition> AmmoClass)
{
	local int i;

	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x54
	/*@Error*/
	// End:0x46
	if(__NFUN_114__(AmmoClass, AvailableAmmoTypes[i]))
	{
		return true;
		__NFUN_165__(i);
		// [Loop Continue]
		goto J0x0B;
		return false;
		return;
		@NULL
		Item
	}
	Item
	@NULL
}

function AddAvailableAmmo(Class<Ammunition> AmmoClass)
{
	AvailableAmmoTypes[AvailableAmmoTypes.Length] = AmmoClass;
	return;
	@NULL
	Item
	Item
}

function RemoveAvailableAmmo(Class<Ammunition> AmmoClass)
{
	local int i;

	i = 0;
	// End:0x69
	if(__NFUN_150__(i, AvailableAmmoTypes.Length))
	{
		// End:0x5B
		if(__NFUN_114__(AmmoClass, AvailableAmmoTypes[i]))
		{
			AvailableAmmoTypes.Remove(i, 1);
			goto J0x69;
			__NFUN_165__(i);
			// [Loop Continue]
			goto J0x0B;
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0xBA
			/*@Error*/
			SelectAmmo(DefaultAmmoSelection);
		}
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0xBA
		/*@Error*/
	}
	Reload();
	return;
	@NULL
	Item
	Item
	@NULL
}

function bool SelectAmmo(Class<Ammunition> AmmoClass)
{
	local int i;
	local bool Found;

	i = 0;
	// End:0x61
	if(__NFUN_150__(i, AvailableAmmoTypes.Length))
	{
		// End:0x53
		if(__NFUN_114__(AmmoClass, AvailableAmmoTypes[i]))
		{
			Found = true;
			goto J0x61;
			__NFUN_165__(i);
			// [Loop Continue]
			goto J0x0B;
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x72
			/*@Error*/
			return false;
			PendingAmmoSelection = AmmoClass;
		}
		return true;
		return;
		@NULL
	}
	Item
	Item
	@NULL
}

function PendingFire(optional bool inAltFire)
{
	return;
}

function BeginFiring(optional bool inAltFire)
{
	local bool weaponIsEmpty;

	weaponIsEmpty = IsEmpty(false);
	// End:0x30
	if(weaponIsEmpty)
	{
		Reload();
		goto J0x3B;
		__NFUN_113__('Firing');
	}
	return;
	@NULL
	Item
}

function CeaseFiring(optional bool AltFire, optional bool bInterruptBurst)
{
	// End:0x18
	if(bInterruptBurst)
	{
		BurstShotsRemaining = 0;
		// End:0x31
		if(bFullAuto)
		{
		}
		bFullAuto = false;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x62
		/*@Error*/
		CurrentDamageEmitter.Kill();
	}
	CurrentDamageEmitter = none;
	return;
	@NULL
	Item
	Item
	@NULL
}

function Reload()
{
	return;
}

function InterruptCurrentAction(optional float TweenOutTime)
{
	InterruptCurrentAnimations(TweenOutTime);
	return;
	@NULL
}

function OnEquippingFinished()
{
	// End:0x4B
	if(__NFUN_129__(EverBeenEquipped))
	{
		PendingAmmoSelection = DefaultAmmoSelection;
		SetCurrentAmmoSelection(DefaultAmmoSelection);
		ShowAmmoModel();
		EverBeenEquipped = true;
		super.OnEquippingFinished();
		return;
		@NULL
		Item
		Item
	}
	@NULL
}

function OnFiringStarted()
{
	FiringRandomSeed = __NFUN_167__(10000);
	ResetBurstShotsRemaining();
	SetFullAuto();
	Holder.OnFiringStarted(self);
	return;
	@NULL
	Item
}

function OnFiringFinished()
{
	FiringRandomSeed = 0;
	Holder.OnFiringFinished(self);
	return;
	@NULL
	Item
}

function OnFiringInterrupted()
{
	FiringRandomSeed = 0;
	Holder.OnFiringInterrupted(self);
	return;
	@NULL
	Item
}

function OnReloadingStarted()
{
	Holder.OnReloadingStarted(self);
	return;
	@NULL
}

function OnReloadingFinished()
{
	Holder.OnReloadingFinished(self);
	return;
	@NULL
}

function PlayWeaponAnimations(optional name HandsAnim, optional name WeaponAnim, optional name HolderAnim, optional name AltFireAttachmentAnim, optional name StrictlySuperiorAttachmentAnim, optional float Rate, optional int AnimationEndBehavior, optional float EaseInTime)
{
	// End:0x1B
	if(__NFUN_154__(AnimationEndBehavior, 0))
	{
		AnimationEndBehavior = 4;
		assert(__NFUN_119__(Holder, none));
	}
	HolderAnimationHandle = Holder.PlayAnimationOnChannelFlatEaseIn(Holder.GetAnimationChannelForWeapon(self), HolderAnim, EaseInTime, 1);
	Holder.SetAnimationPlaybackRate(HolderAnimationHandle, __NFUN_171__(Rate, Holder.GetAnimationPlaybackRate(HolderAnimationHandle)));
	AnimationHandle = PlayAnimationOnChannelFlatEaseIn(0, WeaponAnim, EaseInTime, AnimationEndBehavior);
	SetAnimationPlaybackRate(AnimationHandle, __NFUN_171__(Rate, GetAnimationPlaybackRate(AnimationHandle)));
	return;
	@NULL
	Collectable
	Item
	@NULL
}

function PlayAndFinishHandAndWeaponAnimations(name HandsAnim, name WeaponAnim, name HolderAnim, name AltFireAttachmentAnim, name StrictlySuperiorAttachmentAnim, float Rate, optional int AnimationEndBehavior)
{
	PlayWeaponAnimations(HandsAnim, WeaponAnim, HolderAnim, AltFireAttachmentAnim, StrictlySuperiorAttachmentAnim, Rate, AnimationEndBehavior);
	FinishAnimations();
	return;
	@NULL
	Collectable
	Item
	@NULL
}

function FinishAnimations()
{
	Holder.FinishAnimation(HolderAnimationHandle);
	FinishAnimation(AnimationHandle);
	return;
	@NULL
	Collectable
	Item
	@NULL
}

function InterruptCurrentAnimations(optional float TweenOutTime)
{
	// End:0x5B
	if(__NFUN_177__(TweenOutTime, 0.0000000))
	{
		Holder.FlatEaseOutAnimation(HolderAnimationHandle, TweenOutTime);
		FlatEaseOutAnimation(AnimationHandle, TweenOutTime);
		goto J0x8E;
		Holder.SmartPerTrackEaseOutAnimation(HolderAnimationHandle);
		SmartPerTrackEaseOutAnimation(AnimationHandle);
		return;
	}
	@NULL
	Item
	DifficultyAdjustment
	@NULL
}

function bool HasInitiateDamageOccurred()
{
	return false;
	return;
}

function bool HasAnyInitiateDamageOccurredForAnimation(Actor AnimationTarget, name AnimationName, int AnimationHandle)
{
	local int i;
	local array<AnimNotify> InitiateDamageAnimNotifies;
	local AnimNotify AnimNotifyIter;
	local float CurrentTime, AnimNotifyTime;

	log('Weapons', 5, __NFUN_112__(__NFUN_112__(__NFUN_112__("HasAnyInitiateDamageOccurredForAnimation - AnimationName: ", string(AnimationName)), " AnimationHandle: "), string(AnimationHandle)));
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x244
	/*@Error*/
	AnimationTarget.GetAnimationAnimNotifies(AnimationName, InitiateDamageAnimNotifies, Class'ShockGame.AnimNotify_InitiateDamage');
	CurrentTime = AnimationTarget.GetAnimationCurrentTime(AnimationHandle);
	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x244
	/*@Error*/
	AnimNotifyIter = InitiateDamageAnimNotifies[i];
	AnimNotifyTime = AnimationTarget.GetAnimationAnimNotifyTime(AnimationName, AnimNotifyIter);
	J0x11F:

	log('Weapons', 5, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("HasAnyInitiateDamageOccurredForAnimation - Looking at ", string(AnimNotifyIter)), " AnimNotifyTime: "), string(AnimNotifyTime)), " CurrentTime: "), string(CurrentTime)));
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x236
	/*@Error*/
	return true;
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x11F;
	return false;
	return;
	@NULL
	Item
	DifficultyAdjustment
	@NULL
}

function GetCurrentAnimationNames(out name HolderAnimationName, out name HandsAnimationName, out name WeaponAnimationName)
{
	// End:0x39
	if(__NFUN_119__(Holder, none))
	{
		HolderAnimationName = Holder.GetAnimationName(HolderAnimationHandle);
		WeaponAnimationName = GetAnimationName(AnimationHandle);
		return;
		@NULL
	}
	Item
	DifficultyAdjustment
	@NULL
}

function PlayIdleAnimations()
{
	Holder.PlayAnimationOnChannel(Holder.GetAnimationChannelForWeapon(self), GetIdlingHolderAnim(), 8);
	return;
	@NULL
	Item
	Item
}

function PlayWeaponFiringAnimations()
{
	local bool TriggeredIsFiring;

	log('Weapons', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(self), "::PlayWeaponFiringAnimations() ... BurstShotsRemaining = "), string(BurstShotsRemaining)), ", RoundsRemaining = "), string(RoundsRemaining)));
	// End:0xCE
	if(__NFUN_129__(IsEmpty(false)))
	{
		TriggerEffectEvent('IsFiring',,,,,,,, CurrentAmmoSelection.Name);
		TriggeredIsFiring = true;
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x3F5
		/*@Error*/
	}
	// End:0x106
	if(__NFUN_151__(BurstShotsRemaining, 0))
	{
		__NFUN_166__(BurstShotsRemaining);
		CurrentFireRate = GetFireRate();
		// End:0x183
		if(IsEmpty(false))
		{
			PlayWeaponAnimations(, GetAnimationForRate(CurrentFireRate, FiringEmptyShotAnim), GetAnimationForRate(CurrentFireRate, FiringEmptyShotHolderAnim),,, CurrentFireRate);
		}
		FinishAnimations();
		goto J0x3F5;
		// End:0x202
		if(__NFUN_130__(__NFUN_151__(RoundsRemaining, 0), __NFUN_150__(RoundsRemaining, __NFUN_144__(2, GetNumRoundsToUse(false)))))
		{
			PlayWeaponAnimations(, GetAnimationForRate(CurrentFireRate, FiringFinalShotAnim), GetAnimationForRate(CurrentFireRate, FiringFinalShotHolderAnim),,, CurrentFireRate);
		}
		goto J0x247;
		PlayWeaponAnimations(, GetAnimationForRate(CurrentFireRate, FiringAnim), GetFiringHolderAnim(CurrentFireRate),,, CurrentFireRate);
		TriggerEffectEvent('Fired',,, Location, Rotation,,,, CurrentAmmoSelection.Name);
	}
	TriggerEffectEvent('FiredSound',,, Location, Rotation,,,, CurrentAmmoSelection.Name);
	RunOnFiredEmitters(CurrentAmmoSelection.Name);
	// End:0x313
	if(__NFUN_178__(GetAmmoConsumptionRate(), 0.0000000))
	{
		UseAmmo(false);
		FinishAnimations();
		goto J0x35F;
		FinishAnimations();
		// End:0x35F
		if(__NFUN_119__(CurrentDamageEmitter, none))
		{
			UseAmmo(false);
			__NFUN_256__(GetAmmoConsumptionRate());
			// End:0x35C
			if(IsEmpty(false))
			{
				CeaseFiring();
				goto J0x31D;
				UnTriggerEffectEvent('Fired', CurrentAmmoSelection.Name);
				/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
					
				*/

				// End:0x3F2
				/*@Error*/
				__NFUN_256__(RandRange(CurrentAmmoSelection.default.RandomRangeBetweenBurstShots.Min, CurrentAmmoSelection.default.RandomRangeBetweenBurstShots.Max));
			}
			// [Loop Continue]
			goto J0xCE;
			/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
				
			*/

			// End:0x42B
			/*@Error*/
			UnTriggerEffectEvent('IsFiring', CurrentAmmoSelection.Name);
			return;
		}
		@NULL
	}
	Collectable
	Item
	@NULL
}

function UntriggerFiringSoundEffectEvents()
{
	UnTriggerEffectEvent('IsFiring', CurrentAmmoSelection.Name);
	UnTriggerEffectEvent('Fired', CurrentAmmoSelection.Name);
	return;
	@NULL
	Item
	Item
	@NULL
}

function PlayReloadingAnimations(optional float EaseInTime)
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x113
	/*@Error*/
	CurrentReloadRate = GetReloadRate();
	// End:0xB1
	if(IsEmpty(false))
	{
		PlayWeaponAnimations(, GetAnimationForRate(CurrentReloadRate, ReloadingEmptyWeaponAnim), GetAnimationForRate(CurrentReloadRate, ReloadingEmptyWeaponHolderAnim),,, CurrentReloadRate,, EaseInTime);
		goto J0x109;
		PlayWeaponAnimations(, GetAnimationForRate(CurrentReloadRate, ReloadingNotEmptyWeaponAnim), GetAnimationForRate(CurrentReloadRate, ReloadingNotEmptyWeaponHolderAnim),,, CurrentReloadRate,, EaseInTime);
	}
	FinishAnimations();
	SetCurrentAmmoSelection(PendingAmmoSelection);
	return;
	@NULL
	Collectable
	Item
	@NULL
}

function HideWeapon(bool Hide)
{
	SetHidden(Hide);
	return;
	@NULL
	Item
}

function bool UsesAmmo()
{
	return UsesAmmunition;
	return;
	@NULL
}

function ResetBurstShotsRemaining()
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0xC7
	/*@Error*/
	BurstShotsRemaining = int(RandRange(CurrentAmmoSelection.default.RandomRangeBurstShots.Min, CurrentAmmoSelection.default.RandomRangeBurstShots.Max));
	goto J0xEA;
	BurstShotsRemaining = __NFUN_250__(1, CurrentAmmoSelection.default.NumBurstShots);
	return;
	@NULL
	Item
	DifficultyAdjustment
	@NULL
}

function SetFullAuto()
{
	bFullAuto = CurrentAmmoSelection.default.UseFullAuto;
	return;
	@NULL
	Item
	DifficultyAdjustment
}

private function UseAmmo(bool inAltFiring)
{
	return;
}

function int GetNumRoundsToUse(bool inAltFiring)
{
	// End:0x26
	if(__NFUN_119__(CurrentAmmoSelection, none))
	{
		return CurrentAmmoSelection.default.NumRoundsUsedPerShot;
		// End:0x4C
		if(__NFUN_119__(PendingAmmoSelection, none))
		{
			return PendingAmmoSelection.default.NumRoundsUsedPerShot;
		}
		AssertWithDescription(false, __NFUN_112__(__NFUN_112__("Attempted to GetNumRoundsToUse for '", string(self.Name)), "', but no ammo is selected, returning 0."));
	}
	return 0;
	return;
	@NULL
	Item
	DifficultyAdjustment
	@NULL
}

function bool IsEmpty(bool inAltFiring)
{
	return __NFUN_130__(UsesAmmo(), __NFUN_150__(RoundsRemaining, GetNumRoundsToUse(inAltFiring)));
	return;
	@NULL
	Item
}

function SetCurrentAmmoSelection(Class<Ammunition> AmmoClass)
{
	return;
}

function Class<Ammunition> GetCurrentAmmoSelection()
{
	return CurrentAmmoSelection;
	return;
	@NULL
}

function Class<Ammunition> GetDefaultAmmoSelection()
{
	return DefaultAmmoSelection;
	return;
	@NULL
}

function int GetRoundsRemaining()
{
	return RoundsRemaining;
	return;
	@NULL
}

function ShowAmmoModel()
{
	log('Weapons', 4, __NFUN_112__(string(self), "::ShowAmmoModel()"));
	// End:0x39
	if(__NFUN_114__(AmmoModel, none))
	{
		return;
		// End:0x55
		if(__NFUN_129__(ShouldShowAmmoModel()))
		{
		}
		HideAmmoModel();
		goto J0x152;
		// End:0xB3
		if(__NFUN_119__(AmmoModel.StaticMesh, PendingAmmoSelection.default.VisualAmmoModel))
		{
		}
		AmmoModel.SetStaticMesh(PendingAmmoSelection.default.VisualAmmoModel);
		// End:0xFD
		if(__NFUN_119__(PendingAmmoSelection.default.VisualAmmoModelSkinOverride, none))
		{
			AmmoModel.SetSkin(0, PendingAmmoSelection.default.VisualAmmoModelSkinOverride);
		}
		AmmoModel.TriggerEffectEvent('AmmoUnHidden',,,,,,,, PendingAmmoSelection.Name);
		AmmoModel.SetHidden(false);
	}
	return;
	@NULL
	Item
	Item
	@NULL
}

function bool ShouldShowAmmoModel()
{
	return true;
	return;
}

function HideAmmoModel()
{
	log('Weapons', 4, __NFUN_112__(string(self), "::HideAmmoModel()"));
	// End:0x39
	if(__NFUN_114__(AmmoModel, none))
	{
		return;
		AmmoModel.SetHidden(true);
	}
	AmmoModel.UnTriggerEffectEvent('AmmoUnHidden', CurrentAmmoSelection.Name);
	return;
	@NULL
	Item
	Item
	@NULL
}

function int GetMagazineSize()
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x67
	/*@Error*/
	return int(Holder.ModifyStat(string(__NFUN_112__(string(Class.Name), "MagazineSize_Bonus")), float(BaseMagazineSize)));
	goto J0x71;
	return BaseMagazineSize;
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function float GetAccuracy()
{
	return Holder.ModifyStat(string(__NFUN_112__(string(Class.Name), "Accuracy_Modifier")), BaseAccuracy);
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function float GetReloadRate()
{
	return Holder.ModifyStat(string(__NFUN_112__(string(Class.Name), "ReloadRate_Bonus")), BaseReloadRate);
	return;
	@NULL
	Item
	Item
	@NULL
}

function float GetFireRate()
{
	return Holder.ModifyStat(string(__NFUN_112__(string(Class.Name), "FireRate_Bonus")), BaseFireRate);
	return;
	@NULL
	Item
	Item
	@NULL
}

function float GetAmmoDamagePotential(ShockPlayer Player, Class<Ammunition> AmmoClass)
{
	local float DamagePotential;
	local DamageStimuliSet DamageStimuli;
	local int i;

	DamageStimuli = Class'Engine.DamageStimuliSet'.static.GetDamageStimuliSet(AmmoClass.default.DamageStimuliSetName);
	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x114
	/*@Error*/
	switch(DamageStimuli.Stimulus[i].Type)
	{
		// End:0x9F
		case 18:
			// End:0xA4
			case 19:
				// End:0xA9
				case 20:
					// End:0xAE
					case 21:
						// End:0xB3
						case 22:
							// End:0xB8
							case 23:
								// End:0xBD
								case 24:
									// End:0xC2
									case 25:
										// End:0x103
										case 26:
											__NFUN_184__(DamagePotential, DamageStimuli.Stimulus[i].Amount);
						// End:0xFFFF
						default:
							__NFUN_165__(i);
							break;/* Tried to find Switch scope, found Case instead */
				// [Loop Continue]
				goto J0x42;
				DamageStimuli.__NFUN_200__();
			return DamagePotential;
			return;
			@NULL
			Item
			Item
			@NULL
}

function float GetDamagePotential(ShockPlayer Player)
{
	local float DamagePotential;
	local int i;
	local Class<Ammunition> AmmoClass;

	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xB3
	/*@Error*/
	AmmoClass = AvailableAmmoTypes[i];
	__NFUN_184__(DamagePotential, __NFUN_172__(__NFUN_171__(float(Player.GetNumberOfItems(AmmoClass)), GetAmmoDamagePotential(Player, AmmoClass)), float(AmmoClass.default.NumRoundsUsedPerShot)));
	__NFUN_163__(i);
	// [Loop Continue]
	goto J0x0B;
	return DamagePotential;
	return;
	@NULL
	Item
	Item
	@NULL
}

function AddStatUpgrade(name StatName)
{
	//native.StatName;	
	@NULL
}

function bool IsWeaponFullyUpgraded()
{
	local bool bAllStatsUpgraded;
	local int i;

	bAllStatsUpgraded = true;
	i = __NFUN_147__(UpgradeStats.Length, 1);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x94
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x86
	/*@Error*/
	bAllStatsUpgraded = false;
	goto J0x94;
	__NFUN_164__(i);
	// [Loop Continue]
	goto J0x23;
	return bAllStatsUpgraded;
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function float GetAmmoConsumptionRate()
{
	return Holder.ModifyStat(string(__NFUN_112__(string(Class.Name), "AmmoConsumptionRate_Bonus")), BaseAmmoConsumptionRate);
	return;
	@NULL
	Item
	Item
	@NULL
}

event GiveAltFireMod()
{
	return;
}

event GiveStrictlySuperiorMod()
{
	return;
}

event bool HasAltFireMod()
{
	return false;
	return;
}

event bool HasStrictlySuperiorMod()
{
	return false;
	return;
}

function DumpState()
{
	local int LOD;

	// End:0x2B
	if(Holder.__NFUN_303__('ShockPlayer'))
	{
		LOD = 3;
		goto J0x37;
		LOD = 4;
	}
	log('Weapons', byte(LOD), "---------------------------------------------------------------------------------");
	log('Weapons', byte(LOD), __NFUN_112__(__NFUN_112__("-------------------------------Weapon State: ", string(Name)), " --------------------"));
	log('Weapons', byte(LOD), "");
	log('Weapons', byte(LOD), __NFUN_112__(__NFUN_112__("... RoundsRemaining = ", string(RoundsRemaining)), " ..."));
	log('Weapons', byte(LOD), __NFUN_112__(__NFUN_112__("... CurrentAmmoSelection = ", string(CurrentAmmoSelection)), " ..."));
	log('Weapons', byte(LOD), "---------------------------------------------------------------------------------");
	return;
	@NULL
	Item
	Item
	@NULL
}

function Destroyed()
{
	// End:0x31
	if(__NFUN_119__(CurrentDamageEmitter, none))
	{
		CurrentDamageEmitter.Kill();
		CurrentDamageEmitter = none;
		CleanupOnFiredEmitters();
		CleanupTracerEmitters();
	}
	super(Actor).Destroyed();
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

state Firing
{
	function BeginState()
	{
		OnFiringStarted();
		return;
	}
Begin:

	PlayWeaponFiringAnimations();
	OnFiringFinished();
	__NFUN_113__('None');
	stop;				
}

defaultproperties
{
	FriendlyName="The 'FriendlyName' field needs to be configured in Weapons.ini for this Weapon"
	UsesAmmunition=true
	bUseForDodgeTesting=true
	DroppedVelocityModifier=0.5000000
	BaseMagazineSize=10
	BaseAccuracy=1.0000000
	BaseReloadRate=1.0000000
	BaseFireRate=1.0000000
	NumberOfStatPointsRequiredToApplyAltFireMod=8
	NumberOfStatPointsRequiredToApplyStrictlySuperiorMod=4
	IdlingHandsAnim[0]="testIdle"
	EquippingAnim="Equip"
	UnEquippingAnim="UnEquip"
	ShouldSerializeSkeletonInstance=true
}