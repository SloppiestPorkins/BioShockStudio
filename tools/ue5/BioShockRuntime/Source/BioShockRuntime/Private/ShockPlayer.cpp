#include "ShockPlayer.h"

#include "ShockAudioLibrary.h"
#include "ShockGameMode.h"
#include "ShockHackingMinigame.h"
#include "ShockConsumablePickup.h"
#include "ShockPlasmid.h"
#include "ShockPlasmidFx.h"
#include "ShockSearchableContainer.h"
#include "ShockSecurityDevice.h"
#include "ShockSecuritySubsystem.h"
#include "ShockStationActor.h"
#include "ShockTurret.h"
#include "ShockViewHandsAnimInstance.h"
#include "ShockWaterVolume.h"
#include "ShockWeapon.h"
#include "ShockWeaponDef.h"
#include "Animation/AnimSequence.h"
#include "Animation/AnimSingleNodeInstance.h"
#include "Blueprint/UserWidget.h"
#include "Camera/CameraComponent.h"
#include "Components/CapsuleComponent.h"
#include "Components/InputComponent.h"
#include "Components/SkeletalMeshComponent.h"
#include "Components/StaticMeshComponent.h"
#include "NavigationInvokerComponent.h"
#include "CollisionQueryParams.h"
#include "DrawDebugHelpers.h"
#include "Engine/Scene.h"
#include "Engine/SkeletalMesh.h"
#include "EngineUtils.h"
#include "GameFramework/CharacterMovementComponent.h"
#include "GameFramework/Controller.h"
#include "GameFramework/PlayerController.h"
#include "Materials/MaterialInstanceDynamic.h"
#include "Materials/MaterialInterface.h"
#include "TimerManager.h"

namespace
{
constexpr float WeaponRecoilRecoverSeconds = 0.12f;
constexpr float PlasmidTraceRange = 10000.0f;
constexpr float HackTraceRange = 800.0f;
constexpr float HackFailSelfDamage = 5.0f; // PLAUSIBLE — pipe minigame shock stand-in

/** Asset-leaf names under /Game/BioShockWeapons/NEWPlayerHands/Animations/ — casing is per-file. */
struct FViewHandsAnimNames
{
	const TCHAR* Equip = nullptr;
	const TCHAR* Fidget = nullptr;
	const TCHAR* Fire = nullptr;
	const TCHAR* Reload = nullptr;
	const TCHAR* FireWindup = nullptr; // optional clip before Fire (wrench Swing_A_Wrench_Start)
	const TCHAR* FireAlt = nullptr;    // optional alternate strike, every other swing (Swing_B_Wrench)
	const TCHAR* ReloadLoop = nullptr; // optional per-round loop (ReloadShotgun_LOOP)
	const TCHAR* ReloadEnd = nullptr;  // optional reload finisher (ReloadShotgun_End)
};

bool TryGetViewHandsAnimNames(FName WeaponDefName, FViewHandsAnimNames& Out)
{
	const FString Key = WeaponDefName.ToString();
	if (Key.Equals(TEXT("TommyGun"), ESearchCase::IgnoreCase))
	{
		// On-disk: EquipTommygun / FidgetTommygun (lower g); FireTommyGun / ReloadTommyGun (upper G).
		Out = {TEXT("EquipTommygun"), TEXT("FidgetTommygun"), TEXT("FireTommyGun"), TEXT("ReloadTommyGun")};
		return true;
	}
	if (Key.Equals(TEXT("Pistol"), ESearchCase::IgnoreCase))
	{
		Out = {TEXT("EquipPistol"), TEXT("FidgetPistol"), TEXT("FireSinglePistol"), TEXT("FastReloadPistol")};
		return true;
	}
	if (Key.Equals(TEXT("Crossbow"), ESearchCase::IgnoreCase))
	{
		Out = {TEXT("EquipCrossbow"), TEXT("FidgetCrossbow"), TEXT("FireCrossbow"), TEXT("ReloadCrossbow")};
		return true;
	}
	if (Key.Equals(TEXT("Shotgun"), ESearchCase::IgnoreCase))
	{
		// Shell-by-shell reload: Start → LOOP per round → End (NotifyViewHandsWeaponReloadStarted).
		Out = {TEXT("EquipShotgun"), TEXT("FidgetShotgun"), TEXT("FireShotgun"), TEXT("ReloadShotgun_Start")};
		Out.ReloadLoop = TEXT("ReloadShotgun_LOOP");
		Out.ReloadEnd = TEXT("ReloadShotgun_End");
		return true;
	}
	if (Key.Equals(TEXT("ChemicalThrower"), ESearchCase::IgnoreCase))
	{
		// Fire is a Start/Loop/End trio in-game; FireStartChem is the trigger-pull this struct plays.
		Out = {TEXT("EquipChem"), TEXT("FidgetChem"), TEXT("FireStartChem"), TEXT("ReloadChem")};
		return true;
	}
	if (Key.Equals(TEXT("GrenadeLauncher"), ESearchCase::IgnoreCase))
	{
		Out = {TEXT("EquipLauncher"), TEXT("FidgetLauncher"), TEXT("FireLauncher"), TEXT("ReloadLauncher")};
		return true;
	}
	if (Key.Equals(TEXT("Wrench"), ESearchCase::IgnoreCase))
	{
		// Melee: no reload. Swings alternate Swing_A (with a Start wind-up) and Swing_B so the
		// attack has an over/under variation instead of one repeated clip.
		Out = {TEXT("EquipWrench"), TEXT("FidgetWrench"), TEXT("Swing_A_Wrench"), nullptr};
		Out.FireWindup = TEXT("Swing_A_Wrench_Start");
		Out.FireAlt = TEXT("Swing_B_Wrench");
		return true;
	}
	return false;
}

UAnimSequence* LoadViewHandsAnim(const TCHAR* LeafName)
{
	if (!LeafName)
	{
		return nullptr;
	}
	const FString Path = FString::Printf(
		TEXT("/Game/BioShockWeapons/NEWPlayerHands/Animations/%s.%s"), LeafName, LeafName);
	return LoadObject<UAnimSequence>(nullptr, *Path);
}
} // namespace

AShockPlayer::AShockPlayer()
{
	SchemaClassName = TEXT("ShockPlayer");
	bUseControllerRotationYaw = true;
	bUseControllerRotationPitch = false;
	bUseControllerRotationRoll = false;
	AutoPossessPlayer = EAutoReceiveInput::Disabled;
	BaseEyeHeight = 60.0f;
	CrouchedEyeHeight = 36.0f;
	CurrentEyeHeight = 60.0f;

	if (UCapsuleComponent* Capsule = GetCapsuleComponent())
	{
		// Radius already matched UE's own standard mannequin capsule (34); half-height was 68 (136uu
		// total ~1.36m), well short of the standard 88 (176uu ~1.76m, a real human) the rest of this
		// project's scale assumes everywhere else (room/door dimensions, weapon ranges). Movement
		// never actually worked until today (see h11), so nobody had ever walked around to notice
		// the player read as short against doorways and furniture built for a full-height human.
		Capsule->SetCapsuleRadius(34.0f);
		Capsule->SetCapsuleHalfHeight(88.0f);
	}
	if (UCharacterMovementComponent* Movement = GetCharacterMovement())
	{
		Movement->MaxWalkSpeed = 450.0f;
		Movement->JumpZVelocity = 525.0f;
		Movement->MaxAcceleration = 2048.0f;
		Movement->BrakingDecelerationWalking = 2048.0f;
		Movement->GroundFriction = 8.0f;
		Movement->AirControl = 0.05f;
		Movement->FallingLateralFriction = 0.0f;
		Movement->MaxStepHeight = 35.0f;
		Movement->SetWalkableFloorAngle(44.0f);
		Movement->SetCrouchedHalfHeight(40.0f);
		Movement->MaxWalkSpeedCrouched = 450.0f * 0.45f;
		Movement->GetNavAgentPropertiesRef().bCanCrouch = true;
	}
	if (USkeletalMeshComponent* BodyMesh = GetMesh())
	{
		BodyMesh->SetHiddenInGame(true);
		BodyMesh->SetCollisionEnabled(ECollisionEnabled::NoCollision);
	}

	FirstPersonCamera = CreateDefaultSubobject<UCameraComponent>(TEXT("FirstPersonCamera"));
	FirstPersonCamera->SetupAttachment(GetCapsuleComponent());
	FirstPersonCamera->SetRelativeLocation(FVector(0.0f, 0.0f, BaseEyeHeight));
	FirstPersonCamera->bUsePawnControlRotation = true;
	// BioShock 1 renders at a narrower FOV than UE's 90 default — the world reads more enclosed and
	// the viewmodel sits large and close, the way an FPS gun is meant to. Overridable in the
	// editor and via -bioshockfov=<deg>.
	FirstPersonCamera->SetFieldOfView(CameraFieldOfView);
	// Manual exposure must match repair_level_lighting.py's unbound PPV (BIOSHOCK_LIGHT_EV,
	// default 11). Camera PP at blend weight 1 overrides the volume: pinning EV=0 here made
	// Play near-black while the editor viewport (volume only) stayed bright — reported
	// 5 Sept 2026. Do not drop this back to 0 without also removing the repair PPV.
	FirstPersonCamera->PostProcessBlendWeight = 1.0f;
	FirstPersonCamera->PostProcessSettings.bOverride_AutoExposureMethod = true;
	FirstPersonCamera->PostProcessSettings.AutoExposureMethod = AEM_Manual;
	FirstPersonCamera->PostProcessSettings.bOverride_AutoExposureBias = true;
	FirstPersonCamera->PostProcessSettings.AutoExposureBias = 11.0f;

	// Tick: held-fire, one-shot hands→fidget, recoil. ViewHands is NOT re-pinned each frame
	// (docs/research/viewmodel.md) — only PlaceViewHandsFixed on equip.
	PrimaryActorTick.bCanEverTick = true;

	ViewHands = CreateDefaultSubobject<USkeletalMeshComponent>(TEXT("ViewHands"));
	ViewHands->SetupAttachment(FirstPersonCamera);
	ViewHands->SetCollisionEnabled(ECollisionEnabled::NoCollision);
	ViewHands->SetCastShadow(false);
	ViewHands->SetHiddenInGame(true);

	// A first-person viewmodel is always in view, and must never decide otherwise on its own.
	//
	// It did. Measured from the posed bone transforms, all 66 bones sat in front of the eye and
	// topped out 17 units below it — plainly in frame — while the component's FBoxSphereBounds
	// claimed a sphere centred 132 units BELOW the eye. Unreal culls on bounds, not on geometry,
	// so the arms were culled while their skeleton was in shot, and the gun (a separate actor on
	// the grip socket) kept drawing, which made it look like a framing problem.
	//
	// The default VisibilityBasedAnimTickOption then locks that in: OnlyTickPoseWhenRendered
	// stops evaluating the pose once the component is culled, so the stale bounds that caused the
	// culling can never be recomputed. Always ticking breaks the loop; the generous bounds scale
	// means a pose that briefly leaves the authored bounds cannot start it again. Both are cheap
	// on one always-visible mesh.
	ViewHands->VisibilityBasedAnimTickOption =
		EVisibilityBasedAnimTickOption::AlwaysTickPoseAndRefreshBones;
	ViewHands->SetBoundsScale(4.0f);

	PlasmidHands = CreateDefaultSubobject<USkeletalMeshComponent>(TEXT("PlasmidHands"));
	PlasmidHands->SetupAttachment(FirstPersonCamera);
	PlasmidHands->SetCollisionEnabled(ECollisionEnabled::NoCollision);
	PlasmidHands->SetCastShadow(false);
	PlasmidHands->SetHiddenInGame(true);
	PlasmidHands->VisibilityBasedAnimTickOption =
		EVisibilityBasedAnimTickOption::AlwaysTickPoseAndRefreshBones;
	PlasmidHands->SetBoundsScale(4.0f);

	// The imported 1-Medical BSP has no placed NavMeshBoundsVolume, and a volume spawned at runtime
	// has no brush geometry to scale (ConstructTiledNavMesh: navmesh of size 0). A NavigationInvoker
	// on the player, with NavigationSystemV1 bGenerateNavigationOnlyAroundNavigationInvokers=True and
	// the RecastNavMesh RuntimeGeneration=Dynamic (both in DefaultEngine.ini), makes the nav system
	// build tiles in a radius around the pawn — enough for the encounter AI to path around geometry.
	NavInvoker = CreateDefaultSubobject<UNavigationInvokerComponent>(TEXT("NavInvoker"));
	NavInvoker->SetGenerationRadii(4000.0f, 5500.0f);

	EquippedPlasmids.SetNum(6);
	WeaponSlots.SetNum(8);
}

void AShockPlayer::OnDeathFromDamage()
{
	OnDied();
}

void AShockPlayer::OnDied()
{
	if (bDeathHandled)
	{
		return;
	}
	bDeathHandled = true;
	++DeathNotifyCount;
	UShockAudioLibrary::SpawnEventAttached(TEXT("ShockPlayer"), TEXT("Died"), RootComponent);
	UE_LOG(LogTemp, Display, TEXT("BIOSHOCK_AUDIO vocal pawn=Player event=Died"));

	EnablePlayableInput(false);
	SetMovementDisabled(true);

	if (APlayerController* PC = Cast<APlayerController>(GetController()))
	{
		PC->DisableInput(PC);
	}

	if (UCharacterMovementComponent* Move = GetCharacterMovement())
	{
		Move->StopMovementImmediately();
		Move->DisableMovement();
	}
	if (USkeletalMeshComponent* Body = GetMesh();
		Body && Body->GetSkeletalMeshAsset() && Body->GetPhysicsAsset())
	{
		Body->SetCollisionProfileName(TEXT("Ragdoll"));
		Body->SetSimulatePhysics(true);
	}

	if (ViewHands)
	{
		ViewHands->SetHiddenInGame(true);
	}
	if (PlasmidHands)
	{
		PlasmidHands->SetHiddenInGame(true);
	}
	if (EquippedWeapon)
	{
		EquippedWeapon->SetActorHiddenInGame(true);
	}

	OnPlayerDied.Broadcast(this);
}

void AShockPlayer::ResetForRespawn(float Health)
{
	const float Seed = Health > 0.0f ? Health : (AuthoredMaxHealth > 0.0f ? AuthoredMaxHealth : 100.0f);
	if (USkeletalMeshComponent* Body = GetMesh(); Body && Body->IsSimulatingPhysics())
	{
		Body->SetSimulatePhysics(false);
		Body->SetCollisionEnabled(ECollisionEnabled::QueryOnly);
		Body->AttachToComponent(
			GetCapsuleComponent(), FAttachmentTransformRules::SnapToTargetNotIncludingScale);
	}
	CurrentHealth = Seed;
	bIsDead = false;
	bDeathHandled = false;
	SetMovementDisabled(false);
	EnablePlayableInput(true);

	if (APlayerController* PC = Cast<APlayerController>(GetController()))
	{
		PC->EnableInput(PC);
	}

	SetPlasmidHandActive(bPlasmidHandActive);
	if (EquippedWeapon)
	{
		EquippedWeapon->SetActorHiddenInGame(false);
	}
}

void AShockPlayer::RestoreVitaChamberVitals(float HealthFraction, float EveFloorFraction)
{
	const float MaxHealth = AuthoredMaxHealth > 0.0f
		? AuthoredMaxHealth
		: (AuthoredHealth > 0.0f ? AuthoredHealth : 100.0f);
	ResetForRespawn(MaxHealth * FMath::Clamp(HealthFraction, 0.0f, 1.0f));
	CurrentEve = FMath::Max(
		CurrentEve,
		MaxEve * FMath::Clamp(EveFloorFraction, 0.0f, 1.0f));
}

void AShockPlayer::PossessedBy(AController* NewController)
{
	Super::PossessedBy(NewController);

	if (USkeletalMeshComponent* BodyMesh = GetMesh())
	{
		BodyMesh->SetHiddenInGame(true);
	}

	if (FirstPersonCamera)
	{
		float Fov = CameraFieldOfView;
		FString S;
		if (FParse::Value(FCommandLine::Get(), TEXT("bioshockfov="), S, false) && !S.IsEmpty())
		{
			Fov = FCString::Atof(*S);
		}
		FirstPersonCamera->SetFieldOfView(FMath::Clamp(Fov, 40.0f, 120.0f));
	}

	if (APlayerController* PC = Cast<APlayerController>(NewController))
	{
		PC->SetViewTarget(this);
	}
}

void AShockPlayer::EnsureViewHands()
{
	if (!ViewHands || ViewHands->GetSkeletalMeshAsset())
	{
		return;
	}

	USkeletalMesh* Hands = LoadObject<USkeletalMesh>(
		nullptr,
		TEXT("/Game/BioShockWeapons/NEWPlayerHands/NEWPlayerHands.NEWPlayerHands"));
	if (!Hands)
	{
		UE_LOG(LogTemp, Warning, TEXT("BIOSHOCK_VIEWMODEL hands=0"));
		return;
	}

	ViewHands->SetSkeletalMesh(Hands);
	ViewHands->SetHiddenInGame(false);
	ViewHands->SetOnlyOwnerSee(false);
	ViewHands->SetOwnerNoSee(false);
	// Crossfading native anim instance — smooths every equip/fire/reload/swing/fidget transition
	// instead of UAnimSingleNodeInstance's hard cut. Clips go through PlayViewHandsAnimation.
	ViewHands->SetAnimInstanceClass(UShockViewHandsAnimInstance::StaticClass());
	// Idle / equip / fire / reload clips are selected per weapon by StartViewHandsForEquippedWeapon.
	// Do not hardcode FidgetTommygun here — that locked every weapon to the Tommy Gun pose.
}

void AShockPlayer::EnsurePlasmidHands()
{
	if (!PlasmidHands)
	{
		return;
	}
	if (!PlasmidHands->GetSkeletalMeshAsset())
	{
		USkeletalMesh* Hands = LoadObject<USkeletalMesh>(
			nullptr,
			TEXT("/Game/BioShockWeapons/NEWPlayerHands/NEWPlayerHands.NEWPlayerHands"));
		if (!Hands)
		{
			UE_LOG(LogTemp, Warning, TEXT("BIOSHOCK_PLASMID_HAND mesh=0"));
			return;
		}
		PlasmidHands->SetSkeletalMesh(Hands);
		PlasmidHands->SetOnlyOwnerSee(false);
		PlasmidHands->SetOwnerNoSee(false);
		PlasmidHands->SetAnimInstanceClass(UShockViewHandsAnimInstance::StaticClass());
	}

	PlasmidHands->SetRelativeLocation(ViewmodelOffset);
	PlasmidHands->SetRelativeRotation(ViewmodelRotation);
}

UShockViewHandsAnimInstance* AShockPlayer::GetViewHandsAnimInstance() const
{
	return ViewHands ? Cast<UShockViewHandsAnimInstance>(ViewHands->GetAnimInstance()) : nullptr;
}

UShockViewHandsAnimInstance* AShockPlayer::GetPlasmidHandsAnimInstance() const
{
	return PlasmidHands ? Cast<UShockViewHandsAnimInstance>(PlasmidHands->GetAnimInstance()) : nullptr;
}

void AShockPlayer::PlayPlasmidHandsAnimation(UAnimSequence* Sequence, bool bLoop)
{
	if (!PlasmidHands || !Sequence)
	{
		return;
	}
	if (bLoop && Sequence == LastPlasmidHandsAnim && !bPlasmidHandsPlayingOneShot)
	{
		return;
	}

	if (UShockViewHandsAnimInstance* Inst = GetPlasmidHandsAnimInstance())
	{
		Inst->PlayClip(Sequence, bLoop, bLoop ? 0.12f : 0.04f);
	}
	else
	{
		PlasmidHands->PlayAnimation(Sequence, bLoop);
	}
	PlasmidHands->TickAnimation(0.0f, false);
	PlasmidHands->RefreshBoneTransforms();
	LastPlasmidHandsAnim = Sequence;
	bPlasmidHandsPlayingOneShot = !bLoop;
	PlasmidHandsOneShotRemaining = bLoop ? 0.0f : Sequence->GetPlayLength();
}

void AShockPlayer::ResolvePlasmidHandsPresentation()
{
	UShockPlasmid* Plasmid = GetActivePlasmid();
	if (!Plasmid || !PlasmidHands)
	{
		return;
	}
	if (PlasmidHandsAnimName != Plasmid->PlasmidName)
	{
		PlasmidHandsAnimName = Plasmid->PlasmidName;
		PlasmidHandsIdleAnim = LoadViewHandsAnim(*Plasmid->HandIdleAnimation.ToString());
		PlasmidHandsCastAnim = LoadViewHandsAnim(*Plasmid->HandCastAnimation.ToString());
		LastPlasmidHandsAnim = nullptr;
	}

	UMaterialInterface* HandMaterial = LoadObject<UMaterialInterface>(
		nullptr,
		TEXT("/Game/BioShockFX/Plasmids/M_PlasmidHand_Base.M_PlasmidHand_Base"));
	if (HandMaterial)
	{
		PlasmidHandsMaterial = UMaterialInstanceDynamic::Create(HandMaterial, this);
		if (PlasmidHandsMaterial)
		{
			PlasmidHandsMaterial->SetVectorParameterValue(TEXT("Tint"), Plasmid->HandTint);
			const int32 Slots = FMath::Max(1, PlasmidHands->GetNumMaterials());
			for (int32 Slot = 0; Slot < Slots; ++Slot)
			{
				PlasmidHands->SetMaterial(Slot, PlasmidHandsMaterial);
			}
		}
	}

	if (PlasmidHandsIdleAnim)
	{
		PlayPlasmidHandsAnimation(PlasmidHandsIdleAnim, true);
	}
	UE_LOG(
		LogTemp,
		Display,
		TEXT("BIOSHOCK_PLASMID_HAND plasmid=%s idle=%s cast=%s tint=%s"),
		*Plasmid->PlasmidName.ToString(),
		PlasmidHandsIdleAnim ? *PlasmidHandsIdleAnim->GetName() : TEXT("missing"),
		PlasmidHandsCastAnim ? *PlasmidHandsCastAnim->GetName() : TEXT("missing"),
		*Plasmid->HandTint.ToString());
}

void AShockPlayer::PlayActivePlasmidCastAnimation()
{
	if (PlasmidHandsCastAnim)
	{
		PlayPlasmidHandsAnimation(PlasmidHandsCastAnim, false);
	}
}

void AShockPlayer::TickPlasmidHandsAnimation(float DeltaSeconds)
{
	if (!bPlasmidHandsPlayingOneShot)
	{
		return;
	}
	PlasmidHandsOneShotRemaining = FMath::Max(0.0f, PlasmidHandsOneShotRemaining - DeltaSeconds);
	if (PlasmidHandsOneShotRemaining <= 0.0f)
	{
		bPlasmidHandsPlayingOneShot = false;
		if (PlasmidHandsIdleAnim)
		{
			PlayPlasmidHandsAnimation(PlasmidHandsIdleAnim, true);
		}
	}
}

void AShockPlayer::SetPlasmidHandActive(bool bActive)
{
	bPlasmidHandActive = bActive && GetActivePlasmid() != nullptr;
	if (bPlasmidHandActive)
	{
		EnsurePlasmidHands();
		if (ViewHands)
		{
			ViewHands->SetHiddenInGame(true);
		}
		if (EquippedWeapon)
		{
			EquippedWeapon->SetActorHiddenInGame(true);
		}
		if (PlasmidHands && PlasmidHands->GetSkeletalMeshAsset())
		{
			PlasmidHands->SetHiddenInGame(false);
			ResolvePlasmidHandsPresentation();
		}
		return;
	}

	if (PlasmidHands)
	{
		PlasmidHands->SetHiddenInGame(true);
	}
	if (ViewHands && ViewHands->GetSkeletalMeshAsset() && !bIsDead)
	{
		ViewHands->SetHiddenInGame(false);
	}
	if (ActiveWeaponSlot >= 0 && !bIsDead)
	{
		UpdateWeaponSlotVisibility(ActiveWeaponSlot);
	}
}

bool AShockPlayer::IsPlasmidHandsVisibleForVerify() const
{
	return PlasmidHands && PlasmidHands->GetSkeletalMeshAsset() && !PlasmidHands->bHiddenInGame;
}

FName AShockPlayer::GetPlayingPlasmidHandsAnimationNameForVerify() const
{
	return LastPlasmidHandsAnim ? LastPlasmidHandsAnim->GetFName() : NAME_None;
}

FVector AShockPlayer::GetPlasmidMuzzleWorldLocation() const
{
	static const FName LeftHand(TEXT("Bip01_L_Hand"));
	if (PlasmidHands && PlasmidHands->DoesSocketExist(LeftHand))
	{
		return PlasmidHands->GetSocketLocation(LeftHand);
	}
	if (FirstPersonCamera)
	{
		return FirstPersonCamera->GetComponentLocation()
			+ FirstPersonCamera->GetForwardVector() * 35.0f
			- FirstPersonCamera->GetRightVector() * 18.0f
			- FirstPersonCamera->GetUpVector() * 14.0f;
	}
	return GetActorLocation() + FVector(0.0f, 0.0f, BaseEyeHeight);
}

FName AShockPlayer::ResolveGripSocketForWeapon(FName WeaponDefName)
{
	if (!ViewHands || !ViewHands->GetSkeletalMeshAsset() || WeaponDefName.IsNone())
	{
		return NAME_None;
	}

	// Hands skeleton carries a separately named socket per weapon (Pistol, TommyGun, …), not a
	// shared R_Grip. Match the equipped def name; never substitute another weapon's socket.
	if (ViewHands->DoesSocketExist(WeaponDefName))
	{
		return WeaponDefName;
	}

	// Def key is GrenadeLauncher; NEWPlayerHands socket is Launcher (export-firstperson socket name).
	if (WeaponDefName.ToString().Equals(TEXT("GrenadeLauncher"), ESearchCase::IgnoreCase)
		&& ViewHands->DoesSocketExist(FName(TEXT("Launcher"))))
	{
		return FName(TEXT("Launcher"));
	}

	// Def key is ChemicalThrower; NEWPlayerHands socket is Chem (export-firstperson Chem).
	// Without this alias AttachToComponent gets NAME_None → hands component root.
	if (WeaponDefName.ToString().Equals(TEXT("ChemicalThrower"), ESearchCase::IgnoreCase)
		&& ViewHands->DoesSocketExist(FName(TEXT("Chem"))))
	{
		return FName(TEXT("Chem"));
	}

	// Shotgun.uc / Weapons.ini: AttachBone="Launcher" — no Shotgun socket on the hands.
	// WP_ShotgunMesh root is SG_Body; it still attaches here (BioShock AttachToBone).
	if (WeaponDefName.ToString().Equals(TEXT("Shotgun"), ESearchCase::IgnoreCase)
		&& ViewHands->DoesSocketExist(FName(TEXT("Launcher"))))
	{
		return FName(TEXT("Launcher"));
	}

	// Any remaining weapon without a named socket: every per-weapon socket sits on R_grip.
	for (const TCHAR* GripBone : {TEXT("R_grip"), TEXT("R_Grip"), TEXT("Bip01_R_Hand")})
	{
		if (ViewHands->DoesSocketExist(FName(GripBone)))
		{
			return FName(GripBone);
		}
	}

	if (!LoggedMissingGripSockets.Contains(WeaponDefName))
	{
		LoggedMissingGripSockets.Add(WeaponDefName);
		UE_LOG(
			LogTemp,
			Warning,
			TEXT("BIOSHOCK_VIEWMODEL no grip socket for weapon=%s — attach without named socket"),
			*WeaponDefName.ToString());
	}
	return NAME_None;
}

void AShockPlayer::ResolveViewHandsAnimsForWeapon(FName WeaponDefName)
{
	if (WeaponDefName == ViewHandsAnimWeapon && ViewHandsAnimWeapon != NAME_None)
	{
		return;
	}

	ViewHandsAnimWeapon = WeaponDefName;
	ViewHandsEquipAnim = nullptr;
	ViewHandsFidgetAnim = nullptr;
	ViewHandsFireAnim = nullptr;
	ViewHandsReloadAnim = nullptr;
	ViewHandsFireWindupAnim = nullptr;
	ViewHandsFireAltAnim = nullptr;
	ViewHandsReloadLoopAnim = nullptr;
	ViewHandsReloadEndAnim = nullptr;
	ViewHandsOneShotQueue.Reset();

	FViewHandsAnimNames Names;
	if (!TryGetViewHandsAnimNames(WeaponDefName, Names))
	{
		return;
	}

	ViewHandsEquipAnim = LoadViewHandsAnim(Names.Equip);
	ViewHandsFidgetAnim = LoadViewHandsAnim(Names.Fidget);
	ViewHandsFireAnim = LoadViewHandsAnim(Names.Fire);
	ViewHandsReloadAnim = LoadViewHandsAnim(Names.Reload);
	ViewHandsFireWindupAnim = LoadViewHandsAnim(Names.FireWindup);
	ViewHandsFireAltAnim = LoadViewHandsAnim(Names.FireAlt);
	ViewHandsReloadLoopAnim = LoadViewHandsAnim(Names.ReloadLoop);
	ViewHandsReloadEndAnim = LoadViewHandsAnim(Names.ReloadEnd);

	UE_LOG(
		LogTemp,
		Display,
		TEXT("BIOSHOCK_VIEWMODEL_ANIMS weapon=%s equip=%d fidget=%d fire=%d reload=%d"),
		*WeaponDefName.ToString(),
		ViewHandsEquipAnim ? 1 : 0,
		ViewHandsFidgetAnim ? 1 : 0,
		ViewHandsFireAnim ? 1 : 0,
		ViewHandsReloadAnim ? 1 : 0);
}

void AShockPlayer::PlayViewHandsAnimation(UAnimSequence* Sequence, bool bLoop)
{
	if (!ViewHands || !Sequence)
	{
		return;
	}
	// Skip only when the same looping idle is already installed. One-shots (equip/fire/reload)
	// always re-play so automatic fire can restart the fire clip every shot.
	if (bLoop && Sequence == LastViewHandsAnim && !bViewHandsPlayingOneShot)
	{
		return;
	}

	if (UShockViewHandsAnimInstance* Inst = GetViewHandsAnimInstance())
	{
		// Blend: quick settle into the looping fidget, snappier for one-shots, near-instant on
		// a fresh equip. The crossfade removes the hard cut between clips.
		float Blend = 0.06f;
		if (bLoop) { Blend = 0.12f; }
		else if (CurrentViewHandsPhase == EViewHandsPhase::Equip) { Blend = 0.04f; }
		Inst->PlayClip(Sequence, bLoop, Blend);
	}
	else
	{
		ViewHands->PlayAnimation(Sequence, bLoop);
	}
	// Evaluate immediately so socket attachment sees the posed grip, not bind pose.
	ViewHands->TickAnimation(0.0f, /*bNeedsValidRootMotion*/ false);
	ViewHands->RefreshBoneTransforms();
	LastViewHandsAnim = Sequence;

	if (bLoop)
	{
		bViewHandsPlayingOneShot = false;
		ViewHandsOneShotRemaining = 0.0f;
	}
	else
	{
		bViewHandsPlayingOneShot = true;
		ViewHandsOneShotRemaining = Sequence->GetPlayLength();
	}

	SyncEquippedWeaponMeshAnimation(bLoop);
}

void AShockPlayer::PlayViewHandsAnimationChain(const TArray<UAnimSequence*>& Clips, EViewHandsPhase Phase)
{
	ViewHandsOneShotQueue.Reset();
	int32 First = INDEX_NONE;
	for (int32 i = 0; i < Clips.Num(); ++i)
	{
		if (Clips[i])
		{
			if (First == INDEX_NONE) { First = i; }
			else { ViewHandsOneShotQueue.Add(Clips[i]); }
		}
	}
	if (First == INDEX_NONE)
	{
		return;
	}
	CurrentViewHandsPhase = Phase;
	PlayViewHandsAnimation(Clips[First], false);
}

void AShockPlayer::SyncEquippedWeaponMeshAnimation(bool bLoop)
{
	if (!EquippedWeapon)
	{
		return;
	}
	switch (CurrentViewHandsPhase)
	{
	case EViewHandsPhase::Equip:
		EquippedWeapon->PlayEquipMeshAnimation();
		break;
	case EViewHandsPhase::Fidget:
		EquippedWeapon->PlayIdleMeshAnimation();
		break;
	case EViewHandsPhase::Fire:
		EquippedWeapon->PlayFireMeshAnimation();
		break;
	case EViewHandsPhase::Reload:
		// AShockWeapon::Reload already starts the weapon mesh clip.
		break;
	default:
		break;
	}
	(void)bLoop;
}

void AShockPlayer::StartViewHandsForEquippedWeapon()
{
	if (!EquippedWeapon || !ViewHands || !ViewHands->GetSkeletalMeshAsset())
	{
		return;
	}

	// AlignShotgunToHandPose drops the mesh into single-node mode for its measurement — put the
	// crossfading instance back before the equip clip plays.
	if (!GetViewHandsAnimInstance())
	{
		ViewHands->SetAnimInstanceClass(UShockViewHandsAnimInstance::StaticClass());
	}

	const FName DefName = EquippedWeapon->GetWeaponDefName();
	ResolveViewHandsAnimsForWeapon(DefName);
	ViewHandsOneShotQueue.Reset();

	if (ViewHandsEquipAnim)
	{
		CurrentViewHandsPhase = EViewHandsPhase::Equip;
		PlayViewHandsAnimation(ViewHandsEquipAnim, false);
	}
	else if (ViewHandsFidgetAnim)
	{
		CurrentViewHandsPhase = EViewHandsPhase::Fidget;
		PlayViewHandsAnimation(ViewHandsFidgetAnim, true);
	}
	else
	{
		CurrentViewHandsPhase = EViewHandsPhase::None;
		ViewHands->Stop();
		LastViewHandsAnim = nullptr;
		bViewHandsPlayingOneShot = false;
		ViewHandsOneShotRemaining = 0.0f;
	}
}

void AShockPlayer::TickViewHandsAnimation(float DeltaSeconds)
{
	if (!bViewHandsPlayingOneShot)
	{
		return;
	}

	ViewHandsOneShotRemaining = FMath::Max(0.0f, ViewHandsOneShotRemaining - DeltaSeconds);
	if (ViewHandsOneShotRemaining > 0.0f)
	{
		return;
	}

	// Next queued one-shot (wrench Start→strike, shotgun Start→LOOP…→End) before the fidget.
	if (ViewHandsOneShotQueue.Num() > 0)
	{
		UAnimSequence* Next = ViewHandsOneShotQueue[0];
		ViewHandsOneShotQueue.RemoveAt(0);
		if (Next)
		{
			PlayViewHandsAnimation(Next, false);
			return;
		}
	}

	bViewHandsPlayingOneShot = false;
	if (ViewHandsFidgetAnim)
	{
		CurrentViewHandsPhase = EViewHandsPhase::Fidget;
		PlayViewHandsAnimation(ViewHandsFidgetAnim, true);
	}
}

void AShockPlayer::NotifyViewHandsWeaponFired()
{
	// Wrench: alternate Swing_A (with wind-up) and Swing_B so the melee has an over/under
	// variation. Guns: FireAlt/FireWindup are null, so this is just the single fire clip.
	const bool bUseAlt = ViewHandsFireAltAnim && (ViewHandsSwingVariant & 1);
	TArray<UAnimSequence*> Chain;
	if (!bUseAlt && ViewHandsFireWindupAnim)
	{
		Chain.Add(ViewHandsFireWindupAnim);
	}
	Chain.Add(bUseAlt ? ViewHandsFireAltAnim.Get() : ViewHandsFireAnim.Get());
	if (Chain.Num() == 0 || (Chain.Num() == 1 && !Chain[0]))
	{
		return;
	}
	PlayViewHandsAnimationChain(Chain, EViewHandsPhase::Fire);
	if (ViewHandsFireAltAnim)
	{
		ViewHandsSwingVariant ^= 1;
	}
}

void AShockPlayer::NotifyViewHandsWeaponReloadStarted(int32 RoundsToLoad)
{
	if (!ViewHandsReloadAnim)
	{
		return;
	}
	// Single-clip reload (most guns): just the one clip.
	if (!ViewHandsReloadLoopAnim)
	{
		ViewHandsOneShotQueue.Reset();
		CurrentViewHandsPhase = EViewHandsPhase::Reload;
		PlayViewHandsAnimation(ViewHandsReloadAnim, false);
		return;
	}
	// Shell-by-shell (shotgun): Start → LOOP per round → End.
	const int32 Shells = FMath::Clamp(RoundsToLoad, 1, 8);
	TArray<UAnimSequence*> Chain;
	Chain.Add(ViewHandsReloadAnim.Get());
	for (int32 i = 0; i < Shells; ++i)
	{
		Chain.Add(ViewHandsReloadLoopAnim.Get());
	}
	if (ViewHandsReloadEndAnim)
	{
		Chain.Add(ViewHandsReloadEndAnim.Get());
	}
	PlayViewHandsAnimationChain(Chain, EViewHandsPhase::Reload);
}

float AShockPlayer::GetViewHandsReloadPlayLengthForVerify() const
{
	return ViewHandsReloadAnim ? ViewHandsReloadAnim->GetPlayLength() : 0.0f;
}

FName AShockPlayer::GetPlayingViewHandsAnimationNameForVerify() const
{
	if (LastViewHandsAnim)
	{
		return LastViewHandsAnim->GetFName();
	}
	if (ViewHands)
	{
		if (const UAnimSingleNodeInstance* Single =
				Cast<UAnimSingleNodeInstance>(ViewHands->GetAnimInstance()))
		{
			if (const UAnimationAsset* Anim = Single->GetAnimationAsset())
			{
				return Anim->GetFName();
			}
		}
	}
	return NAME_None;
}

void AShockPlayer::AdvanceViewHandsAnimationForVerify(float DeltaSeconds)
{
	if (DeltaSeconds <= 0.0f)
	{
		return;
	}
	TickViewHandsAnimation(DeltaSeconds);
}

FVector AShockPlayer::GetActiveGripSocketWorldLocationForVerify() const
{
	if (ActiveGripSocket.IsNone() || !ViewHands || !ViewHands->DoesSocketExist(ActiveGripSocket))
	{
		return FVector::ZeroVector;
	}
	return ViewHands->GetSocketLocation(ActiveGripSocket);
}

FVector AShockPlayer::GetEquippedWeaponBoundsCenterForVerify() const
{
	if (!EquippedWeapon || !EquippedWeapon->Mesh || !EquippedWeapon->Mesh->GetSkeletalMeshAsset())
	{
		return FVector::ZeroVector;
	}
	EquippedWeapon->Mesh->UpdateBounds();
	return EquippedWeapon->Mesh->Bounds.Origin;
}

FVector AShockPlayer::GetEquippedWeaponRootBoneWorldLocationForVerify() const
{
	if (!EquippedWeapon || !EquippedWeapon->Mesh || EquippedWeapon->Mesh->GetNumBones() <= 0)
	{
		return FVector::ZeroVector;
	}
	return EquippedWeapon->Mesh->GetBoneLocation(EquippedWeapon->Mesh->GetBoneName(0));
}

float AShockPlayer::GetGripToWeaponRootDistanceForVerify() const
{
	const FVector Socket = GetActiveGripSocketWorldLocationForVerify();
	const FVector Root = GetEquippedWeaponRootBoneWorldLocationForVerify();
	if (Socket.IsNearlyZero() && Root.IsNearlyZero())
	{
		return -1.0f;
	}
	return FVector::Dist(Socket, Root);
}

float AShockPlayer::GetGripToWeaponBoundsLateralDistanceForVerify() const
{
	if (!FirstPersonCamera)
	{
		return -1.0f;
	}
	const FVector Socket = GetActiveGripSocketWorldLocationForVerify();
	const FVector BoundsCenter = GetEquippedWeaponBoundsCenterForVerify();
	if (Socket.IsNearlyZero() && BoundsCenter.IsNearlyZero())
	{
		return -1.0f;
	}
	const FTransform CamXform = FirstPersonCamera->GetComponentTransform();
	const FVector SocketCam = CamXform.InverseTransformPosition(Socket);
	const FVector BoundsCam = CamXform.InverseTransformPosition(BoundsCenter);
	return FMath::Abs(BoundsCam.Y - SocketCam.Y);
}

int32 AShockPlayer::GetEquippedWeaponSkeletalMeshComponentCountForVerify() const
{
	if (!EquippedWeapon)
	{
		return 0;
	}
	TArray<USkeletalMeshComponent*> Meshes;
	EquippedWeapon->GetComponents<USkeletalMeshComponent>(Meshes);
	return Meshes.Num();
}

bool AShockPlayer::DoesEquippedWeaponBoneExistForVerify(FName BoneName) const
{
	if (BoneName.IsNone() || !EquippedWeapon || !EquippedWeapon->Mesh)
	{
		return false;
	}
	return EquippedWeapon->Mesh->GetBoneIndex(BoneName) != INDEX_NONE;
}

float AShockPlayer::GetEquippedWeaponBoneDistanceForVerify(FName BoneA, FName BoneB) const
{
	if (!EquippedWeapon || !EquippedWeapon->Mesh)
	{
		return -1.0f;
	}
	USkeletalMeshComponent* WeaponMesh = EquippedWeapon->Mesh;
	if (WeaponMesh->GetBoneIndex(BoneA) == INDEX_NONE || WeaponMesh->GetBoneIndex(BoneB) == INDEX_NONE)
	{
		return -1.0f;
	}
	WeaponMesh->RefreshBoneTransforms();
	return FVector::Dist(WeaponMesh->GetBoneLocation(BoneA), WeaponMesh->GetBoneLocation(BoneB));
}

void AShockPlayer::PlaceViewHandsFixed()
{
	if (!FirstPersonCamera || !ViewHands)
	{
		return;
	}

	// BioShock Hands.UpdateLocation: PlayerViewOffset (0,0,0) at the eye. Mesh origin on the
	// camera; authored clips place R_Grip. Do NOT subtract the animated socket — that cancels
	// the arm motion the weapon must inherit (docs/research/viewmodel.md).
	FVector DesiredLocal = ViewmodelOffset;
	FRotator DesiredRotation = ViewmodelRotation;
	{
		const auto ParseTriple = [](const TCHAR* Key, float& A, float& B, float& C) -> bool
		{
			FString Value;
			if (!FParse::Value(FCommandLine::Get(), Key, Value, /*bShouldStopOnSeparator*/ false))
			{
				return false;
			}
			TArray<FString> Parts;
			Value.ParseIntoArray(Parts, TEXT(","));
			if (Parts.Num() != 3)
			{
				UE_LOG(LogTemp, Warning,
					TEXT("BIOSHOCK_VIEWMODEL %s expects three comma-separated numbers, got '%s'"),
					Key, *Value);
				return false;
			}
			A = FCString::Atof(*Parts[0]);
			B = FCString::Atof(*Parts[1]);
			C = FCString::Atof(*Parts[2]);
			return true;
		};

		float X = 0.0f, Y = 0.0f, Z = 0.0f;
		if (ParseTriple(TEXT("bioshockvmoffset="), X, Y, Z))
		{
			DesiredLocal = FVector(X, Y, Z);
		}
		if (ParseTriple(TEXT("bioshockvmrot="), X, Y, Z))
		{
			DesiredRotation = FRotator(X, Y, Z);
		}
	}

	ViewHands->SetRelativeRotation(DesiredRotation);
	ViewHands->SetRelativeLocation(DesiredLocal);
	ViewHands->RefreshBoneTransforms();

	if (!bLoggedViewmodelFraming)
	{
		bLoggedViewmodelFraming = true;
		UE_LOG(LogTemp, Display, TEXT("BIOSHOCK_VIEWMODEL fixed offset=%s rot=%s"),
			*DesiredLocal.ToCompactString(), *DesiredRotation.ToCompactString());
	}
}

void AShockPlayer::AlignEquippedWeaponRootToGripSocket()
{
	// context.md CONFIRMED: for R_grip-rooted guns the root bone IS the hands' socket.
	// SnapToTarget puts the mesh *component origin* on the socket. After FBX import those two are
	// not always the same point — cancel the root-bone component-space transform so the root
	// bone lands on the socket. Same rule for Shotgun (SG_Body): BioShock AttachToBone places the
	// mesh root on Launcher; aligning SG_Body to the socket is that semantics, not a fudge.
	if (!EquippedWeapon)
	{
		return;
	}
	USkeletalMeshComponent* WeaponMesh = EquippedWeapon->Mesh;
	if (!WeaponMesh || !WeaponMesh->GetSkeletalMeshAsset() || WeaponMesh->GetNumBones() <= 0)
	{
		return;
	}

	WeaponMesh->RefreshBoneTransforms();
	const FName RootBoneName = WeaponMesh->GetBoneName(0);

	// Shotgun root is SG_Body (the gun body), not a grip bone — there is no root rotation to
	// cancel. It is placed from the posed hands instead (AlignShotgunToHandPose, called from
	// EquipWeapon after the fidget starts): SG_Body → the grip socket, barrel (SG_Body→SG_Pump)
	// → the hand-to-hand line. Nothing to do in the FBX root-cancel path.
	if (EquippedWeapon->GetWeaponDefName().ToString().Equals(TEXT("Shotgun"), ESearchCase::IgnoreCase))
	{
		UE_LOG(LogTemp, Display, TEXT("BIOSHOCK_VIEWMODEL alignRoot skip weapon=Shotgun root=%s (SG_Body) — hand-pose aligned"),
			*RootBoneName.ToString());
		return;
	}

	const FTransform RootCS = WeaponMesh->GetBoneTransform(RootBoneName, RTS_Component);
	if (RootCS.Equals(FTransform::Identity, 0.05f))
	{
		return;
	}

	WeaponMesh->SetRelativeTransform(RootCS.Inverse());
	WeaponMesh->RefreshBoneTransforms();

	const FVector SocketWorld = (!ActiveGripSocket.IsNone() && ViewHands && ViewHands->DoesSocketExist(ActiveGripSocket))
		? ViewHands->GetSocketLocation(ActiveGripSocket)
		: FVector::ZeroVector;
	const FVector RootWorld = WeaponMesh->GetBoneLocation(RootBoneName);
	UE_LOG(
		LogTemp,
		Display,
		TEXT("BIOSHOCK_VIEWMODEL alignRoot weapon=%s rootCS=%s socketToRoot=%.2f"),
		*EquippedWeapon->GetWeaponDefName().ToString(),
		*RootCS.GetLocation().ToCompactString(),
		FVector::Dist(SocketWorld, RootWorld));
}

void AShockPlayer::AlignShotgunToHandPose()
{
	// The shotgun skeleton has no grip bone (root SG_Body is the receiver body), so it can't
	// self-correct the way every R_grip-rooted gun does. Instead solve its placement from the
	// posed hands: land SG_Body on the grip socket and rotate the barrel (SG_Body → SG_Pump)
	// onto the line between the two hands. Deterministic from the FidgetShotgun pose + the mesh
	// geometry — no tuned offsets. Called once per equip; the result is baked relative to the
	// animated socket so it rides the fidget like the others.
	if (!EquippedWeapon || !ViewHands)
	{
		return;
	}
	if (!EquippedWeapon->GetWeaponDefName().ToString().Equals(TEXT("Shotgun"), ESearchCase::IgnoreCase))
	{
		return;
	}
	USkeletalMeshComponent* Gun = EquippedWeapon->Mesh;
	if (!Gun || !Gun->GetSkeletalMeshAsset())
	{
		return;
	}
	if (Gun->GetBoneIndex(FName(TEXT("SG_Body"))) == INDEX_NONE
		|| Gun->GetBoneIndex(FName(TEXT("SG_Pump"))) == INDEX_NONE)
	{
		UE_LOG(LogTemp, Warning, TEXT("BIOSHOCK_VIEWMODEL shotgun align: SG_Body/SG_Pump missing"));
		return;
	}

	// Measure against the SETTLED FidgetShotgun pose, not whatever is currently installed
	// (the previous weapon's clip — this runs before StartViewHandsForEquippedWeapon). The
	// two-hand hold is only stable ~0.3s into the fidget: a probe of Bip01_L_Hand − R_grip
	// showed a ~12 uu Z jump between fidget frame 0 and the settled pose, which was the "barrel
	// not in the left hand" gap. Resolve this weapon's clips, pose the fidget, bake; StartView
	// then installs the real equip/idle clip.
	ResolveViewHandsAnimsForWeapon(EquippedWeapon->GetWeaponDefName());
	if (ViewHandsFidgetAnim)
	{
		// Single-node pose for the one measurement, then hand the mesh back to the crossfading
		// instance (StartViewHandsForEquippedWeapon, called next, installs the real clip).
		ViewHands->PlayAnimation(ViewHandsFidgetAnim, true);
		ViewHands->SetPosition(0.4f, false);
		ViewHands->TickAnimation(0.0f, false);
		ViewHands->RefreshBoneTransforms();
		Gun->RefreshBoneTransforms();
	}
	else
	{
		UE_LOG(LogTemp, Warning, TEXT("BIOSHOCK_VIEWMODEL shotgun align: no FidgetShotgun to pose against"));
		ViewHands->RefreshBoneTransforms();
		Gun->RefreshBoneTransforms();
	}

	// Left-hand target: the centre of the closed grip — the cylinder the fist wraps sits above
	// the palm, roughly between the knuckle bases and the curled fingertips. Averaging the
	// index/middle MCP (base) and PIP-tip bones lands there; the wrist bone alone put the
	// barrel through the hand and wrist (user PIE 7 Sept).
	const FVector LWrist = ViewHands->GetBoneLocation(FName(TEXT("Bip01_L_Hand")));
	FVector Grip = FVector::ZeroVector;
	int32 GripCount = 0;
	for (const TCHAR* Bone : {TEXT("kBone_L_Index1"), TEXT("kBone_L_Middle1"),
		TEXT("kBone_L_Index3"), TEXT("kBone_L_Middle3")})
	{
		if (ViewHands->GetBoneIndex(FName(Bone)) != INDEX_NONE)
		{
			Grip += ViewHands->GetBoneLocation(FName(Bone));
			++GripCount;
		}
	}
	const FVector LHand = GripCount > 0 ? (Grip / GripCount) : LWrist;
	const FVector RHand = ViewHands->GetBoneLocation(FName(TEXT("Bip01_R_Hand")));
	const FVector GripW = (!ActiveGripSocket.IsNone() && ViewHands->DoesSocketExist(ActiveGripSocket))
		? ViewHands->GetSocketLocation(ActiveGripSocket)
		: RHand;

	// The BARREL LINE is SG_Shell → SG_Pump (both ~4 uu above SG_Body in mesh Z — the receiver
	// body drops below the bore). Using SG_Body → SG_Pump as the axis tilted the whole gun nose-up
	// ~4°, which is why the tube kept clipping the hand. Orient and translate against the true
	// bore instead.
	const FVector ShellW = Gun->GetBoneIndex(FName(TEXT("SG_Shell"))) != INDEX_NONE
		? Gun->GetBoneLocation(FName(TEXT("SG_Shell")))
		: Gun->GetBoneLocation(FName(TEXT("SG_Body")));
	const FVector PumpW = Gun->GetBoneLocation(FName(TEXT("SG_Pump")));
	const FVector BodyW = Gun->GetBoneLocation(FName(TEXT("SG_Body")));

	const FVector CurAxis = (PumpW - ShellW).GetSafeNormal();
	const FVector WantAxis = (LHand - GripW).GetSafeNormal();
	if (CurAxis.IsNearlyZero() || WantAxis.IsNearlyZero())
	{
		return;
	}

	// 1. Turn the bore onto the grip → forestock line.
	FQuat DeltaQ = FQuat::FindBetweenNormals(CurAxis, WantAxis);

	// 2. Roll about that axis so the receiver hangs below the bore (gun local −Z ≈ world down).
	{
		const FVector GunDown = (DeltaQ * Gun->GetComponentQuat()).RotateVector(FVector(0, 0, -1));
		const FVector RefDown = (-FVector::UpVector - WantAxis * (-FVector::UpVector | WantAxis)).GetSafeNormal();
		const FVector CurDown = (GunDown - WantAxis * (GunDown | WantAxis)).GetSafeNormal();
		if (!RefDown.IsNearlyZero() && !CurDown.IsNearlyZero())
		{
			DeltaQ = FQuat::FindBetweenNormals(CurDown, RefDown) * DeltaQ;
		}
	}

	const FQuat NewGunQ = DeltaQ * Gun->GetComponentQuat();

	// 3. Translate so the bore line passes exactly through the left-hand grip point, and SG_Body
	//    sits as near the right-hand grip socket as the fixed mesh geometry allows (exact along
	//    the bore; the perpendicular residual is the receiver drop, which is what we want).
	const FQuat OldQ = Gun->GetComponentQuat();
	const FVector OldLoc = Gun->GetComponentLocation();
	const FVector ShellLocal = OldQ.UnrotateVector(ShellW - OldLoc);
	const FVector BodyLocal = OldQ.UnrotateVector(BodyW - OldLoc);
	const FVector ShellAfter = NewGunQ.RotateVector(ShellLocal) + OldLoc;      // before translate
	const FVector BodyMinusShell = NewGunQ.RotateVector(BodyLocal - ShellLocal);
	const float K = WantAxis | (LHand + BodyMinusShell - GripW);
	const FVector T = LHand - ShellAfter - WantAxis * K;
	const FVector NewGunLoc = OldLoc + T;

	Gun->SetWorldLocationAndRotation(NewGunLoc, NewGunQ);
	Gun->RefreshBoneTransforms();

	// Perpendicular gap from the bore line to the left grip point should be ~0 by construction.
	const FVector NewShellW = Gun->GetBoneLocation(FName(TEXT("SG_Shell")));
	const FVector NewPumpW = Gun->GetBoneLocation(FName(TEXT("SG_Pump")));
	const FVector BoreDir = (NewPumpW - NewShellW).GetSafeNormal();
	const FVector ToL = LHand - NewShellW;
	const float BorePerp = (ToL - BoreDir * (ToL | BoreDir)).Size();
	UE_LOG(
		LogTemp,
		Display,
		TEXT("BIOSHOCK_VIEWMODEL shotgun handPose: bodyToGrip=%.2f borePerpToLGrip=%.2f deltaRot=%s"),
		FVector::Dist(Gun->GetBoneLocation(FName(TEXT("SG_Body"))), GripW),
		BorePerp,
		*DeltaQ.Rotator().ToCompactString());
}

void AShockPlayer::TickHeldFire()
{
	if (!bFireInputHeld || !EquippedWeapon || !EquippedWeapon->IsAutomatic())
	{
		return;
	}
	// Empty mag: do not re-call FireAt every tick (would spam dry-fire feedback). Semi-auto
	// only clicks once on the initial press; automatic should match that once drained.
	if (EquippedWeapon->bEnforceAmmo && EquippedWeapon->GetRoundsInMagazine() <= 0)
	{
		EquippedWeapon->StopFireAudio();
		return;
	}
	TryFireEquippedWeapon();
}

void AShockPlayer::Tick(float DeltaSeconds)
{
	Super::Tick(DeltaSeconds);

	TickViewHandsAnimation(DeltaSeconds);
	TickPlasmidHandsAnimation(DeltaSeconds);
	TickInteractionTrace();
	TickHeldFire();
	TickUnderwaterPostProcess(DeltaSeconds);
	TickViewEffects(DeltaSeconds);

	// UShockSecuritySubsystem is a plain UWorldSubsystem, not UTickableWorldSubsystem -- nothing
	// else drives its alarm-auto-expiry/bot-despawn timers during real play (only the headless
	// verify harness called AdvanceSecurityForVerify before this).
	if (UWorld* World = GetWorld())
	{
		if (UShockSecuritySubsystem* Security = UShockSecuritySubsystem::Get(World))
		{
			Security->TickSecurity(DeltaSeconds);
		}
	}

	// ViewHands stays at the fixed eye-relative transform from PlaceViewHandsFixed. The looping
	// fidget moves R_Grip (via the arm chain) and the weapon attached to that socket rides with it.
}

void AShockPlayer::Landed(const FHitResult& Hit)
{
	Super::Landed(Hit);
	// CMC has usually zeroed Velocity.Z by the time Landed fires; LastFallZSpeed is the downward
	// speed sampled on the final airborne frame in TickViewEffects.
	const float DipStrength = FMath::GetMappedRangeValueClamped(
		FVector2D(180.0f, 1400.0f), FVector2D(1.0f, 9.0f), LastFallZSpeed);
	LandDipVelocity -= DipStrength * 12.0f;
	LastFallZSpeed = 0.0f;
}

void AShockPlayer::TickViewEffects(float DeltaSeconds)
{
	if (!FirstPersonCamera || DeltaSeconds <= 0.0f)
	{
		return;
	}

	// Smooth eye height between stand (BaseEyeHeight) and crouch (CrouchedEyeHeight). UE lerps the
	// capsule half-height over the crouch transition; match that on the camera instead of snapping.
	const float TargetEye = bIsCrouched ? CrouchedEyeHeight : BaseEyeHeight;
	CurrentEyeHeight = FMath::FInterpTo(CurrentEyeHeight, TargetEye, DeltaSeconds, 10.0f);

	// Critically-damped spring for the landing dip back to rest.
	const float Stiffness = 170.0f;
	const float Damping = 2.0f * FMath::Sqrt(Stiffness);
	LandDipVelocity += (-Stiffness * LandDipOffset - Damping * LandDipVelocity) * DeltaSeconds;
	LandDipOffset += LandDipVelocity * DeltaSeconds;
	if (FMath::Abs(LandDipOffset) < 0.01f && FMath::Abs(LandDipVelocity) < 0.01f)
	{
		LandDipOffset = 0.0f;
		LandDipVelocity = 0.0f;
	}

	const UCharacterMovementComponent* Move = GetCharacterMovement();
	if (Move && Move->MovementMode == MOVE_Falling)
	{
		LastFallZSpeed = FMath::Abs(FMath::Min(0.0f, Move->Velocity.Z));
	}

	float BobZ = 0.0f;
	float BobY = 0.0f;
	if (bViewEffectsEnabled && !bMovementDisabled)
	{
		const bool bGrounded = Move && Move->IsMovingOnGround();
		FVector Horizontal = GetVelocity();
		Horizontal.Z = 0.0f;
		const float Speed = Horizontal.Size();
		const float MaxSpeed = Move ? FMath::Max(Move->MaxWalkSpeed, 1.0f) : 450.0f;
		const float SpeedAlpha = bGrounded ? FMath::Clamp(Speed / MaxSpeed, 0.0f, 1.0f) : 0.0f;

		// Step frequency scales a little with speed; ~1.9 Hz walking.
		const float StepHz = 1.75f + 0.9f * SpeedAlpha;
		ViewBobPhase += DeltaSeconds * StepHz * 2.0f * PI;
		ViewBobPhase = FMath::Fmod(ViewBobPhase, 2.0f * PI);

		const float Amp = 1.6f * ViewBobScale * SpeedAlpha;   // vertical, two steps per cycle
		const float AmpLat = 1.1f * ViewBobScale * SpeedAlpha; // lateral, one sway per cycle
		BobZ = FMath::Abs(FMath::Sin(ViewBobPhase)) * Amp - Amp * 0.5f;
		BobY = FMath::Sin(ViewBobPhase * 0.5f) * AmpLat;
	}
	else
	{
		ViewBobPhase = 0.0f;
	}

	ViewEffectsLocalOffset = FVector(0.0f, BobY, CurrentEyeHeight + BobZ + LandDipOffset);
	FirstPersonCamera->SetRelativeLocation(ViewEffectsLocalOffset);
}

void AShockPlayer::TickUnderwaterPostProcess(float DeltaSeconds)
{
	if (!FirstPersonCamera)
	{
		return;
	}

	const bool bInWater = AShockWaterVolume::IsActorInWater(this);
	const float Target = bInWater ? 1.0f : 0.0f;
	const float FadeRate = 1.0f / FMath::Max(UnderwaterFadeSeconds, 0.01f);
	UnderwaterBlend = FMath::FInterpConstantTo(UnderwaterBlend, Target, DeltaSeconds, FadeRate);

	FPostProcessSettings& PPS = FirstPersonCamera->PostProcessSettings;
	// Keep the manual-exposure pin from the constructor (must stay at blend weight 1).
	FirstPersonCamera->PostProcessBlendWeight = 1.0f;

	const float W = UnderwaterBlend;
	const bool bActive = W > 0.001f;

	// Blue-green colour grade (APPROXIMATION of BioShock's underwater look — not a shipped LUT).
	PPS.bOverride_SceneColorTint = bActive;
	PPS.SceneColorTint = FMath::Lerp(
		FLinearColor::White,
		FLinearColor(0.42f, 0.78f, 0.88f),
		W);

	PPS.bOverride_ColorSaturation = bActive;
	PPS.ColorSaturation = FVector4(
		FMath::Lerp(1.0f, 0.75f, W),
		FMath::Lerp(1.0f, 0.85f, W),
		FMath::Lerp(1.0f, 1.05f, W),
		1.0f);

	PPS.bOverride_ColorContrast = bActive;
	PPS.ColorContrast = FVector4(
		FMath::Lerp(1.0f, 0.92f, W),
		FMath::Lerp(1.0f, 0.95f, W),
		FMath::Lerp(1.0f, 1.0f, W),
		1.0f);

	// Slight murk / bloom stand-in for exponential fog (world fog is a separate concern).
	PPS.bOverride_BloomIntensity = bActive;
	PPS.BloomIntensity = FMath::Lerp(0.675f, 1.35f, W);

	PPS.bOverride_VignetteIntensity = bActive;
	PPS.VignetteIntensity = FMath::Lerp(0.0f, 0.45f, W);

	// Chromatic edge.
	PPS.bOverride_SceneFringeIntensity = bActive;
	PPS.SceneFringeIntensity = 2.0f * W;

	// Soft blur via DOF — cheap, gated; not a shipped underwater shader.
	PPS.bOverride_DepthOfFieldFstop = bActive;
	PPS.DepthOfFieldFstop = FMath::Lerp(22.0f, 4.0f, W);
	PPS.bOverride_DepthOfFieldFocalDistance = bActive;
	PPS.DepthOfFieldFocalDistance = FMath::Lerp(10000.0f, 280.0f, W);
	PPS.bOverride_DepthOfFieldDepthBlurAmount = bActive;
	PPS.DepthOfFieldDepthBlurAmount = 0.4f * W;
}

void AShockPlayer::AdvanceUnderwaterPostProcessForVerify(float DeltaSeconds)
{
	TickUnderwaterPostProcess(DeltaSeconds);
}

bool AShockPlayer::IsInWaterForVerify() const
{
	return AShockWaterVolume::IsActorInWater(this);
}

void AShockPlayer::EquipWeapon(AShockWeapon* Weapon)
{
	EquippedWeapon = Weapon;
	if (!Weapon)
	{
		return;
	}
	// Raising a weapon puts the plasmid arm away (BioShock switches between them).
	SetPlasmidHandActive(false);

	Weapon->SetOwner(this);
	EnsureViewHands();

	const FName DefName = Weapon->GetWeaponDefName();
	const FName GripSocket = ResolveGripSocketForWeapon(DefName);
	if (ViewHands && ViewHands->GetSkeletalMeshAsset())
	{
		bLoggedViewmodelFraming = false;
		PlaceViewHandsFixed();
		Weapon->AttachToComponent(
			ViewHands,
			FAttachmentTransformRules::SnapToTargetNotIncludingScale,
			GripSocket);
		ActiveGripSocket = GripSocket;
		AlignEquippedWeaponRootToGripSocket();
		// Shotgun placement is solved against the settled fidget pose, which this poses itself;
		// StartViewHandsForEquippedWeapon then installs the real equip/idle clip.
		AlignShotgunToHandPose();
		StartViewHandsForEquippedWeapon();
	}
	else if (FirstPersonCamera)
	{
		Weapon->AttachToComponent(
			FirstPersonCamera,
			FAttachmentTransformRules::SnapToTargetNotIncludingScale);
		Weapon->SetActorRelativeLocation(FVector(28.0f, 10.0f, -14.0f));
		ActiveGripSocket = NAME_None;
	}

	Weapon->SetActorHiddenInGame(false);
	if (USkeletalMeshComponent* WeaponMesh = Weapon->FindComponentByClass<USkeletalMeshComponent>())
	{
		WeaponMesh->SetOnlyOwnerSee(false);
		WeaponMesh->SetOwnerNoSee(false);
		WeaponMesh->SetCastShadow(false);
		WeaponMesh->SetCollisionEnabled(ECollisionEnabled::NoCollision);
	}
	if (UStaticMeshComponent* WeaponStatic = Weapon->StaticMesh)
	{
		WeaponStatic->SetOnlyOwnerSee(false);
		WeaponStatic->SetOwnerNoSee(false);
		WeaponStatic->SetCastShadow(false);
		WeaponStatic->SetCollisionEnabled(ECollisionEnabled::NoCollision);
		if (WeaponStatic->GetStaticMesh())
		{
			WeaponStatic->SetHiddenInGame(false);
			WeaponStatic->SetVisibility(true);
			// Mesh root must stay visible so the StaticMesh child renders; clear skeletal only.
			if (Weapon->Mesh)
			{
				Weapon->Mesh->SetSkeletalMesh(nullptr);
				Weapon->Mesh->SetHiddenInGame(false);
				Weapon->Mesh->SetVisibility(true);
			}
		}
	}

	UE_LOG(
		LogTemp,
		Display,
		TEXT("BIOSHOCK_VIEWMODEL hands=%d socket=%s weapon=%s auto=%d"),
		(ViewHands && ViewHands->GetSkeletalMeshAsset()) ? 1 : 0,
		*GripSocket.ToString(),
		*DefName.ToString(),
		Weapon->IsAutomatic() ? 1 : 0);
}

void AShockPlayer::UpdateWeaponSlotVisibility(int32 VisibleSlot)
{
	for (int32 Index = 0; Index < WeaponSlots.Num(); ++Index)
	{
		if (AShockWeapon* SlotWeapon = WeaponSlots[Index].Get())
		{
			SlotWeapon->SetActorHiddenInGame(Index != VisibleSlot);
		}
	}
}

AShockWeapon* AShockPlayer::GiveWeaponByDef(FName DefName, int32 Slot)
{
	if (DefName.IsNone() || Slot < 0 || Slot >= WeaponSlots.Num())
	{
		return nullptr;
	}

	UWorld* World = GetWorld();
	if (!World)
	{
		return nullptr;
	}

	if (AShockWeapon* Existing = WeaponSlots[Slot].Get())
	{
		if (EquippedWeapon == Existing)
		{
			EquippedWeapon = nullptr;
		}
		Existing->Destroy();
		WeaponSlots[Slot] = nullptr;
	}

	FActorSpawnParameters Params;
	Params.Owner = this;
	Params.Instigator = this;
	AShockWeapon* Weapon = World->SpawnActor<AShockWeapon>(
		AShockWeapon::StaticClass(),
		GetActorLocation(),
		GetActorRotation(),
		Params);
	if (!Weapon)
	{
		return nullptr;
	}

	if (UShockWeaponDef* Def = UShockWeaponDef::Resolve(DefName))
	{
		Weapon->ApplyDef(Def);
		Weapon->InitializeAmmoFullMag(Def->ReserveAmmo);
	}

	Weapon->SetOwner(this);
	Weapon->SetActorHiddenInGame(true);
	WeaponSlots[Slot] = Weapon;
	return Weapon;
}

AShockWeapon* AShockPlayer::GiveWeapon(TSubclassOf<AShockWeapon> WeaponClass, int32 Slot)
{
	if (!WeaponClass || Slot < 0 || Slot >= WeaponSlots.Num())
	{
		return nullptr;
	}

	UWorld* World = GetWorld();
	if (!World)
	{
		return nullptr;
	}

	if (AShockWeapon* Existing = WeaponSlots[Slot].Get())
	{
		if (EquippedWeapon == Existing)
		{
			EquippedWeapon = nullptr;
		}
		Existing->Destroy();
		WeaponSlots[Slot] = nullptr;
	}

	FActorSpawnParameters Params;
	Params.Owner = this;
	Params.Instigator = this;
	AShockWeapon* Weapon = World->SpawnActor<AShockWeapon>(
		WeaponClass,
		GetActorLocation(),
		GetActorRotation(),
		Params);
	if (!Weapon)
	{
		return nullptr;
	}

	Weapon->SetOwner(this);
	Weapon->SetActorHiddenInGame(true);
	WeaponSlots[Slot] = Weapon;
	return Weapon;
}

AShockWeapon* AShockPlayer::GetWeaponInSlot(int32 Slot) const
{
	if (Slot < 0 || Slot >= WeaponSlots.Num())
	{
		return nullptr;
	}
	return WeaponSlots[Slot].Get();
}

bool AShockPlayer::IsWeaponSlotHidden(int32 Slot) const
{
	const AShockWeapon* Weapon = GetWeaponInSlot(Slot);
	return Weapon ? Weapon->IsHidden() : true;
}

bool AShockPlayer::SelectWeaponSlot(int32 Slot)
{
	if (Slot < 0 || Slot >= WeaponSlots.Num())
	{
		return false;
	}

	AShockWeapon* Weapon = WeaponSlots[Slot].Get();
	if (!Weapon)
	{
		return false;
	}

	ActiveWeaponSlot = Slot;
	UpdateWeaponSlotVisibility(Slot);
	EquipWeapon(Weapon);
	return true;
}

bool AShockPlayer::SelectPlasmidSlot(int32 Slot)
{
	if (Slot < 0 || Slot >= EquippedPlasmids.Num())
	{
		return false;
	}
	if (!EquippedPlasmids[Slot].Get())
	{
		return false;
	}
	ActivePlasmidSlot = Slot;
	SetPlasmidHandActive(true);
	return true;
}

void AShockPlayer::NextWeapon()
{
	if (WeaponSlots.Num() <= 0)
	{
		return;
	}

	const int32 Start = ActiveWeaponSlot >= 0 ? ActiveWeaponSlot : 0;
	for (int32 Step = 1; Step <= WeaponSlots.Num(); ++Step)
	{
		const int32 NextSlot = (Start + Step) % WeaponSlots.Num();
		if (WeaponSlots[NextSlot].Get())
		{
			SelectWeaponSlot(NextSlot);
			return;
		}
	}
}

void AShockPlayer::PrevWeapon()
{
	if (WeaponSlots.Num() <= 0)
	{
		return;
	}

	const int32 Start = ActiveWeaponSlot >= 0 ? ActiveWeaponSlot : 0;
	for (int32 Step = 1; Step <= WeaponSlots.Num(); ++Step)
	{
		const int32 PrevSlot = (Start - Step + WeaponSlots.Num()) % WeaponSlots.Num();
		if (WeaponSlots[PrevSlot].Get())
		{
			SelectWeaponSlot(PrevSlot);
			return;
		}
	}
}

void AShockPlayer::HandleWeaponNextInput()
{
	NextWeapon();
}

void AShockPlayer::HandleWeaponPrevInput()
{
	PrevWeapon();
}

void AShockPlayer::HandleWeaponSlot1Input()
{
	SelectWeaponSlot(0);
}

void AShockPlayer::HandleWeaponSlot2Input()
{
	SelectWeaponSlot(1);
}

void AShockPlayer::HandleWeaponSlot3Input()
{
	SelectWeaponSlot(2);
}

void AShockPlayer::HandleWeaponSlot4Input()
{
	SelectWeaponSlot(3);
}

void AShockPlayer::HandleWeaponSlot5Input()
{
	// Keys 1..N map to slots 0..N-1. Slot 4 is GrenadeLauncher — do not skip it
	// (the pre-h14 hole left Key 5 → ChemicalThrower / slot 5 and Key 6 → Crossbow).
	SelectWeaponSlot(4);
}

void AShockPlayer::HandleWeaponSlot6Input()
{
	SelectWeaponSlot(5);
}

void AShockPlayer::HandleWeaponSlot7Input()
{
	SelectWeaponSlot(6);
}

void AShockPlayer::HandleFireReleasedInput()
{
	bFireInputHeld = false;
	if (EquippedWeapon)
	{
		EquippedWeapon->StopBeam();
		EquippedWeapon->StopFireAudio();
	}
}

void AShockPlayer::EnablePlayableInput(bool bEnable)
{
	bPlayableInputEnabled = bEnable;
}

void AShockPlayer::DriveFireInputForVerify(bool bPressed)
{
	if (bPressed)
	{
		HandleFireInput();
	}
	else
	{
		HandleFireReleasedInput();
	}
}

void AShockPlayer::DriveWeaponSlotInputForVerify(int32 SlotOneBased)
{
	// Same dispatch SetupPlayerInputComponent binds to WeaponSlotN ActionMappings.
	switch (SlotOneBased)
	{
	case 1:
		HandleWeaponSlot1Input();
		break;
	case 2:
		HandleWeaponSlot2Input();
		break;
	case 3:
		HandleWeaponSlot3Input();
		break;
	case 4:
		HandleWeaponSlot4Input();
		break;
	case 5:
		HandleWeaponSlot5Input();
		break;
	case 6:
		HandleWeaponSlot6Input();
		break;
	case 7:
		HandleWeaponSlot7Input();
		break;
	default:
		break;
	}
}

void AShockPlayer::AdvanceHeldFireForVerify(float DeltaSeconds)
{
	if (DeltaSeconds <= 0.0f)
	{
		return;
	}
	if (EquippedWeapon)
	{
		EquippedWeapon->AdvanceFireRateClockForVerify(DeltaSeconds);
	}
	TickHeldFire();
}

bool AShockPlayer::TryFireEquippedWeapon()
{
	if (!EquippedWeapon)
	{
		return false;
	}

	FVector Start = GetActorLocation();
	if (FirstPersonCamera)
	{
		Start = FirstPersonCamera->GetComponentLocation();
	}
	else if (UCameraComponent* Cam = FindComponentByClass<UCameraComponent>())
	{
		Start = Cam->GetComponentLocation();
	}
	else
	{
		Start.Z += BaseEyeHeight;
	}

	FRotator Aim = GetActorRotation();
	if (AController* C = GetController())
	{
		Aim = C->GetControlRotation();
	}

	return EquippedWeapon->FireAt(this, Start, Aim.Vector());
}

void AShockPlayer::ApplyWeaponRecoil()
{
	static constexpr float KickDegrees = 0.6f;

	// ACCUMULATE the kick into what recovery still owes; do not reset the budget. Resetting it
	// granted a fresh full 0.6 degrees of recovery for a kick that had already been partly repaid,
	// so every shot landing mid-recovery returned more pitch than it took. Under sustained
	// automatic fire (TommyGun, 10 rounds/sec against a 0.12s recovery) that surplus compounded
	// and walked the camera up into the ceiling.
	WeaponRecoilKickRemaining += KickDegrees;
	WeaponRecoilKickTotal = WeaponRecoilKickRemaining;

	if (AController* C = GetController())
	{
		FRotator Rot = C->GetControlRotation();
		// ClampAngle (same path as APlayerCameraManager::LimitViewPitch), not raw Clamp.
		// GetControlRotation().Pitch is often a wrapped equivalent outside [-90, 90] (e.g. 350 for
		// "-10 looking down"). FMath::Clamp(350 - Kick, -89, 89) snaps straight to +89 (ceiling)
		// on the first shot; ClampAngle normalizes before limiting.
		Rot.Pitch = FMath::ClampAngle(Rot.Pitch - KickDegrees, -89.0f, 89.0f);
		C->SetControlRotation(Rot);
	}

	if (UWorld* World = GetWorld())
	{
		// Only arm it when it is not already recovering — re-arming restarts the interval and
		// stretches recovery out under fire.
		if (!World->GetTimerManager().IsTimerActive(WeaponRecoilTimerHandle))
		{
			World->GetTimerManager().SetTimer(
				WeaponRecoilTimerHandle,
				this,
				&AShockPlayer::TickWeaponRecoil,
				0.01f,
				true);
		}
	}
}

void AShockPlayer::EnsureControllerForVerify()
{
	if (!GetController())
	{
		SpawnDefaultController();
	}
}

float AShockPlayer::GetControlRotationPitchForVerify() const
{
	if (const AController* C = GetController())
	{
		return C->GetControlRotation().Pitch;
	}
	return 0.0f;
}

void AShockPlayer::SetControlRotationPitchForVerify(float PitchDegrees)
{
	EnsureControllerForVerify();
	if (AController* C = GetController())
	{
		FRotator Rot = C->GetControlRotation();
		Rot.Pitch = PitchDegrees;
		C->SetControlRotation(Rot);
	}
}

void AShockPlayer::AdvanceWeaponRecoilForVerify(float DeltaSeconds)
{
	if (DeltaSeconds <= 0.0f || WeaponRecoilKickRemaining <= KINDA_SMALL_NUMBER)
	{
		WeaponRecoilKickRemaining = 0.0f;
		if (UWorld* World = GetWorld())
		{
			World->GetTimerManager().ClearTimer(WeaponRecoilTimerHandle);
		}
		return;
	}

	const float RecoverRate =
		WeaponRecoilKickTotal > KINDA_SMALL_NUMBER && WeaponRecoilRecoverSeconds > KINDA_SMALL_NUMBER
			? WeaponRecoilKickTotal / WeaponRecoilRecoverSeconds
			: 0.0f;
	const float Step = FMath::Min(RecoverRate * DeltaSeconds, WeaponRecoilKickRemaining);
	if (AController* C = GetController())
	{
		FRotator Rot = C->GetControlRotation();
		Rot.Pitch = FMath::ClampAngle(Rot.Pitch + Step, -89.0f, 89.0f);
		C->SetControlRotation(Rot);
	}
	WeaponRecoilKickRemaining -= Step;
	if (WeaponRecoilKickRemaining <= KINDA_SMALL_NUMBER)
	{
		WeaponRecoilKickRemaining = 0.0f;
		if (UWorld* World = GetWorld())
		{
			World->GetTimerManager().ClearTimer(WeaponRecoilTimerHandle);
		}
	}
}

void AShockPlayer::TickWeaponRecoil()
{
	AdvanceWeaponRecoilForVerify(0.01f);
}

void AShockPlayer::AddResearchPoints(FName Archetype, float Points)
{
	if (Archetype.IsNone() || Points <= 0.0f)
	{
		return;
	}

	const int32 OldLevel = GetResearchLevel(Archetype);
	ResearchPointsByArchetype.FindOrAdd(Archetype) += Points;
	const int32 NewLevel = GetResearchLevel(Archetype);
	if (NewLevel > OldLevel)
	{
		UE_LOG(
			LogTemp,
			Display,
			TEXT("BIOSHOCK_RESEARCH archetype=%s level=%d->%d"),
			*Archetype.ToString(),
			OldLevel,
			NewLevel);
	}
}

int32 AShockPlayer::GetResearchLevel(FName Archetype) const
{
	const float Points = ResearchPointsByArchetype.FindRef(Archetype);
	int32 Level = 0;
	for (int32 Index = 0; Index < ResearchLevelThresholds.Num(); ++Index)
	{
		const float Threshold = ResearchLevelThresholds[Index];
		if (Threshold <= 0.0f)
		{
			continue;
		}
		if (Points >= Threshold)
		{
			Level = Index;
		}
		else
		{
			break;
		}
	}
	return Level;
}

float AShockPlayer::GetResearchDamageMultiplier(FName Archetype) const
{
	return 1.0f + static_cast<float>(GetResearchLevel(Archetype)) * ResearchDamageBonusPerLevel;
}

float AShockPlayer::GetResearchPointsForVerify(FName Archetype) const
{
	return ResearchPointsByArchetype.FindRef(Archetype);
}

TMap<FName, int32> AShockPlayer::GetInventoryStacksForTravel() const
{
	return InventoryStacks;
}

void AShockPlayer::RestoreInventoryStacksForTravel(const TMap<FName, int32>& Stacks)
{
	InventoryStacks = Stacks;
}

void AShockPlayer::HandleFireInput()
{
	bFireInputHeld = true;
	TryFireEquippedWeapon();
}

bool AShockPlayer::TryReloadEquippedWeapon()
{
	if (!EquippedWeapon)
	{
		return false;
	}
	return EquippedWeapon->Reload();
}

void AShockPlayer::HandleReloadInput()
{
	TryReloadEquippedWeapon();
}

void AShockPlayer::HandleAmmoCycleInput()
{
	if (EquippedWeapon)
	{
		EquippedWeapon->CycleAmmoType();
	}
}

bool AShockPlayer::ConsumeEve(float Amount)
{
	if (bInfiniteEve || Amount <= 0.0f)
	{
		return Amount <= 0.0f;
	}
	if (CurrentEve + KINDA_SMALL_NUMBER < Amount)
	{
		return false;
	}
	CurrentEve = FMath::Max(0.0f, CurrentEve - Amount);
	return true;
}

void AShockPlayer::RefillEve(float Amount)
{
	if (Amount <= 0.0f)
	{
		return;
	}
	CurrentEve = FMath::Clamp(CurrentEve + Amount, 0.0f, MaxEve);
}

bool AShockPlayer::EquipPlasmid(TSubclassOf<UShockPlasmid> PlasmidClass, int32 Slot)
{
	if (!PlasmidClass || Slot < 0 || Slot >= EquippedPlasmids.Num())
	{
		return false;
	}

	UShockPlasmid* Instance = NewObject<UShockPlasmid>(this, PlasmidClass);
	if (!Instance)
	{
		return false;
	}
	EquippedPlasmids[Slot] = Instance;
	ActivePlasmidSlot = Slot;
	SetPlasmidHandActive(true);
	return true;
}

void AShockPlayer::ClearAllPlasmids()
{
	for (int32 Index = 0; Index < EquippedPlasmids.Num(); ++Index)
	{
		EquippedPlasmids[Index] = nullptr;
	}
}

void AShockPlayer::GrantOwnedPlasmid(TSubclassOf<UShockPlasmid> PlasmidClass)
{
	if (!PlasmidClass)
	{
		return;
	}
	for (const TSubclassOf<UShockPlasmid>& Existing : OwnedPlasmidClasses)
	{
		if (Existing == PlasmidClass)
		{
			return;
		}
	}
	OwnedPlasmidClasses.Add(PlasmidClass);
}

void AShockPlayer::AddPlasmidSlot()
{
	EquippedPlasmids.Add(nullptr);
}

void AShockPlayer::IncreaseMaxHealth(float Amount)
{
	if (Amount <= 0.0f)
	{
		return;
	}
	EnsureHealthInitialized();
	const float NewMax = GetMaxHealth() + Amount;
	AuthoredMaxHealth = NewMax;
	CurrentHealth = FMath::Min(CurrentHealth + Amount, NewMax);
}

void AShockPlayer::IncreaseMaxEve(float Amount)
{
	if (Amount <= 0.0f)
	{
		return;
	}
	MaxEve += Amount;
	CurrentEve = FMath::Min(CurrentEve + Amount, MaxEve);
}

bool AShockPlayer::TryInteractNearbyStation()
{
	UWorld* World = GetWorld();
	if (!World)
	{
		return false;
	}

	AShockStationBase* Best = nullptr;
	float BestDistSq = TNumericLimits<float>::Max();
	const FVector Origin = GetActorLocation();
	for (TActorIterator<AShockStationBase> It(World); It; ++It)
	{
		AShockStationBase* Station = *It;
		if (!Station)
		{
			continue;
		}
		const float DistSq = FVector::DistSquared(Origin, Station->GetActorLocation());
		const float Range = Station->InteractRadius;
		if (DistSq <= Range * Range && DistSq < BestDistSq)
		{
			BestDistSq = DistSq;
			Best = Station;
		}
	}
	if (!Best)
	{
		return false;
	}
	return Best->TryInteract(this);
}

UShockPlasmid* AShockPlayer::GetActivePlasmid() const
{
	if (ActivePlasmidSlot < 0 || ActivePlasmidSlot >= EquippedPlasmids.Num())
	{
		return nullptr;
	}
	return EquippedPlasmids[ActivePlasmidSlot];
}

float AShockPlayer::GetPlasmidCooldownRemaining() const
{
	const UShockPlasmid* Plasmid = GetActivePlasmid();
	const UWorld* World = GetWorld();
	if (!Plasmid || !World || LastPlasmidCastWorldSeconds < 0.0)
	{
		return 0.0f;
	}
	const double Elapsed = World->GetTimeSeconds() - LastPlasmidCastWorldSeconds;
	return FMath::Max(0.0f, Plasmid->CastCooldown - static_cast<float>(Elapsed));
}

bool AShockPlayer::PerformPlasmidAimTrace(FHitResult& OutHit) const
{
	const UWorld* World = GetWorld();
	if (!World)
	{
		return false;
	}

	FVector Start = GetActorLocation() + FVector(0.0f, 0.0f, BaseEyeHeight);
	FRotator AimRotation = GetControlRotation();
	if (FirstPersonCamera)
	{
		Start = FirstPersonCamera->GetComponentLocation();
		AimRotation = FirstPersonCamera->GetComponentRotation();
	}
	const FVector End = Start + AimRotation.Vector() * PlasmidTraceRange;

	FCollisionQueryParams Params(SCENE_QUERY_STAT(ShockPlasmidCast), false, this);
	FCollisionObjectQueryParams ObjectParams;
	ObjectParams.AddObjectTypesToQuery(ECC_Pawn);
	return World->LineTraceSingleByObjectType(OutHit, Start, End, ObjectParams, Params);
}

bool AShockPlayer::CastActivePlasmid()
{
	UShockPlasmid* Plasmid = GetActivePlasmid();
	UWorld* World = GetWorld();
	if (!Plasmid || !World)
	{
		return false;
	}

	if (Plasmid->EnforcesCastCooldown(this) && GetPlasmidCooldownRemaining() > KINDA_SMALL_NUMBER)
	{
		return false;
	}

	const float EveNeeded = Plasmid->GetCastEveCost(this);
	if (!bInfiniteEve && EveNeeded > KINDA_SMALL_NUMBER && CurrentEve + KINDA_SMALL_NUMBER < EveNeeded)
	{
		return false;
	}

	FHitResult Hit;
	PerformPlasmidAimTrace(Hit);

	if (!Plasmid->Cast(this, Hit))
	{
		return false;
	}

	// Presentation: plasmid arm up, cast gesture, and a burst at the hand (plus one at the hit
	// point for a targeted cast). Plasmids that shape their own FX still spawn theirs on top.
	SetPlasmidHandActive(true);
	PlayActivePlasmidCastAnimation();
	AShockPlasmidFx::SpawnBurst(
		World, Plasmid->CastFxAssetPath, GetPlasmidMuzzleWorldLocation(),
		GetControlRotation(), Plasmid->HandTint, 0.35f, 12.0f);
	if (Hit.bBlockingHit)
	{
		AShockPlasmidFx::SpawnBurst(
			World, Plasmid->CastFxAssetPath, Hit.ImpactPoint,
			Hit.ImpactNormal.Rotation(), Plasmid->HandTint, 0.45f, 16.0f);
	}

	if (!bInfiniteEve && EveNeeded > KINDA_SMALL_NUMBER)
	{
		ConsumeEve(EveNeeded);
	}
	LastPlasmidCastWorldSeconds = World->GetTimeSeconds();
	return true;
}

void AShockPlayer::CycleActivePlasmid()
{
	if (EquippedPlasmids.Num() <= 0)
	{
		return;
	}

	const int32 StartSlot = ActivePlasmidSlot;
	for (int32 Step = 1; Step <= EquippedPlasmids.Num(); ++Step)
	{
		const int32 NextSlot = (StartSlot + Step) % EquippedPlasmids.Num();
		if (EquippedPlasmids[NextSlot])
		{
			ActivePlasmidSlot = NextSlot;
			SetPlasmidHandActive(true);
			return;
		}
	}
}

void AShockPlayer::HandlePlasmidInput()
{
	if (AShockGameMode* GM = GetWorld() ? GetWorld()->GetAuthGameMode<AShockGameMode>() : nullptr)
	{
		GM->OpenPlasmidRadial(this);
	}
}

void AShockPlayer::HandlePlasmidReleasedInput()
{
	if (AShockGameMode* GM = GetWorld() ? GetWorld()->GetAuthGameMode<AShockGameMode>() : nullptr)
	{
		GM->CloseRadial(true);
	}
}

void AShockPlayer::HandlePlasmidCastInput()
{
	CastActivePlasmid();
}

void AShockPlayer::HandleWeaponRadialPressed()
{
	if (AShockGameMode* GM = GetWorld() ? GetWorld()->GetAuthGameMode<AShockGameMode>() : nullptr)
	{
		GM->OpenWeaponRadial(this);
	}
}

void AShockPlayer::HandleWeaponRadialReleased()
{
	if (AShockGameMode* GM = GetWorld() ? GetWorld()->GetAuthGameMode<AShockGameMode>() : nullptr)
	{
		GM->CloseRadial(true);
	}
}

void AShockPlayer::HandleWeaponSelectToggle()
{
	if (AShockGameMode* GM = GetWorld() ? GetWorld()->GetAuthGameMode<AShockGameMode>() : nullptr)
	{
		GM->ToggleWeaponSelect(this);
	}
}

void AShockPlayer::HandleRadialStepLeft()
{
	if (AShockGameMode* GM = GetWorld() ? GetWorld()->GetAuthGameMode<AShockGameMode>() : nullptr)
	{
		GM->StepRadialHover(-1);
	}
}

void AShockPlayer::HandleRadialStepRight()
{
	if (AShockGameMode* GM = GetWorld() ? GetWorld()->GetAuthGameMode<AShockGameMode>() : nullptr)
	{
		GM->StepRadialHover(1);
	}
}

void AShockPlayer::HandleStatusMenuToggle()
{
	if (AShockGameMode* GM = GetWorld() ? GetWorld()->GetAuthGameMode<AShockGameMode>() : nullptr)
	{
		GM->ToggleStatusMenu(this);
	}
}

void AShockPlayer::HandlePauseMenuToggle()
{
	if (AShockGameMode* GM = GetWorld() ? GetWorld()->GetAuthGameMode<AShockGameMode>() : nullptr)
	{
		GM->TogglePauseMenu(this);
	}
}

void AShockPlayer::HandlePlasmidCycleInput()
{
	CycleActivePlasmid();
}

bool AShockPlayer::PerformHackToolTrace(AShockSecurityDevice*& OutDevice) const
{
	OutDevice = nullptr;
	UWorld* World = GetWorld();
	if (!World || !FirstPersonCamera)
	{
		return false;
	}

	const FVector Start = FirstPersonCamera->GetComponentLocation();
	const FVector End = Start + FirstPersonCamera->GetForwardVector() * HackTraceRange;

	FCollisionQueryParams Params(SCENE_QUERY_STAT(ShockHackTool), false, this);
	FHitResult Hit;
	if (!World->LineTraceSingleByChannel(Hit, Start, End, ECC_Visibility, Params))
	{
		return false;
	}

	OutDevice = Cast<AShockSecurityDevice>(Hit.GetActor());
	if (!OutDevice && Hit.GetComponent())
	{
		OutDevice = Cast<AShockSecurityDevice>(Hit.GetComponent()->GetOwner());
	}
	return OutDevice != nullptr;
}

void AShockPlayer::HandleHackToolInput()
{
	AShockSecurityDevice* Device = nullptr;
	if (!PerformHackToolTrace(Device) || !Device)
	{
		return;
	}

	// PLAUSIBLE default difficulty when using the hack-tool key without a minigame.
	TryHackDevice(Device, 0.5f);
}

void AShockPlayer::TickInteractionTrace()
{
	CachedInteractPrompt.Reset();
	CachedInteractActor = nullptr;

	UWorld* World = GetWorld();
	if (!World || !FirstPersonCamera)
	{
		return;
	}
	const FVector Start = FirstPersonCamera->GetComponentLocation();
	const FVector End = Start + FirstPersonCamera->GetForwardVector() * 260.0f;
	FCollisionQueryParams Params(SCENE_QUERY_STAT(ShockInteractTrace), false, this);
	FHitResult Hit;
	if (!World->LineTraceSingleByChannel(Hit, Start, End, ECC_Visibility, Params))
	{
		return;
	}

	AActor* HitActor = Hit.GetActor();
	if (const AShockConsumablePickup* Pickup = Cast<AShockConsumablePickup>(HitActor))
	{
		// Auto-collect pickups (ammo/health/money) grab on touch — no prompt.
		if (Pickup->RequiresInteract())
		{
			CachedInteractActor = HitActor;
			CachedInteractPrompt = FString::Printf(TEXT("Press F to %s"), *Pickup->GetInteractPrompt());
		}
	}
	else if (const AShockSearchableContainer* Container = Cast<AShockSearchableContainer>(HitActor))
	{
		if (!Container->WasSearchedForVerify())
		{
			CachedInteractActor = HitActor;
			CachedInteractPrompt = TEXT("Press F to search");
		}
	}
	else if (const AShockStationBase* Station = Cast<AShockStationBase>(HitActor))
	{
		CachedInteractActor = HitActor;
		CachedInteractPrompt = Station->StationKind == EShockStationKind::HealthStation
			? TEXT("Press F to use the Health Station")
			: TEXT("Press F to use");
	}
}

void AShockPlayer::HandleInteractInput()
{
	if (AActor* Target = CachedInteractActor.Get())
	{
		if (AShockConsumablePickup* Pickup = Cast<AShockConsumablePickup>(Target))
		{
			if (Pickup->TryCollect(this))
			{
				return;
			}
		}
		else if (AShockSearchableContainer* Container = Cast<AShockSearchableContainer>(Target))
		{
			if (Container->Search(this))
			{
				return;
			}
		}
	}

	TryInteractNearbyStation();
}

bool AShockPlayer::TryHackDevice(AShockSecurityDevice* Device, float Difficulty01)
{
	if (!Device || Device->GetAllegiance() == EShockDeviceAllegiance::Disabled)
	{
		return false;
	}

	if (!bInstantHack)
	{
		APlayerController* PC = Cast<APlayerController>(GetController());
		UWorld* World = GetWorld();
		UShockHackingMinigame* Menu = nullptr;
		if (PC)
		{
			Menu = CreateWidget<UShockHackingMinigame>(PC, UShockHackingMinigame::StaticClass());
		}
		else if (World)
		{
			Menu = CreateWidget<UShockHackingMinigame>(World, UShockHackingMinigame::StaticClass());
		}
		if (!Menu)
		{
			UE_LOG(LogTemp, Warning, TEXT("BIOSHOCK_HACK minigame create failed — falling back to instant"));
		}
		else
		{
			Menu->BindDisplayPlayer(this);
			Menu->BindDevice(Device);
			if (PC && !Menu->IsInViewport())
			{
				Menu->AddToViewport(55);
			}
			Menu->OpenMinigame(Difficulty01);
			const FName Label = Device->DeviceLabel.IsNone() ? Device->GetFName() : Device->DeviceLabel;
			UE_LOG(LogTemp, Display, TEXT("BIOSHOCK_HACK label=%s result=minigame"), *Label.ToString());
			return false; // outcome deferred to the pipe puzzle
		}
	}

	const FName Label = Device->DeviceLabel.IsNone() ? Device->GetFName() : Device->DeviceLabel;
	const bool bSuccess = Difficulty01 <= HackSkill + KINDA_SMALL_NUMBER;
	if (bSuccess)
	{
		Device->SetAllegiance(EShockDeviceAllegiance::Friendly);
		SetTurretHacked(Label, true);
		UE_LOG(LogTemp, Display, TEXT("BIOSHOCK_HACK label=%s result=ok"), *Label.ToString());
	}
	else
	{
		UE_LOG(LogTemp, Display, TEXT("BIOSHOCK_HACK label=%s result=fail"), *Label.ToString());
		ApplyAuthoredDamage(HackFailSelfDamage);
	}
	return bSuccess;
}

bool AShockPlayer::UnHackDevice(AShockSecurityDevice* Device)
{
	if (!Device)
	{
		return false;
	}

	const FName Label = Device->DeviceLabel.IsNone() ? Device->GetFName() : Device->DeviceLabel;
	Device->SetAllegiance(EShockDeviceAllegiance::Neutral);
	SetTurretHacked(Label, false);
	return true;
}

void AShockPlayer::MoveForward(float Value)
{
	if (Value == 0.0f || Controller == nullptr || bMovementDisabled)
	{
		return;
	}
	const FRotator YawRot(0.0f, Controller->GetControlRotation().Yaw, 0.0f);
	AddMovementInput(FRotationMatrix(YawRot).GetUnitAxis(EAxis::X), Value);
}

void AShockPlayer::MoveRight(float Value)
{
	if (Value == 0.0f || Controller == nullptr || bMovementDisabled)
	{
		return;
	}
	const FRotator YawRot(0.0f, Controller->GetControlRotation().Yaw, 0.0f);
	AddMovementInput(FRotationMatrix(YawRot).GetUnitAxis(EAxis::Y), Value);
}

void AShockPlayer::TurnAtRate(float Value)
{
	AddControllerYawInput(Value);
}

void AShockPlayer::LookUpAtRate(float Value)
{
	AddControllerPitchInput(Value);
}

void AShockPlayer::HandleJumpPressed()
{
	if (!bMovementDisabled)
	{
		Jump();
	}
}

void AShockPlayer::HandleJumpReleased()
{
	StopJumping();
}

void AShockPlayer::HandleCrouchPressed()
{
	if (!bMovementDisabled)
	{
		Crouch();
	}
}

void AShockPlayer::HandleCrouchReleased()
{
	if (!bForcedCrouch)
	{
		UnCrouch();
	}
}

int32 AShockPlayer::AddStackToInventory(FName ItemClass, int32 StackSize)
{
	if (ItemClass.IsNone() || StackSize <= 0)
	{
		return 0;
	}
	int32& Count = InventoryStacks.FindOrAdd(ItemClass);
	int32 MaxStack = MAX_int32;
	if (ItemClass == FName(TEXT("FirstAidKit")))
	{
		MaxStack = FMath::Max(0, MaxFirstAidKits);
	}
	else if (ItemClass == FName(TEXT("EveHypo")))
	{
		MaxStack = FMath::Max(0, MaxEveHypos);
	}
	Count = FMath::Min(Count + StackSize, MaxStack);
	return Count;
}

int32 AShockPlayer::RemoveStackFromInventory(FName ItemClass, int32 StackSize)
{
	if (ItemClass.IsNone() || StackSize <= 0)
	{
		return 0;
	}
	int32* Count = InventoryStacks.Find(ItemClass);
	if (!Count)
	{
		return 0;
	}
	Count[0] = FMath::Max(0, Count[0] - StackSize);
	return Count[0];
}

int32 AShockPlayer::GetInventoryStack(FName ItemClass) const
{
	if (const int32* Count = InventoryStacks.Find(ItemClass))
	{
		return *Count;
	}
	return 0;
}

float AShockPlayer::GetMaxHealth() const
{
	if (AuthoredMaxHealth > 0.0f)
	{
		return AuthoredMaxHealth;
	}
	if (AuthoredHealth > 0.0f)
	{
		return AuthoredHealth;
	}
	return 100.0f;
}

void AShockPlayer::SetCurrentHealthForVerify(float Value)
{
	EnsureHealthInitialized();
	CurrentHealth = FMath::Clamp(Value, 0.0f, GetMaxHealth());
	if (CurrentHealth > 0.0f)
	{
		bIsDead = false;
		bDeathHandled = false;
	}
}

void AShockPlayer::Heal(float Amount)
{
	if (Amount <= 0.0f)
	{
		return;
	}
	EnsureHealthInitialized();
	const float MaxHealth = GetMaxHealth();
	if (CurrentHealth >= MaxHealth - KINDA_SMALL_NUMBER)
	{
		return;
	}
	CurrentHealth = FMath::Min(CurrentHealth + Amount, MaxHealth);
}

bool AShockPlayer::UseFirstAidKit()
{
	if (GetInventoryStack(FName(TEXT("FirstAidKit"))) <= 0)
	{
		return false;
	}
	EnsureHealthInitialized();
	if (CurrentHealth >= GetMaxHealth() - KINDA_SMALL_NUMBER)
	{
		return false;
	}
	RemoveStackFromInventory(FName(TEXT("FirstAidKit")), 1);
	Heal(FirstAidHealAmount);
	UE_LOG(
		LogTemp,
		Display,
		TEXT("BIOSHOCK_CONSUMABLE item=FirstAidKit health=%.1f"),
		CurrentHealth);
	return true;
}

bool AShockPlayer::UseEveHypo()
{
	if (GetInventoryStack(FName(TEXT("EveHypo"))) <= 0)
	{
		return false;
	}
	if (CurrentEve >= MaxEve - KINDA_SMALL_NUMBER)
	{
		return false;
	}
	RemoveStackFromInventory(FName(TEXT("EveHypo")), 1);
	RefillEve(EveHypoAmount);
	UE_LOG(
		LogTemp,
		Display,
		TEXT("BIOSHOCK_CONSUMABLE item=EveHypo eve=%.1f"),
		CurrentEve);
	return true;
}

void AShockPlayer::AddMoney(int32 Amount)
{
	if (Amount > 0)
	{
		PlayerMoney += Amount;
	}
}

bool AShockPlayer::SpendMoney(int32 Amount)
{
	if (Amount <= 0)
	{
		return true;
	}
	if (PlayerMoney < Amount)
	{
		return false;
	}
	PlayerMoney -= Amount;
	return true;
}

void AShockPlayer::AddAdam(int32 Amount)
{
	if (Amount > 0)
	{
		PlayerAdam += Amount;
	}
}

bool AShockPlayer::SpendAdam(int32 Amount)
{
	if (Amount <= 0)
	{
		return true;
	}
	if (PlayerAdam < Amount)
	{
		return false;
	}
	PlayerAdam -= Amount;
	return true;
}

void AShockPlayer::TryAutoFirstAidAfterDamage()
{
	if (!bAutoFirstAid)
	{
		return;
	}
	const float MaxHealth = GetMaxHealth();
	if (MaxHealth <= 0.0f)
	{
		return;
	}
	if ((CurrentHealth / MaxHealth) < AutoFirstAidThreshold)
	{
		UseFirstAidKit();
	}
}

void AShockPlayer::NoteDamageHit(AActor* DamageInstigator)
{
	UShockAudioLibrary::SpawnEventAttached(TEXT("ShockPlayer"), TEXT("Damaged"), RootComponent);
	UE_LOG(LogTemp, Display, TEXT("BIOSHOCK_AUDIO vocal pawn=Player event=Damaged"));
	if (DamageInstigator)
	{
		LastDamageSourceWorld = DamageInstigator->GetActorLocation();
		bHasLastDamageSource = true;
	}
	else
	{
		LastDamageSourceWorld = FVector::ZeroVector;
		bHasLastDamageSource = false;
	}
}

bool AShockPlayer::TryGetLastDamageSourceWorld(FVector& OutWorldLocation) const
{
	if (!bHasLastDamageSource)
	{
		return false;
	}
	OutWorldLocation = LastDamageSourceWorld;
	return true;
}

void AShockPlayer::HandleUseFirstAidInput()
{
	UseFirstAidKit();
}

void AShockPlayer::HandleUseEveHypoInput()
{
	UseEveHypo();
}

void AShockPlayer::SetForcedCrouch(bool bShouldCrouch)
{
	bForcedCrouch = bShouldCrouch;
	if (UCharacterMovementComponent* Move = GetCharacterMovement())
	{
		Move->GetNavAgentPropertiesRef().bCanCrouch = true;
	}
	if (bShouldCrouch)
	{
		Crouch();
	}
	else
	{
		UnCrouch();
	}
}

void AShockPlayer::SetMovementDisabled(bool bDisable)
{
	bMovementDisabled = bDisable;
	if (UCharacterMovementComponent* Move = GetCharacterMovement())
	{
		if (bDisable)
		{
			Move->DisableMovement();
		}
		else
		{
			Move->SetMovementMode(MOVE_Walking);
		}
	}
}

void AShockPlayer::SetConceptEnabled(FName ConceptName, bool bEnable)
{
	if (ConceptName.IsNone())
	{
		return;
	}
	ConceptEnabled.FindOrAdd(ConceptName) = bEnable;
}

bool AShockPlayer::IsConceptEnabled(FName ConceptName) const
{
	if (ConceptName.IsNone())
	{
		return false;
	}
	if (const bool* Value = ConceptEnabled.Find(ConceptName))
	{
		return *Value;
	}
	return true;
}

void AShockPlayer::SetTipPriority(FName TipName, int32 Priority)
{
	if (TipName.IsNone())
	{
		return;
	}
	TipPriorities.FindOrAdd(TipName) = Priority;
}

int32 AShockPlayer::GetTipPriority(FName TipName) const
{
	if (const int32* Value = TipPriorities.Find(TipName))
	{
		return *Value;
	}
	return 0;
}

namespace
{
	FString MakeFactKey(FName Slot1, const FString& Slot2, const FString& Slot3)
	{
		return Slot1.ToString() + TEXT("|") + Slot2 + TEXT("|") + Slot3;
	}
}

void AShockPlayer::SetScriptedSequenceRunNow(FName SequenceLabel, int32 RunNow)
{
	if (SequenceLabel.IsNone())
	{
		return;
	}
	ScriptedSequenceRunNow.FindOrAdd(SequenceLabel) = RunNow;
}

int32 AShockPlayer::GetScriptedSequenceRunNow(FName SequenceLabel) const
{
	if (const int32* Value = ScriptedSequenceRunNow.Find(SequenceLabel))
	{
		return *Value;
	}
	return 0;
}

void AShockPlayer::SetInputContext(FName Context, bool bUnset)
{
	if (Context.IsNone())
	{
		return;
	}
	LastInputContext = Context;
	if (bUnset)
	{
		for (int32 Index = InputContextStack.Num() - 1; Index >= 0; --Index)
		{
			if (InputContextStack[Index] == Context)
			{
				InputContextStack.RemoveAt(Index);
				break;
			}
		}
		CurrentInputContext = InputContextStack.IsEmpty() ? NAME_None : InputContextStack.Last();
		return;
	}
	InputContextStack.Add(Context);
	CurrentInputContext = Context;
}

void AShockPlayer::SetRegionPressure(FName RegionName, uint8 Pressure)
{
	if (RegionName.IsNone())
	{
		return;
	}
	RegionPressure.FindOrAdd(RegionName) = Pressure;
}

uint8 AShockPlayer::GetRegionPressure(FName RegionName) const
{
	if (const uint8* Value = RegionPressure.Find(RegionName))
	{
		return *Value;
	}
	return 0;
}

void AShockPlayer::AssertFact(FName Slot1, const FString& Slot2, const FString& Slot3)
{
	if (Slot1.IsNone())
	{
		return;
	}
	Facts.Add(MakeFactKey(Slot1, Slot2, Slot3));
}

void AShockPlayer::RetractFact(FName Slot1, const FString& Slot2, const FString& Slot3)
{
	if (Slot1.IsNone())
	{
		return;
	}
	Facts.Remove(MakeFactKey(Slot1, Slot2, Slot3));
}

bool AShockPlayer::HasFact(FName Slot1, const FString& Slot2, const FString& Slot3) const
{
	if (Slot1.IsNone())
	{
		return false;
	}
	return Facts.Contains(MakeFactKey(Slot1, Slot2, Slot3));
}

void AShockPlayer::InitiateQuest(FName QuestName, bool bSetActive)
{
	if (QuestName.IsNone())
	{
		return;
	}
	QuestState.FindOrAdd(QuestName) = 1;
	if (bSetActive)
	{
		ActiveQuest = QuestName;
	}
}

void AShockPlayer::CompleteQuestObjective(FName QuestName, int32 Count)
{
	if (QuestName.IsNone() || Count <= 0)
	{
		return;
	}
	QuestObjectiveCount.FindOrAdd(QuestName) += Count;
}

void AShockPlayer::CompleteQuest(FName QuestName)
{
	if (QuestName.IsNone())
	{
		return;
	}
	QuestState.FindOrAdd(QuestName) = 2;
}

void AShockPlayer::FailQuest(FName QuestName)
{
	if (QuestName.IsNone())
	{
		return;
	}
	QuestState.FindOrAdd(QuestName) = 3;
}

int32 AShockPlayer::GetQuestState(FName QuestName) const
{
	if (const uint8* Value = QuestState.Find(QuestName))
	{
		return *Value;
	}
	return 0;
}

int32 AShockPlayer::GetQuestObjectiveCount(FName QuestName) const
{
	if (const int32* Value = QuestObjectiveCount.Find(QuestName))
	{
		return *Value;
	}
	return 0;
}

void AShockPlayer::GetActiveQuestNames(TArray<FName>& OutNames) const
{
	OutNames.Reset();
	for (const TPair<FName, uint8>& Pair : QuestState)
	{
		if (Pair.Value == 1)
		{
			OutNames.Add(Pair.Key);
		}
	}
	OutNames.Sort([](const FName& A, const FName& B) { return A.LexicalLess(B); });
}

int32 AShockPlayer::GetActiveQuestCount() const
{
	TArray<FName> Names;
	GetActiveQuestNames(Names);
	return Names.Num();
}

void AShockPlayer::SetQuestHint(FName QuestName, FName HintName)
{
	if (QuestName.IsNone())
	{
		return;
	}
	QuestHints.FindOrAdd(QuestName) = HintName;
}

FName AShockPlayer::GetQuestHint(FName QuestName) const
{
	if (const FName* Value = QuestHints.Find(QuestName))
	{
		return *Value;
	}
	return NAME_None;
}

void AShockPlayer::SetAutoSaveCommand(const FString& Command)
{
	LastAutoSaveCommand = Command;
}

void AShockPlayer::SetPendingTimerSeconds(float Seconds)
{
	PendingTimerSeconds = Seconds;
}

void AShockPlayer::StopTimerForScript(FName InScriptLabel)
{
	StoppedTimerLabel = InScriptLabel;
	PendingTimerSeconds = 0.0f;
}

void AShockPlayer::SetMapHUDRegion(const FString& Description)
{
	LastMapHUDRegion = Description;
}

void AShockPlayer::SetTrainingMessage(FName MessageName)
{
	LastTrainingMessage = MessageName;
}

void AShockPlayer::SetFadeVolumeOverride(float Volume, float Duration)
{
	FadeVolumeOverride = Volume;
	FadeVolumeDuration = Duration;
}

void AShockPlayer::SetLevelSavingDisabled(bool bDisable)
{
	bLevelSavingDisabled = bDisable;
}

void AShockPlayer::SetLevelSwitchingDisabled(bool bDisable)
{
	bLevelSwitchingDisabled = bDisable;
}

void AShockPlayer::SetHUDEnabled(bool bEnable)
{
	bHUDEnabled = bEnable;
}

void AShockPlayer::SetResurrectionStationActivated(FName Station, bool bActivated)
{
	if (Station.IsNone())
	{
		return;
	}
	ResurrectionStationActivated.FindOrAdd(Station) = bActivated;
}

bool AShockPlayer::IsResurrectionStationActivated(FName Station) const
{
	if (const bool* Value = ResurrectionStationActivated.Find(Station))
	{
		return *Value;
	}
	return false;
}

void AShockPlayer::SetResurrectionStationEnabled(FName Station, bool bEnabled)
{
	if (Station.IsNone())
	{
		return;
	}
	ResurrectionStationEnabled.FindOrAdd(Station) = bEnabled;
}

bool AShockPlayer::IsResurrectionStationEnabled(FName Station) const
{
	if (const bool* Value = ResurrectionStationEnabled.Find(Station))
	{
		return *Value;
	}
	return true;
}

void AShockPlayer::UnlockBathysphereDestination(FName System, FName MapName)
{
	if (System.IsNone() || MapName.IsNone())
	{
		return;
	}
	UnlockedBathysphereDestinations.Add(FString::Printf(TEXT("%s|%s"), *System.ToString(), *MapName.ToString()));
}

bool AShockPlayer::IsBathysphereDestinationUnlocked(FName System, FName MapName) const
{
	if (System.IsNone() || MapName.IsNone())
	{
		return false;
	}
	return UnlockedBathysphereDestinations.Contains(
		FString::Printf(TEXT("%s|%s"), *System.ToString(), *MapName.ToString()));
}

void AShockPlayer::RemoveAvailableHoldable(FName HoldableClass)
{
	if (HoldableClass.IsNone())
	{
		return;
	}
	RemovedHoldables.Add(HoldableClass);
}

bool AShockPlayer::IsHoldableRemoved(FName HoldableClass) const
{
	return RemovedHoldables.Contains(HoldableClass);
}

void AShockPlayer::SetClientMessage(const FString& Text)
{
	LastClientMessage = Text;
}

void AShockPlayer::SetHUDPlaying(bool bPlaying)
{
	bHUDPlaying = bPlaying;
}

void AShockPlayer::SetSecurityAlarmOn(bool bOn, FName TargetLabel)
{
	const bool bWasOn = bSecurityAlarmOn;
	bSecurityAlarmOn = bOn;
	if (!TargetLabel.IsNone())
	{
		LastAlarmTarget = TargetLabel;
	}

	if (UWorld* World = GetWorld())
	{
		if (UShockSecuritySubsystem* Security = UShockSecuritySubsystem::Get(World))
		{
			Security->OnAlarmStateChanged(this, bOn, bWasOn, TargetLabel);
		}
	}
}

void AShockPlayer::SetSpawnZoneRepopulation(FName Zone, uint8 Aggressor, uint8 Protector)
{
	if (Zone.IsNone())
	{
		return;
	}
	SpawnZoneAggressor.FindOrAdd(Zone) = Aggressor;
	SpawnZoneProtector.FindOrAdd(Zone) = Protector;
}

uint8 AShockPlayer::GetSpawnZoneAggressor(FName Zone) const
{
	if (const uint8* Value = SpawnZoneAggressor.Find(Zone))
	{
		return *Value;
	}
	return 0;
}

void AShockPlayer::SetSpotlightTarget(FName Spotlight, FName Target)
{
	if (Spotlight.IsNone())
	{
		return;
	}
	SpotlightTarget.FindOrAdd(Spotlight) = Target;
}

FName AShockPlayer::GetSpotlightTarget(FName Spotlight) const
{
	if (const FName* Value = SpotlightTarget.Find(Spotlight))
	{
		return *Value;
	}
	return NAME_None;
}

void AShockPlayer::SetSpotlightOn(FName Spotlight, bool bOn)
{
	if (Spotlight.IsNone())
	{
		return;
	}
	SpotlightOn.FindOrAdd(Spotlight) = bOn;
}

bool AShockPlayer::IsSpotlightOn(FName Spotlight) const
{
	if (const bool* Value = SpotlightOn.Find(Spotlight))
	{
		return *Value;
	}
	return false;
}

void AShockPlayer::SetQuestLogWait(FName QuestLogClass)
{
	LastQuestLogWait = QuestLogClass;
}

void AShockPlayer::SetQuestLogPlaying(FName QuestLogClass, bool bPlaying)
{
	if (QuestLogClass.IsNone())
	{
		return;
	}
	if (bPlaying)
	{
		PlayingQuestLogs.Add(QuestLogClass);
	}
	else
	{
		PlayingQuestLogs.Remove(QuestLogClass);
	}
}

bool AShockPlayer::IsQuestLogPlaying(FName QuestLogClass) const
{
	return !QuestLogClass.IsNone() && PlayingQuestLogs.Contains(QuestLogClass);
}

void AShockPlayer::SetMaterialSwitchIndex(FName MaterialSwitch, float Index)
{
	if (MaterialSwitch.IsNone())
	{
		return;
	}
	MaterialSwitchIndex.FindOrAdd(MaterialSwitch) = Index;
}

float AShockPlayer::GetMaterialSwitchIndex(FName MaterialSwitch) const
{
	if (const float* Value = MaterialSwitchIndex.Find(MaterialSwitch))
	{
		return *Value;
	}
	return -1.0f;
}

void AShockPlayer::SetSecurityHacked(bool bHacked, float ShutdownTime)
{
	bSecurityHacked = bHacked;
	SecurityHackShutdownTime = bHacked ? ShutdownTime : 0.0f;
	if (bHacked)
	{
		if (UWorld* World = GetWorld())
		{
			SetSecurityAlarmOn(false, NAME_None);
			AShockSecurityDevice::ForEachDevice(
				World,
				[ShutdownTime](AShockSecurityDevice* Device)
				{
					if (Device)
					{
						Device->ApplySecurityShutdown(ShutdownTime);
					}
				});
			if (UShockSecuritySubsystem* Security = UShockSecuritySubsystem::Get(World))
			{
				Security->ApplySecurityShutdown(ShutdownTime);
			}
		}
	}
}

void AShockPlayer::SetTurretHacked(FName Turret, bool bHacked)
{
	if (Turret.IsNone())
	{
		return;
	}
	TurretHacked.FindOrAdd(Turret) = bHacked;
}

bool AShockPlayer::IsTurretHacked(FName Turret) const
{
	if (const bool* Value = TurretHacked.Find(Turret))
	{
		return *Value;
	}
	return false;
}

void AShockPlayer::SetDoorBroken(FName Door, bool bBroken)
{
	if (Door.IsNone())
	{
		return;
	}
	DoorBroken.FindOrAdd(Door) = bBroken;
}

bool AShockPlayer::IsDoorBroken(FName Door) const
{
	if (const bool* Value = DoorBroken.Find(Door))
	{
		return *Value;
	}
	return false;
}

AShockPlayer* AShockPlayer::FindLocalOrFirst(UWorld* World)
{
	if (!World)
	{
		return nullptr;
	}
	if (APlayerController* PC = World->GetFirstPlayerController())
	{
		if (AShockPlayer* Possessed = Cast<AShockPlayer>(PC->GetPawn()))
		{
			return Possessed;
		}
	}
	for (TActorIterator<AShockPlayer> It(World); It; ++It)
	{
		if (*It)
		{
			return *It;
		}
	}
	return nullptr;
}

void AShockPlayer::SetupPlayerInputComponent(UInputComponent* PlayerInputComponent)
{
	Super::SetupPlayerInputComponent(PlayerInputComponent);
	if (!PlayerInputComponent || !bPlayableInputEnabled)
	{
		return;
	}
	PlayerInputComponent->BindAction(TEXT("Fire"), IE_Pressed, this, &AShockPlayer::HandleFireInput);
	PlayerInputComponent->BindAction(TEXT("Fire"), IE_Released, this, &AShockPlayer::HandleFireReleasedInput);
	PlayerInputComponent->BindAction(TEXT("Reload"), IE_Pressed, this, &AShockPlayer::HandleReloadInput);
	PlayerInputComponent->BindAction(TEXT("AmmoTypeCycle"), IE_Pressed, this, &AShockPlayer::HandleAmmoCycleInput);
	PlayerInputComponent->BindAction(TEXT("Plasmid"), IE_Pressed, this, &AShockPlayer::HandlePlasmidInput);
	PlayerInputComponent->BindAction(TEXT("Plasmid"), IE_Released, this, &AShockPlayer::HandlePlasmidReleasedInput);
	PlayerInputComponent->BindAction(TEXT("PlasmidCast"), IE_Pressed, this, &AShockPlayer::HandlePlasmidCastInput);
	PlayerInputComponent->BindAction(TEXT("PlasmidCycle"), IE_Pressed, this, &AShockPlayer::HandlePlasmidCycleInput);
	PlayerInputComponent->BindAction(TEXT("WeaponRadial"), IE_Pressed, this, &AShockPlayer::HandleWeaponRadialPressed);
	PlayerInputComponent->BindAction(TEXT("WeaponRadial"), IE_Released, this, &AShockPlayer::HandleWeaponRadialReleased);
	PlayerInputComponent->BindAction(TEXT("WeaponSelect"), IE_Pressed, this, &AShockPlayer::HandleWeaponSelectToggle);
	PlayerInputComponent->BindAction(TEXT("HackTool"), IE_Pressed, this, &AShockPlayer::HandleHackToolInput);
	PlayerInputComponent->BindAction(TEXT("Interact"), IE_Pressed, this, &AShockPlayer::HandleInteractInput);
	PlayerInputComponent->BindAction(TEXT("UseFirstAid"), IE_Pressed, this, &AShockPlayer::HandleUseFirstAidInput);
	PlayerInputComponent->BindAction(TEXT("UseEveHypo"), IE_Pressed, this, &AShockPlayer::HandleUseEveHypoInput);
	PlayerInputComponent->BindAction(TEXT("WeaponNext"), IE_Pressed, this, &AShockPlayer::HandleWeaponNextInput);
	PlayerInputComponent->BindAction(TEXT("WeaponPrev"), IE_Pressed, this, &AShockPlayer::HandleWeaponPrevInput);
	PlayerInputComponent->BindAction(TEXT("WeaponSlot1"), IE_Pressed, this, &AShockPlayer::HandleWeaponSlot1Input);
	PlayerInputComponent->BindAction(TEXT("WeaponSlot2"), IE_Pressed, this, &AShockPlayer::HandleWeaponSlot2Input);
	PlayerInputComponent->BindAction(TEXT("WeaponSlot3"), IE_Pressed, this, &AShockPlayer::HandleWeaponSlot3Input);
	PlayerInputComponent->BindAction(TEXT("WeaponSlot4"), IE_Pressed, this, &AShockPlayer::HandleWeaponSlot4Input);
	PlayerInputComponent->BindAction(TEXT("WeaponSlot5"), IE_Pressed, this, &AShockPlayer::HandleWeaponSlot5Input);
	PlayerInputComponent->BindAction(TEXT("WeaponSlot6"), IE_Pressed, this, &AShockPlayer::HandleWeaponSlot6Input);
	PlayerInputComponent->BindAction(TEXT("WeaponSlot7"), IE_Pressed, this, &AShockPlayer::HandleWeaponSlot7Input);
	PlayerInputComponent->BindAction(TEXT("RadialStepLeft"), IE_Pressed, this, &AShockPlayer::HandleRadialStepLeft);
	PlayerInputComponent->BindAction(TEXT("RadialStepRight"), IE_Pressed, this, &AShockPlayer::HandleRadialStepRight);
	PlayerInputComponent->BindAction(TEXT("StatusMenu"), IE_Pressed, this, &AShockPlayer::HandleStatusMenuToggle);
	PlayerInputComponent->BindAction(TEXT("PauseMenu"), IE_Pressed, this, &AShockPlayer::HandlePauseMenuToggle);
	PlayerInputComponent->BindAction(TEXT("Jump"), IE_Pressed, this, &AShockPlayer::HandleJumpPressed);
	PlayerInputComponent->BindAction(TEXT("Jump"), IE_Released, this, &AShockPlayer::HandleJumpReleased);
	PlayerInputComponent->BindAction(TEXT("Crouch"), IE_Pressed, this, &AShockPlayer::HandleCrouchPressed);
	PlayerInputComponent->BindAction(TEXT("Crouch"), IE_Released, this, &AShockPlayer::HandleCrouchReleased);
	PlayerInputComponent->BindAxis(TEXT("MoveForward"), this, &AShockPlayer::MoveForward);
	PlayerInputComponent->BindAxis(TEXT("MoveRight"), this, &AShockPlayer::MoveRight);
	PlayerInputComponent->BindAxis(TEXT("Turn"), this, &AShockPlayer::TurnAtRate);
	PlayerInputComponent->BindAxis(TEXT("LookUp"), this, &AShockPlayer::LookUpAtRate);
}
