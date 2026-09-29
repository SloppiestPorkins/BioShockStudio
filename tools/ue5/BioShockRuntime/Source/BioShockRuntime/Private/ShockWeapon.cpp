#include "ShockWeapon.h"

#include "BaseShockAI.h"
#include "ShockAudioLibrary.h"
#include "Components/AudioComponent.h"
#include "ShockDamageLibrary.h"
#include "ShockElectroBoltPlasmid.h"
#include "ShockPawn.h"
#include "ShockPlayer.h"
#include "ShockProjectile.h"
#include "ShockWaterVolume.h"
#include "ShockWeaponDef.h"
#include "Animation/AnimSequence.h"
#include "Animation/AnimSingleNodeInstance.h"
#include "Components/DecalComponent.h"
#include "Components/MeshComponent.h"
#include "Components/PointLightComponent.h"
#include "Components/SkeletalMeshComponent.h"
#include "Components/StaticMeshComponent.h"
#include "DrawDebugHelpers.h"
#include "Engine/StaticMeshActor.h"
#include "Engine/SkeletalMesh.h"
#include "Engine/StaticMesh.h"
#include "Kismet/GameplayStatics.h"
#include "Materials/Material.h"
#include "Materials/MaterialInterface.h"
#include "PhysicalMaterials/PhysicalMaterial.h"
#include "Particles/ParticleSystem.h"
#include "Particles/ParticleSystemComponent.h"
#include "Misc/CommandLine.h"
#include "Misc/Parse.h"
#include "Engine/World.h"
#include "CollisionQueryParams.h"
#include "TimerManager.h"

namespace
{
struct FShockImpactProfile
{
	FName Surface;
	const TCHAR* DecalPath;
	const TCHAR* FxPath;
	FName Sound;
	FColor StandInColor;
	float DecalSize;
	float DecalLife;
};

FShockImpactProfile ImpactProfileFor(FName Surface, bool bBeam)
{
	if (bBeam)
	{
		const FShockImpactProfile SurfaceProfile = ImpactProfileFor(Surface, false);
		return {
			Surface,
			TEXT("/Game/BioShockFX/Impacts/M_BeamScorch.M_BeamScorch"),
			TEXT("/Game/BioShockFX/Impacts/P_BeamScorch.P_BeamScorch"),
			SurfaceProfile.Sound,
			FColor(255, 120, 35),
			9.0f,
			45.0f};
	}
	if (Surface == FName(TEXT("Metal")))
	{
		return {
			Surface,
			TEXT("/Game/BioShockFX/Impacts/M_BulletHole_Metal.M_BulletHole_Metal"),
			TEXT("/Game/BioShockFX/Impacts/P_Impact_MetalSparks.P_Impact_MetalSparks"),
			TEXT("bullet_hit__MVT_ThickMetal"),
			FColor(255, 205, 80),
			5.5f,
			20.0f};
	}
	if (Surface == FName(TEXT("Wood")))
	{
		return {
			Surface,
			TEXT("/Game/BioShockFX/Impacts/M_BulletHole_Wood.M_BulletHole_Wood"),
			TEXT("/Game/BioShockFX/Impacts/P_Impact_WoodSplinters.P_Impact_WoodSplinters"),
			TEXT("bullet_hit__MVT_Wood"),
			FColor(155, 105, 55),
			6.0f,
			20.0f};
	}
	if (Surface == FName(TEXT("Glass")))
	{
		return {
			Surface,
			TEXT("/Game/BioShockFX/Impacts/M_BulletHole_Glass.M_BulletHole_Glass"),
			TEXT("/Game/BioShockFX/Impacts/P_Impact_GlassShatter.P_Impact_GlassShatter"),
			TEXT("bullet_hit__MVT_ThinGlass"),
			FColor(180, 235, 255),
			7.0f,
			15.0f};
	}
	if (Surface == FName(TEXT("Water")))
	{
		return {
			Surface,
			nullptr,
			TEXT("/Game/BioShockFX/Impacts/P_Impact_WaterSplash.P_Impact_WaterSplash"),
			TEXT("bullet_hit__MVT_Water"),
			FColor(90, 190, 255),
			0.0f,
			0.0f};
	}
	if (Surface == FName(TEXT("Dirt")))
	{
		return {
			Surface,
			TEXT("/Game/BioShockFX/Impacts/M_BulletHole_Dirt.M_BulletHole_Dirt"),
			TEXT("/Game/BioShockFX/Impacts/P_Impact_Dirt.P_Impact_Dirt"),
			TEXT("bullet_hit__MVT_Dirt"),
			FColor(125, 95, 65),
			6.5f,
			18.0f};
	}
	return {
		FName(TEXT("Concrete")),
		TEXT("/Game/BioShockFX/Impacts/M_BulletHole_Concrete.M_BulletHole_Concrete"),
		TEXT("/Game/BioShockFX/Impacts/P_Impact_Concrete.P_Impact_Concrete"),
		TEXT("bullet_hit__MVT_Concrete"),
		FColor(170, 165, 155),
		5.5f,
		20.0f};
}
}

AShockWeapon::AShockWeapon()
{
	PrimaryActorTick.bCanEverTick = false;
	Mesh = CreateDefaultSubobject<USkeletalMeshComponent>(TEXT("Mesh"));
	SetRootComponent(Mesh);
	Mesh->SetCollisionEnabled(ECollisionEnabled::NoCollision);
	Mesh->SetCollisionResponseToAllChannels(ECR_Ignore);
	Mesh->SetCastShadow(false);
	// Same AlwaysTickPose reason as ViewHands: a first-person weapon mesh must keep evaluating
	// its own bones (barrel/hammer/drum) even when bounds briefly go stale.
	Mesh->VisibilityBasedAnimTickOption =
		EVisibilityBasedAnimTickOption::AlwaysTickPoseAndRefreshBones;
	Mesh->SetBoundsScale(4.0f);

	StaticMesh = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("StaticMesh"));
	StaticMesh->SetupAttachment(Mesh);
	StaticMesh->SetCollisionEnabled(ECollisionEnabled::NoCollision);
	StaticMesh->SetCollisionResponseToAllChannels(ECR_Ignore);
	StaticMesh->SetCastShadow(false);
	StaticMesh->SetHiddenInGame(true);
	StaticMesh->SetVisibility(false);
}

void AShockWeapon::ApplyDef(UShockWeaponDef* Def)
{
	if (!Def)
	{
		return;
	}

	FireMode = Def->FireMode;
	HitscanDamage = Def->Damage;
	HitscanRange = Def->Range;
	Spread = Def->Spread;
	MagazineSize = FMath::Max(1, Def->MagazineSize);
	ReserveAmmo = FMath::Max(0, Def->ReserveAmmo);
	FireRate = FMath::Max(0.1f, Def->FireRate);
	bAutomatic = Def->bAutomatic;
	ReloadSeconds = FMath::Max(0.01f, Def->ReloadSeconds);
	MeleeArc = Def->MeleeArc;
	MeleeReach = Def->MeleeReach;
	ProjectileClass = Def->ProjectileClass;
	DefProjectileInitialSpeed = Def->ProjectileInitialSpeed;
	DefProjectileImpactRadius = Def->ProjectileImpactRadius;
	DefProjectileLifeSeconds = Def->ProjectileLifeSeconds;
	DefWeaponName = Def->WeaponName;
	FireSoundCue = Def->FireSoundCue;
	ReloadSoundCue = Def->ReloadSoundCue;
	ImpactSoundCue = Def->ImpactSoundCue;
	PelletCount = FMath::Max(1, Def->PelletCount);
	PelletSpreadDeg = FMath::Max(0.0f, Def->PelletSpreadDeg);
	BeamTickInterval = FMath::Max(0.01f, Def->BeamTickInterval);
	BeamRange = FMath::Max(1.0f, Def->BeamRange);
	BeamStatus = Def->BeamStatus;
	BeamAmmoTickCounter = 0;
	bBeamActive = false;

	if (FireMode == EWeaponFireMode::Beam)
	{
		bEnforceAmmo = true;
		FireRate = BeamTickInterval > KINDA_SMALL_NUMBER ? 1.0f / BeamTickInterval : 10.0f;
	}
	else if (FireMode != EWeaponFireMode::Melee)
	{
		bEnforceAmmo = true;
	}

	AmmoTypes = Def->AmmoTypes;
	AmmoReserves.Reset();
	if (AmmoTypes.Num() > 0)
	{
		for (const FShockAmmoType& Entry : AmmoTypes)
		{
			AmmoReserves.Add(FMath::Max(0, Entry.ReserveAmmo));
		}
		ActiveAmmoTypeIndex = 0;
		ChamberedAmmoTypeIndex = 0;
		SyncActiveAmmoFacingFields();
	}

	if (Mesh && !Def->MeshAssetPath.IsNull())
	{
		UObject* Loaded = Def->MeshAssetPath.TryLoad();
		if (USkeletalMesh* MeshAsset = Cast<USkeletalMesh>(Loaded))
		{
			Mesh->SetSkeletalMesh(MeshAsset);
			Mesh->SetHiddenInGame(false);
			Mesh->SetVisibility(true);
			if (StaticMesh)
			{
				StaticMesh->SetStaticMesh(nullptr);
				StaticMesh->SetHiddenInGame(true);
				StaticMesh->SetVisibility(false);
			}
		}
		else if (UStaticMesh* StaticAsset = Cast<UStaticMesh>(Loaded))
		{
			if (StaticMesh)
			{
				StaticMesh->SetStaticMesh(StaticAsset);
				StaticMesh->SetHiddenInGame(false);
				StaticMesh->SetVisibility(true);

				// The hands rig's "Wrench" socket carries a ~180° rotation, now applied to the
				// imported UE socket itself (BioShockSocketLibrary::RestoreSockets reads the
				// manifest's socket translation/rotation — the FbxExporter carries them). No
				// component-level compensation here any more: SnapToTarget onto the Wrench socket
				// picks the rotation up, and a hack here would double-correct.
				StaticMesh->SetRelativeLocationAndRotation(FVector::ZeroVector, FRotator::ZeroRotator);
			}
			// Clear skeletal asset so nothing draws from Mesh — do NOT hide Mesh itself:
			// StaticMesh is a child of Mesh, and parent HiddenInGame/Visibility hides children.
			Mesh->SetSkeletalMesh(nullptr);
			Mesh->SetHiddenInGame(false);
			Mesh->SetVisibility(true);
		}
	}
}

bool AShockWeapon::IsStaticViewmodelForVerify() const
{
	return StaticMesh && StaticMesh->GetStaticMesh() != nullptr
		&& (Mesh == nullptr || Mesh->GetSkeletalMeshAsset() == nullptr);
}

FSoftObjectPath AShockWeapon::GetStaticMeshAssetPathForVerify() const
{
	if (StaticMesh && StaticMesh->GetStaticMesh())
	{
		return FSoftObjectPath(StaticMesh->GetStaticMesh());
	}
	return FSoftObjectPath();
}

void AShockWeapon::StopBeam()
{
	bBeamActive = false;
	LastBeamImpactSoundSeconds = -1.0;
}

void AShockWeapon::ConfigureHitscan(float InDamage, float InRange)
{
	HitscanDamage = InDamage;
	HitscanRange = InRange;
}

void AShockWeapon::ConfigureAmmo(int32 InMagazineSize, int32 InReserveAmmo, float InFireRate, float InReloadSeconds)
{
	MagazineSize = FMath::Max(1, InMagazineSize);
	ReserveAmmo = FMath::Max(0, InReserveAmmo);
	FireRate = FMath::Max(0.1f, InFireRate);
	ReloadSeconds = FMath::Max(0.01f, InReloadSeconds);
	bEnforceAmmo = true;
}

void AShockWeapon::InitializeAmmoFullMag(int32 InReserveAmmo)
{
	RoundsInMagazine = MagazineSize;
	if (AmmoReserves.Num() > 0)
	{
		AmmoReserves[ActiveAmmoTypeIndex] = FMath::Max(0, InReserveAmmo);
		ReserveAmmo = AmmoReserves[ActiveAmmoTypeIndex];
	}
	else
	{
		ReserveAmmo = FMath::Max(0, InReserveAmmo);
	}
	ChamberedAmmoTypeIndex = ActiveAmmoTypeIndex;
	HitscanDamage = GetDamageForAmmoIndex(ChamberedAmmoTypeIndex);
	LogAmmoState();
}

FName AShockWeapon::GetActiveAmmoTypeName() const
{
	if (AmmoTypes.IsValidIndex(ActiveAmmoTypeIndex))
	{
		return AmmoTypes[ActiveAmmoTypeIndex].Name;
	}
	return NAME_None;
}

void AShockWeapon::SetActiveAmmoTypeIndexForVerify(int32 Index)
{
	if (AmmoTypes.Num() == 0)
	{
		return;
	}
	ActiveAmmoTypeIndex = Index % AmmoTypes.Num();
	ChamberedAmmoTypeIndex = ActiveAmmoTypeIndex;
	SyncActiveAmmoFacingFields();
}

void AShockWeapon::SetAmmoEffectForVerify(int32 Index, EAmmoEffect Effect)
{
	if (AmmoTypes.IsValidIndex(Index))
	{
		AmmoTypes[Index].Effect = Effect;
	}
}

void AShockWeapon::CycleAmmoType()
{
	if (AmmoTypes.Num() <= 1)
	{
		return;
	}

	ActiveAmmoTypeIndex = (ActiveAmmoTypeIndex + 1) % AmmoTypes.Num();
	SyncActiveAmmoFacingFields();

	const FShockAmmoType& Active = AmmoTypes[ActiveAmmoTypeIndex];
	UE_LOG(
		LogTemp,
		Display,
		TEXT("BIOSHOCK_AMMO_TYPE weapon=%s type=%s effect=%s"),
		*DefWeaponName.ToString(),
		*Active.Name.ToString(),
		*AmmoEffectToString(Active.Effect));
}

float AShockWeapon::GetDamageForAmmoIndex(int32 Index) const
{
	if (!AmmoTypes.IsValidIndex(Index))
	{
		return HitscanDamage;
	}
	const float TotalDamage = AmmoTypes[Index].Damage;
	if (FireMode == EWeaponFireMode::Shotgun && PelletCount > 0)
	{
		return TotalDamage / static_cast<float>(PelletCount);
	}
	return TotalDamage;
}

void AShockWeapon::SyncActiveAmmoFacingFields()
{
	if (AmmoReserves.IsValidIndex(ActiveAmmoTypeIndex))
	{
		ReserveAmmo = AmmoReserves[ActiveAmmoTypeIndex];
	}
	if (AmmoTypes.IsValidIndex(ChamberedAmmoTypeIndex))
	{
		HitscanDamage = GetDamageForAmmoIndex(ChamberedAmmoTypeIndex);
	}
}

FString AShockWeapon::AmmoEffectToString(EAmmoEffect Effect)
{
	switch (Effect)
	{
	case EAmmoEffect::ArmorPiercing:
		return TEXT("ArmorPiercing");
	case EAmmoEffect::AntiPersonnel:
		return TEXT("AntiPersonnel");
	case EAmmoEffect::Electric:
		return TEXT("Electric");
	case EAmmoEffect::Incendiary:
		return TEXT("Incendiary");
	case EAmmoEffect::Explosive:
		return TEXT("Explosive");
	default:
		return TEXT("None");
	}
}

void AShockWeapon::ApplyAmmoHitEffect(
	AActor* InstigatorActor,
	AShockPawn* Victim,
	FVector ImpactPoint,
	int32 AmmoIndex)
{
	if (!Victim || !AmmoTypes.IsValidIndex(AmmoIndex))
	{
		return;
	}

	const EAmmoEffect Effect = AmmoTypes[AmmoIndex].Effect;
	if (Effect == EAmmoEffect::None)
	{
		return;
	}

	ABaseShockAI* VictimAI = Cast<ABaseShockAI>(Victim);
	if (!VictimAI)
	{
		return;
	}

	UE_LOG(
		LogTemp,
		Display,
		TEXT("BIOSHOCK_AMMO_EFFECT type=%s target=%s"),
		*AmmoEffectToString(Effect),
		*Victim->GetName());

	switch (Effect)
	{
	case EAmmoEffect::Electric:
		// PLAUSIBLE — shorter stun than Electro Bolt's 2s.
		UShockElectroBoltPlasmid::ApplyElectricStunAndWaterChain(
			InstigatorActor,
			Victim,
			1.0f,
			GetDamageForAmmoIndex(AmmoIndex),
			400.0f);
		break;
	case EAmmoEffect::Incendiary:
		// PLAUSIBLE — Incinerate reference tuning (~3s linger, ~5 dps).
		VictimAI->Ignite(3.0f, 5.0f, InstigatorActor);
		break;
	case EAmmoEffect::Explosive:
		if (UWorld* World = GetWorld())
		{
			// PLAUSIBLE — small radial tick (~150uu) plus direct hit; Burning 6 from weapons-config.
			const float RadialAmount = AmmoTypes[AmmoIndex].Damage * 0.35f;
			UShockDamageLibrary::ApplyRadialDamage(
				World,
				ImpactPoint,
				150.0f,
				RadialAmount,
				InstigatorActor,
				FName(TEXT("ExplosiveAmmo")),
				0.0f);
		}
		VictimAI->Ignite(3.0f, 6.0f, InstigatorActor);
		break;
	case EAmmoEffect::AntiPersonnel:
	case EAmmoEffect::ArmorPiercing:
		// Damage number only — organic vs mechanical split TODO (no mechanical targets in slice).
		break;
	default:
		break;
	}
}

void AShockWeapon::SetAmmoStateForVerify(int32 InMag, int32 InReserve)
{
	RoundsInMagazine = FMath::Clamp(InMag, 0, FMath::Max(1, MagazineSize));
	if (AmmoReserves.IsValidIndex(ActiveAmmoTypeIndex))
	{
		AmmoReserves[ActiveAmmoTypeIndex] = FMath::Max(0, InReserve);
		ReserveAmmo = AmmoReserves[ActiveAmmoTypeIndex];
	}
	else
	{
		ReserveAmmo = FMath::Max(0, InReserve);
	}
	LogAmmoState();
}

int32 AShockWeapon::AddReserveAmmo(int32 Amount)
{
	if (Amount <= 0)
	{
		return ReserveAmmo;
	}
	if (AmmoReserves.IsValidIndex(ActiveAmmoTypeIndex))
	{
		AmmoReserves[ActiveAmmoTypeIndex] += Amount;
		ReserveAmmo = AmmoReserves[ActiveAmmoTypeIndex];
	}
	else
	{
		ReserveAmmo += Amount;
	}
	LogAmmoState();
	return ReserveAmmo;
}

float AShockWeapon::GetMinFireInterval() const
{
	return FireRate > KINDA_SMALL_NUMBER ? 1.0f / FireRate : 0.0f;
}

bool AShockWeapon::CanFireNow(UWorld* World) const
{
	if (!World || (bEnforceAmmo && bIsReloading))
	{
		return false;
	}
	if (!bEnforceAmmo)
	{
		return true;
	}
	const float Interval = GetMinFireInterval();
	if (Interval <= 0.0f || LastFireWorldSeconds < 0.0)
	{
		return true;
	}
	return (World->GetTimeSeconds() - LastFireWorldSeconds) >= static_cast<double>(Interval) - KINDA_SMALL_NUMBER;
}

bool AShockWeapon::CanMeleeNow(UWorld* World) const
{
	if (!World)
	{
		return false;
	}
	const float Interval = GetMinFireInterval();
	if (Interval <= 0.0f || LastMeleeWorldSeconds < 0.0)
	{
		return true;
	}
	return (World->GetTimeSeconds() - LastMeleeWorldSeconds) >= static_cast<double>(Interval) - KINDA_SMALL_NUMBER;
}

void AShockWeapon::LogAmmoState() const
{
	UE_LOG(
		LogTemp,
		Display,
		TEXT("BIOSHOCK_AMMO mag=%d reserve=%d"),
		RoundsInMagazine,
		ReserveAmmo);
}

void AShockWeapon::TryAutoReloadOnEmpty()
{
	if (bAutoReload && RoundsInMagazine <= 0 && ReserveAmmo > 0 && !bIsReloading)
	{
		Reload();
	}
}

bool AShockWeapon::Reload()
{
	if (bIsReloading || RoundsInMagazine >= MagazineSize || ReserveAmmo <= 0)
	{
		return false;
	}

	UWorld* World = GetWorld();
	if (!World)
	{
		return false;
	}

	// Pump shotgun loads shells one at a time — the reload takes longer the more it needs, and
	// the arms play Start → LOOP-per-shell → End instead of one clip.
	const bool bShellByShell = DefWeaponName == FName(TEXT("Shotgun"));
	const int32 ShellsToLoad = FMath::Clamp(MagazineSize - RoundsInMagazine, 1, 8);
	const float EffectiveReload = bShellByShell
		? (0.5f + 0.55f * ShellsToLoad)
		: ReloadSeconds;

	bIsReloading = true;
	ReloadCountdown = EffectiveReload;
	World->GetTimerManager().SetTimer(
		ReloadTimerHandle,
		this,
		&AShockWeapon::FinishReload,
		EffectiveReload,
		false);
	UE_LOG(LogTemp, Display, TEXT("BIOSHOCK_WEAPON_RELOAD start seconds=%.2f"), EffectiveReload);
	PlayReloadAudio();
	// Two-rig performance: ViewHands plays the arms clip; this mesh plays the weapon's own
	// moving parts (barrel hinge, bolt, etc.). h10 only sampled the actor world transform —
	// that proved socket-follow, not that Mesh::PlayAnimation was ever called.
	PlayReloadMeshAnimation();
	if (AShockPlayer* OwnerPlayer = Cast<AShockPlayer>(GetOwner()))
	{
		OwnerPlayer->NotifyViewHandsWeaponReloadStarted(bShellByShell ? ShellsToLoad : 1);
	}
	return true;
}

const TCHAR* AShockWeapon::ResolveReloadMeshAnimLeaf() const
{
	// Leaf names under /Game/BioShockWeapons/WP_<Def>/Animations/ — casing from disk.
	// Hands clips carry the weapon suffix (FastReloadPistol); weapon clips do not (FastReload).
	if (DefWeaponName == FName(TEXT("Pistol")))
	{
		return TEXT("FastReload");
	}
	if (DefWeaponName == FName(TEXT("TommyGun"))
		|| DefWeaponName == FName(TEXT("Crossbow"))
		|| DefWeaponName == FName(TEXT("Shotgun"))
		|| DefWeaponName == FName(TEXT("ChemicalThrower"))
		|| DefWeaponName == FName(TEXT("GrenadeLauncher")))
	{
		return TEXT("Reload");
	}
	return nullptr;
}

const TCHAR* AShockWeapon::ResolveIdleMeshAnimLeaf() const
{
	// Only some weapon rigs ship an idle/fidget; others hold bind pose while hands fidget.
	if (DefWeaponName == FName(TEXT("Shotgun")))
	{
		return TEXT("SingleFrame");
	}
	if (DefWeaponName == FName(TEXT("ChemicalThrower")))
	{
		return TEXT("Fidget");
	}
	return nullptr;
}

const TCHAR* AShockWeapon::ResolveFireMeshAnimLeaf() const
{
	if (DefWeaponName == FName(TEXT("Pistol")))
	{
		return TEXT("FireSingle");
	}
	if (DefWeaponName == FName(TEXT("TommyGun"))
		|| DefWeaponName == FName(TEXT("Shotgun"))
		|| DefWeaponName == FName(TEXT("Crossbow"))
		|| DefWeaponName == FName(TEXT("GrenadeLauncher")))
	{
		return TEXT("Fire");
	}
	if (DefWeaponName == FName(TEXT("ChemicalThrower")))
	{
		return TEXT("FireStart");
	}
	return nullptr;
}

const TCHAR* AShockWeapon::ResolveEquipMeshAnimLeaf() const
{
	if (DefWeaponName == FName(TEXT("TommyGun"))
		|| DefWeaponName == FName(TEXT("GrenadeLauncher")))
	{
		return TEXT("Equip");
	}
	return nullptr;
}

UAnimSequence* AShockWeapon::LoadMeshAnim(const TCHAR* LeafName) const
{
	if (!LeafName || DefWeaponName.IsNone())
	{
		return nullptr;
	}
	const FString Path = FString::Printf(
		TEXT("/Game/BioShockWeapons/WP_%s/Animations/%s.%s"),
		*DefWeaponName.ToString(),
		LeafName,
		LeafName);
	return LoadObject<UAnimSequence>(nullptr, *Path);
}

void AShockWeapon::PlayMeshAnimation(UAnimSequence* Sequence, bool bLoop)
{
	if (!Mesh || !Sequence)
	{
		return;
	}
	Mesh->PlayAnimation(Sequence, bLoop);
	Mesh->TickAnimation(0.0f, /*bNeedsValidRootMotion*/ false);
	Mesh->RefreshBoneTransforms();
	LastMeshAnim = Sequence;
}

void AShockWeapon::PlayMeshAnimLeaf(const TCHAR* Leaf, bool bLoop, const TCHAR* PhaseLog)
{
	if (!Leaf)
	{
		return;
	}
	if (UAnimSequence* Sequence = LoadMeshAnim(Leaf))
	{
		PlayMeshAnimation(Sequence, bLoop);
		UE_LOG(
			LogTemp,
			Display,
			TEXT("BIOSHOCK_WEAPON_MESH_ANIM %s=%s weapon=%s"),
			PhaseLog,
			Leaf,
			*DefWeaponName.ToString());
	}
	else
	{
		UE_LOG(
			LogTemp,
			Warning,
			TEXT("BIOSHOCK_WEAPON_MESH_ANIM missing %s leaf=%s weapon=%s"),
			PhaseLog,
			Leaf,
			*DefWeaponName.ToString());
	}
}

void AShockWeapon::PlayReloadMeshAnimation()
{
	PlayMeshAnimLeaf(ResolveReloadMeshAnimLeaf(), false, TEXT("reload"));
}

void AShockWeapon::PlayIdleMeshAnimation()
{
	PlayMeshAnimLeaf(ResolveIdleMeshAnimLeaf(), true, TEXT("idle"));
}

void AShockWeapon::PlayFireMeshAnimation()
{
	PlayMeshAnimLeaf(ResolveFireMeshAnimLeaf(), false, TEXT("fire"));
}

void AShockWeapon::PlayEquipMeshAnimation()
{
	PlayMeshAnimLeaf(ResolveEquipMeshAnimLeaf(), false, TEXT("equip"));
}

FName AShockWeapon::GetPlayingMeshAnimationNameForVerify() const
{
	if (LastMeshAnim)
	{
		return LastMeshAnim->GetFName();
	}
	if (Mesh)
	{
		if (const UAnimSingleNodeInstance* Single =
				Cast<UAnimSingleNodeInstance>(Mesh->GetAnimInstance()))
		{
			if (const UAnimationAsset* Anim = Single->GetAnimationAsset())
			{
				return Anim->GetFName();
			}
		}
	}
	return NAME_None;
}

void AShockWeapon::FinishReload()
{
	bIsReloading = false;
	ReloadCountdown = 0.0f;
	const int32 Need = MagazineSize - RoundsInMagazine;
	int32 ActiveReserve = ReserveAmmo;
	if (AmmoReserves.IsValidIndex(ActiveAmmoTypeIndex))
	{
		ActiveReserve = AmmoReserves[ActiveAmmoTypeIndex];
	}
	const int32 Transfer = FMath::Min(Need, ActiveReserve);
	RoundsInMagazine += Transfer;
	if (AmmoReserves.IsValidIndex(ActiveAmmoTypeIndex))
	{
		AmmoReserves[ActiveAmmoTypeIndex] -= Transfer;
		ReserveAmmo = AmmoReserves[ActiveAmmoTypeIndex];
	}
	else
	{
		ReserveAmmo -= Transfer;
	}
	ChamberedAmmoTypeIndex = ActiveAmmoTypeIndex;
	HitscanDamage = GetDamageForAmmoIndex(ChamberedAmmoTypeIndex);
	UE_LOG(LogTemp, Display, TEXT("BIOSHOCK_WEAPON_RELOAD done transferred=%d"), Transfer);
	LogAmmoState();
}

void AShockWeapon::AdvanceReloadForVerify(float DeltaSeconds)
{
	if (!bIsReloading || DeltaSeconds <= 0.0f)
	{
		return;
	}
	ReloadCountdown -= DeltaSeconds;
	if (ReloadCountdown > 0.0f)
	{
		return;
	}
	if (UWorld* World = GetWorld())
	{
		World->GetTimerManager().ClearTimer(ReloadTimerHandle);
	}
	FinishReload();
}

void AShockWeapon::ClearFireCooldownForVerify()
{
	LastFireWorldSeconds = -1.0;
	LastMeleeWorldSeconds = -1.0;
}

void AShockWeapon::AdvanceFireRateClockForVerify(float DeltaSeconds)
{
	if (DeltaSeconds <= 0.0f || LastFireWorldSeconds < 0.0)
	{
		return;
	}
	LastFireWorldSeconds -= static_cast<double>(DeltaSeconds);
}

bool AShockWeapon::IsMuzzleFlashLightVisibleForVerify() const
{
	return MuzzleFlashLight && MuzzleFlashLight->IsVisible();
}

void AShockWeapon::AdvanceMuzzleFlashForVerify(float DeltaSeconds)
{
	if (DeltaSeconds <= 0.0f || MuzzleFlashRemaining <= 0.0f)
	{
		return;
	}
	MuzzleFlashRemaining -= DeltaSeconds;
	if (MuzzleFlashRemaining <= 0.0f)
	{
		if (UWorld* World = GetWorld())
		{
			World->GetTimerManager().ClearTimer(MuzzleFlashTimerHandle);
		}
		HideMuzzleFlash();
	}
}

FVector AShockWeapon::ResolveMuzzleLocation(const FVector& TraceStart) const
{
	if (Mesh)
	{
		static const FName SocketCandidates[] = {
			TEXT("Muzzle"),
			TEXT("MuzzleFlash"),
			TEXT("BarrelTip"),
			TEXT("FireSocket")};
		for (const FName Socket : SocketCandidates)
		{
			if (Mesh->DoesSocketExist(Socket))
			{
				return Mesh->GetSocketLocation(Socket);
			}
		}
	}
	return TraceStart;
}

void AShockWeapon::EnsureMuzzleFlashLight()
{
	if (MuzzleFlashLight)
	{
		return;
	}

	MuzzleFlashLight = NewObject<UPointLightComponent>(this, TEXT("MuzzleFlashLight"));
	if (!MuzzleFlashLight)
	{
		return;
	}

	USceneComponent* AttachParent = Mesh ? static_cast<USceneComponent*>(Mesh.Get()) : RootComponent.Get();
	MuzzleFlashLight->SetupAttachment(AttachParent);
	MuzzleFlashLight->SetMobility(EComponentMobility::Movable);
	MuzzleFlashLight->SetIntensity(12000.0f);
	MuzzleFlashLight->SetAttenuationRadius(140.0f);
	MuzzleFlashLight->SetCastShadows(false);
	MuzzleFlashLight->SetVisibility(false);
	MuzzleFlashLight->RegisterComponent();
}

void AShockWeapon::HideMuzzleFlash()
{
	MuzzleFlashRemaining = 0.0f;
	if (MuzzleFlashLight)
	{
		MuzzleFlashLight->SetVisibility(false);
	}
}

void AShockWeapon::FlashMuzzleLight(
	const FVector& WorldLocation,
	const FLinearColor& Color,
	float Intensity,
	float Duration)
{
	UWorld* World = GetWorld();
	if (!World)
	{
		return;
	}

	EnsureMuzzleFlashLight();
	if (!MuzzleFlashLight)
	{
		return;
	}

	MuzzleFlashLight->SetWorldLocation(WorldLocation);
	MuzzleFlashLight->SetLightColor(Color);
	MuzzleFlashLight->SetIntensity(Intensity);
	MuzzleFlashLight->SetVisibility(true);
	++MuzzleFlashCount;
	MuzzleFlashRemaining = Duration;

	World->GetTimerManager().ClearTimer(MuzzleFlashTimerHandle);
	World->GetTimerManager().SetTimer(
		MuzzleFlashTimerHandle,
		this,
		&AShockWeapon::HideMuzzleFlash,
		Duration,
		false);
}

FName AShockWeapon::ResolveImpactSurfaceName(const FString& EvidenceName)
{
	if (EvidenceName.Contains(TEXT("water"), ESearchCase::IgnoreCase)
		|| EvidenceName.Contains(TEXT("liquid"), ESearchCase::IgnoreCase))
	{
		return TEXT("Water");
	}
	if (EvidenceName.Contains(TEXT("glass"), ESearchCase::IgnoreCase)
		|| EvidenceName.Contains(TEXT("window"), ESearchCase::IgnoreCase))
	{
		return TEXT("Glass");
	}
	if (EvidenceName.Contains(TEXT("metal"), ESearchCase::IgnoreCase)
		|| EvidenceName.Contains(TEXT("steel"), ESearchCase::IgnoreCase)
		|| EvidenceName.Contains(TEXT("iron"), ESearchCase::IgnoreCase)
		|| EvidenceName.Contains(TEXT("grate"), ESearchCase::IgnoreCase)
		|| EvidenceName.Contains(TEXT("rail"), ESearchCase::IgnoreCase))
	{
		return TEXT("Metal");
	}
	if (EvidenceName.Contains(TEXT("wood"), ESearchCase::IgnoreCase)
		|| EvidenceName.Contains(TEXT("timber"), ESearchCase::IgnoreCase)
		|| EvidenceName.Contains(TEXT("plank"), ESearchCase::IgnoreCase))
	{
		return TEXT("Wood");
	}
	if (EvidenceName.Contains(TEXT("dirt"), ESearchCase::IgnoreCase)
		|| EvidenceName.Contains(TEXT("mud"), ESearchCase::IgnoreCase)
		|| EvidenceName.Contains(TEXT("soil"), ESearchCase::IgnoreCase)
		|| EvidenceName.Contains(TEXT("earth"), ESearchCase::IgnoreCase))
	{
		return TEXT("Dirt");
	}
	// Concrete is the honest slice fallback. Imported materials currently do not carry the
	// game's MVT byte into a UPhysicalMaterial (docs/research/audio.md).
	return TEXT("Concrete");
}

FName AShockWeapon::ResolveImpactSurface(const FHitResult& Hit)
{
	if (const UPhysicalMaterial* PhysicalMaterial = Hit.PhysMaterial.Get())
	{
		const FName FromPhysical = ResolveImpactSurfaceName(PhysicalMaterial->GetName());
		if (FromPhysical != FName(TEXT("Concrete"))
			|| PhysicalMaterial->GetName().Contains(TEXT("concrete"), ESearchCase::IgnoreCase)
			|| PhysicalMaterial->GetName().Contains(TEXT("stone"), ESearchCase::IgnoreCase))
		{
			return FromPhysical;
		}
	}

	if (const UMeshComponent* MeshComponent = Cast<UMeshComponent>(Hit.GetComponent()))
	{
		int32 SectionIndex = INDEX_NONE;
		UMaterialInterface* Material = Hit.FaceIndex != INDEX_NONE
			? MeshComponent->GetMaterialFromCollisionFaceIndex(Hit.FaceIndex, SectionIndex)
			: nullptr;
		if (!Material)
		{
			Material = MeshComponent->GetMaterial(0);
		}
		if (Material)
		{
			return ResolveImpactSurfaceName(Material->GetName());
		}
	}

	FString ComponentEvidence = Hit.GetComponent() ? Hit.GetComponent()->GetName() : FString();
	if (const AActor* Actor = Hit.GetActor())
	{
		ComponentEvidence += TEXT(" ");
		ComponentEvidence += Actor->GetName();
	}
	return ResolveImpactSurfaceName(ComponentEvidence);
}

void AShockWeapon::SpawnMuzzleParticle(const FVector& WorldLocation)
{
	UWorld* World = GetWorld();
	if (!World)
	{
		return;
	}

	const TCHAR* Leaf = DefWeaponName == FName(TEXT("TommyGun"))
		? TEXT("MachineGun_MuzzleFX")
		: DefWeaponName == FName(TEXT("Pistol"))
			? TEXT("Pistol_MuzzleFX")
			: DefWeaponName == FName(TEXT("Shotgun"))
				? TEXT("Shotgun_MuzzleFX")
				: TEXT("Weapon_MuzzleFX");
	const FString AssetPath = FString::Printf(
		TEXT("/Game/BioShockFX/Weapons/%s.%s"), Leaf, Leaf);
	UParticleSystem* Template = LoadObject<UParticleSystem>(nullptr, *AssetPath);

	UParticleSystemComponent* Component =
		NewObject<UParticleSystemComponent>(this, NAME_None, RF_Transient);
	if (!Component)
	{
		return;
	}
	AddInstanceComponent(Component);
	Component->bAutoDestroy = true;
	Component->SetAutoActivate(false);
	Component->RegisterComponent();
	Component->SetWorldLocation(WorldLocation);
	if (Template)
	{
		Component->SetTemplate(Template);
		Component->ActivateSystem(true);
	}
	else
	{
		// The shipped Cascade templates are not recovered yet. This short bright stand-in keeps
		// the muzzle visibly alive while preserving the final /Game asset contract above.
		DrawDebugPoint(World, WorldLocation, 13.0f, FColor(255, 225, 145), false, 0.07f);
	}
	LastMuzzleParticleComponent = Component;
	++MuzzleParticleCount;

	if (bAutomatic && FireMode == EWeaponFireMode::Hitscan && FireCount > 0 && (FireCount % 6) == 0)
	{
		static const TCHAR* SmokePath =
			TEXT("/Game/BioShockFX/Weapons/P_AutomaticSmoke.P_AutomaticSmoke");
		UParticleSystem* SmokeTemplate = LoadObject<UParticleSystem>(nullptr, SmokePath);
		UParticleSystemComponent* Smoke =
			NewObject<UParticleSystemComponent>(this, NAME_None, RF_Transient);
		if (Smoke)
		{
			AddInstanceComponent(Smoke);
			Smoke->bAutoDestroy = true;
			Smoke->SetAutoActivate(false);
			Smoke->RegisterComponent();
			Smoke->SetWorldLocation(WorldLocation);
			if (SmokeTemplate)
			{
				Smoke->SetTemplate(SmokeTemplate);
				Smoke->ActivateSystem(true);
			}
			else
			{
				DrawDebugSphere(
					World, WorldLocation + FVector(0.0f, 0.0f, 3.0f),
					5.0f, 6, FColor(105, 105, 105), false, 0.22f, 0, 0.8f);
			}
		}
	}
}

void AShockWeapon::SpawnShellCasing(const FVector& MuzzleLocation)
{
	if (FireMode != EWeaponFireMode::Hitscan && FireMode != EWeaponFireMode::Shotgun)
	{
		return;
	}
	UWorld* World = GetWorld();
	if (!World)
	{
		return;
	}

	FVector EjectLocation = MuzzleLocation;
	if (Mesh)
	{
		static const FName EjectSockets[] = {
			TEXT("shelleject"), TEXT("ShellEject"), TEXT("SG_Shell")};
		for (const FName Socket : EjectSockets)
		{
			if (Mesh->DoesSocketExist(Socket))
			{
				EjectLocation = Mesh->GetSocketLocation(Socket);
				break;
			}
		}
	}

	UStaticMesh* CasingMesh = LoadObject<UStaticMesh>(
		nullptr, TEXT("/Engine/BasicShapes/Cylinder.Cylinder"));
	if (!CasingMesh)
	{
		return;
	}
	AStaticMeshActor* Casing = World->SpawnActor<AStaticMeshActor>(
		EjectLocation, FRotator(90.0f, 0.0f, 0.0f));
	if (!Casing || !Casing->GetStaticMeshComponent())
	{
		return;
	}
	UStaticMeshComponent* CasingComponent = Casing->GetStaticMeshComponent();
	CasingComponent->SetMobility(EComponentMobility::Movable);
	CasingComponent->SetStaticMesh(CasingMesh);
	// The bare engine cylinder ships with no material of its own -- unset, it falls back to
	// UE's flat grey default, which reads as a stray grey blob sitting on the weapon at the
	// eject socket rather than a recognisable spent shell (reported live 29 Sept 2026).
	if (UMaterialInterface* CasingMaterial = LoadObject<UMaterialInterface>(
			nullptr, TEXT("/Game/BioShockFX/Weapons/M_ShellCasing_Brass.M_ShellCasing_Brass")))
	{
		CasingComponent->SetMaterial(0, CasingMaterial);
	}
	CasingComponent->SetWorldScale3D(FVector(0.015f, 0.015f, 0.04f));
	CasingComponent->SetCollisionProfileName(TEXT("PhysicsActor"));
	CasingComponent->SetSimulatePhysics(true);
	const FVector EjectDirection =
		Mesh ? Mesh->GetRightVector() + Mesh->GetUpVector() * 0.65f : FVector(0.0f, 1.0f, 0.65f);
	CasingComponent->AddImpulse(EjectDirection.GetSafeNormal() * 115.0f, NAME_None, true);
	CasingComponent->AddAngularImpulseInDegrees(FVector(0.0f, 260.0f, 480.0f), NAME_None, true);
	Casing->SetLifeSpan(4.0f);
	++ShellEjectCount;
}

void AShockWeapon::SpawnWorldImpact(const FHitResult& Hit, bool bBeamImpact)
{
	SpawnResolvedWorldImpact(
		ResolveImpactSurface(Hit),
		Hit.ImpactPoint,
		Hit.ImpactNormal.GetSafeNormal(),
		bBeamImpact);
}

void AShockWeapon::SpawnWorldImpactFromHit(const FHitResult& Hit, bool bBeamImpact)
{
	SpawnWorldImpact(Hit, bBeamImpact);
}

void AShockWeapon::SimulateWorldImpactForVerify(
	FName MaterialName,
	FVector ImpactPoint,
	FVector ImpactNormal)
{
	SpawnResolvedWorldImpact(
		ResolveImpactSurfaceName(MaterialName.ToString()),
		ImpactPoint,
		ImpactNormal.GetSafeNormal(),
		false);
}

void AShockWeapon::SpawnResolvedWorldImpact(
	FName Surface,
	const FVector& ImpactPoint,
	const FVector& ImpactNormal,
	bool bBeamImpact)
{
	UWorld* World = GetWorld();
	if (!World)
	{
		return;
	}
	const FVector SafeNormal =
		ImpactNormal.IsNearlyZero() ? FVector::UpVector : ImpactNormal.GetSafeNormal();
	const FShockImpactProfile Profile = ImpactProfileFor(Surface, bBeamImpact);

	const bool bReuseBeamScorch =
		bBeamImpact
		&& bLastImpactWasBeam
		&& IsValid(LastImpactDecalComponent)
		&& LastImpactSurface == Surface
		&& FVector::DistSquared(
			LastImpactDecalComponent->GetComponentLocation(), ImpactPoint) < FMath::Square(25.0f);
	if (Profile.DecalPath && !bReuseBeamScorch)
	{
		UMaterialInterface* DecalMaterial =
			LoadObject<UMaterialInterface>(nullptr, Profile.DecalPath);
		if (!DecalMaterial)
		{
			DecalMaterial = UMaterial::GetDefaultMaterial(MD_DeferredDecal);
		}
		if (DecalMaterial)
		{
			const FVector DecalSize(2.0f, Profile.DecalSize, Profile.DecalSize);
			LastImpactDecalComponent = UGameplayStatics::SpawnDecalAtLocation(
				World,
				DecalMaterial,
				DecalSize,
				ImpactPoint + SafeNormal * 0.2f,
				SafeNormal.Rotation(),
				Profile.DecalLife);
			if (LastImpactDecalComponent)
			{
				++ImpactDecalCount;
			}
		}
	}
	else if (bReuseBeamScorch)
	{
		LastImpactDecalComponent->SetWorldLocationAndRotation(
			ImpactPoint + SafeNormal * 0.2f, SafeNormal.Rotation());
	}
	else if (!Profile.DecalPath)
	{
		LastImpactDecalComponent = nullptr;
	}

	UParticleSystem* FxTemplate =
		LoadObject<UParticleSystem>(nullptr, Profile.FxPath);
	UParticleSystemComponent* FxComponent =
		NewObject<UParticleSystemComponent>(this, NAME_None, RF_Transient);
	if (FxComponent)
	{
		AddInstanceComponent(FxComponent);
		FxComponent->bAutoDestroy = true;
		FxComponent->SetAutoActivate(false);
		FxComponent->RegisterComponent();
		FxComponent->SetWorldLocationAndRotation(ImpactPoint, SafeNormal.Rotation());
		if (FxTemplate)
		{
			FxComponent->SetTemplate(FxTemplate);
			FxComponent->ActivateSystem(true);
		}
		LastImpactFxComponent = FxComponent;
		++ImpactFxCount;
	}

	// Visible stand-ins for the not-yet-recovered Cascade systems. Metal reads as a spark fan,
	// water as a splash cross, and solids as a compact debris puff.
	if (!FxTemplate)
	{
		const FVector Tangent = FVector::CrossProduct(
			SafeNormal,
			FMath::Abs(SafeNormal.Z) > 0.8f ? FVector::ForwardVector : FVector::UpVector)
			.GetSafeNormal();
		const FVector Bitangent = FVector::CrossProduct(SafeNormal, Tangent).GetSafeNormal();
		if (Surface == FName(TEXT("Metal")))
		{
			for (int32 Index = -2; Index <= 2; ++Index)
			{
				const FVector SparkDirection =
					(SafeNormal * 0.8f + Tangent * (0.22f * Index) + Bitangent * (0.12f * (Index & 1))).GetSafeNormal();
				DrawDebugLine(
					World, ImpactPoint, ImpactPoint + SparkDirection * 28.0f,
					Profile.StandInColor, false, 0.3f, 0, 1.6f);
			}
		}
		else
		{
			DrawDebugSphere(
				World,
				ImpactPoint + SafeNormal * 2.0f,
				Surface == FName(TEXT("Water")) ? 8.0f : 5.0f,
				8,
				Profile.StandInColor,
				false,
				0.3f,
				0,
				1.2f);
		}
	}

	const double Now = World->GetTimeSeconds();
	const bool bPlaySound =
		!bBeamImpact
		|| LastBeamImpactSoundSeconds < 0.0
		|| Now - LastBeamImpactSoundSeconds >= 0.35;
	if (bPlaySound)
	{
		LastImpactAudioComponent =
			UShockAudioLibrary::SpawnCueAtLocation(World, Profile.Sound, ImpactPoint);
		++ImpactSoundCount;
		if (bBeamImpact)
		{
			LastBeamImpactSoundSeconds = Now;
		}
	}

	LastImpactSurface = Surface;
	LastImpactDecalAsset = Profile.DecalPath ? Profile.DecalPath : TEXT("None");
	LastImpactFxAsset = Profile.FxPath;
	LastImpactSound = Profile.Sound;
	bLastImpactWasBeam = bBeamImpact;
	UE_LOG(
		LogTemp,
		Display,
		TEXT("BIOSHOCK_IMPACT surface=%s decal=%s fx=%s sound=%s soundcomponent=%d"),
		*Surface.ToString(),
		*LastImpactDecalAsset,
		*LastImpactFxAsset,
		*LastImpactSound.ToString(),
		IsValid(LastImpactAudioComponent) ? 1 : 0);
}

bool AShockWeapon::ShouldDrawTracer() const
{
	// CONFIRMED_BYTES: MachineGun declares three MG_Tracer entries; Pistol declares none.
	// The source does not expose a cadence field. Every third Tommy round is the documented
	// runtime approximation and avoids turning its ten-round-per-second stream into a solid beam.
	return bDrawTracers
		&& (DefWeaponName.IsNone()
			|| (DefWeaponName == FName(TEXT("TommyGun")) && (FireCount % 3) == 1));
}

void AShockWeapon::PlayDryFireFeedback(const FVector& TraceStart)
{
	const FVector MuzzleLoc = ResolveMuzzleLocation(TraceStart);
	FlashMuzzleLight(MuzzleLoc, FLinearColor(0.55f, 0.08f, 0.05f), 1200.0f, 0.03f);
}

void AShockWeapon::PlayFireAudio()
{
	// BioShock ships the automatic weapons a multi-second fire loop (weapons_tommy_fire is
	// ~2.9s). Playing it per round stacks whole bursts on top of each other — one click sounds
	// like five shots. Keep a single attached instance alive while the trigger is held and
	// re-trigger it only when it has actually finished; StopFireAudio() ends it on release /
	// reload / empty. Semi-auto weapons keep one one-shot per round.
	if (bAutomatic)
	{
		if (!IsValid(LastAudioComponent) || !LastAudioComponent->IsPlaying())
		{
			LastAudioComponent = UShockAudioLibrary::SpawnCueAttached(FireSoundCue, Mesh);
		}
		UE_LOG(
			LogTemp,
			Display,
			TEXT("BIOSHOCK_AUDIO fire weapon=%s sound=%s loop=1 component=%d"),
			*DefWeaponName.ToString(),
			*FireSoundCue.ToString(),
			IsValid(LastAudioComponent) ? 1 : 0);
		return;
	}
	LastAudioComponent = UShockAudioLibrary::SpawnCueAttached(FireSoundCue, Mesh);
	UE_LOG(
		LogTemp,
		Display,
		TEXT("BIOSHOCK_AUDIO fire weapon=%s sound=%s component=%d"),
		*DefWeaponName.ToString(),
		*FireSoundCue.ToString(),
		LastAudioComponent ? 1 : 0);
}

void AShockWeapon::StopFireAudio()
{
	if (bAutomatic && IsValid(LastAudioComponent) && LastAudioComponent->IsPlaying())
	{
		LastAudioComponent->FadeOut(0.12f, 0.0f);
		UE_LOG(
			LogTemp, Display, TEXT("BIOSHOCK_AUDIO fire_stop weapon=%s"),
			*DefWeaponName.ToString());
	}
}

void AShockWeapon::PlayReloadAudio()
{
	StopFireAudio();
	LastAudioComponent = UShockAudioLibrary::SpawnCueAttached(ReloadSoundCue, Mesh);
	UE_LOG(
		LogTemp,
		Display,
		TEXT("BIOSHOCK_AUDIO reload weapon=%s sound=%s component=%d"),
		*DefWeaponName.ToString(),
		*ReloadSoundCue.ToString(),
		LastAudioComponent ? 1 : 0);
}

void AShockWeapon::PlayMeleeImpactAudio()
{
	LastAudioComponent = UShockAudioLibrary::SpawnCueAttached(ImpactSoundCue, Mesh);
	UE_LOG(
		LogTemp,
		Display,
		TEXT("BIOSHOCK_AUDIO impact weapon=%s sound=%s component=%d"),
		*DefWeaponName.ToString(),
		*ImpactSoundCue.ToString(),
		LastAudioComponent ? 1 : 0);
}

void AShockWeapon::PlayFireFeedback(
	AActor* InstigatorActor,
	const FVector& MuzzleLocation,
	const FVector& VisualEnd,
	bool bPawnHit,
	bool bWorldHit,
	bool bApplyRecoil,
	const FHitResult* WorldHit,
	bool bBeamImpact)
{
	UWorld* World = GetWorld();
	if (!World)
	{
		return;
	}

	if (bApplyRecoil)
	{
		FlashMuzzleLight(
			MuzzleLocation,
			FLinearColor(1.0f, 0.82f, 0.45f),
			12000.0f,
			0.04f);
		SpawnMuzzleParticle(MuzzleLocation);
		SpawnShellCasing(MuzzleLocation);
	}

	if (ShouldDrawTracer())
	{
		// DrawDebugLine is a world-space debug primitive; it does not know about the first-person
		// viewmodel's own close-range depth/FOV pass. Starting the line exactly at the muzzle
		// socket -- which sits inside that near-camera viewmodel space -- makes the tracer render
		// as if it slices through the gun mesh instead of leaving the barrel cleanly. Starting the
		// line past the viewmodel's typical near range (the gun itself is ~40-90uu from the
		// camera) avoids the visual clash without moving where the muzzle flash/shell eject/light
		// spawn, which should stay at the true muzzle.
		const FVector TracerDirection = (VisualEnd - MuzzleLocation).GetSafeNormal();
		const FVector TracerStart = TracerDirection.IsNearlyZero()
			? MuzzleLocation
			: MuzzleLocation + TracerDirection * 150.0f;
		DrawDebugLine(
			World,
			TracerStart,
			VisualEnd,
			FColor(255, 220, 150),
			false,
			0.05f,
			0,
			1.5f);
		++TracerDrawCount;
	}

	if (bPawnHit)
	{
		DrawDebugSphere(World, VisualEnd, 4.0f, 8, FColor(255, 40, 40), false, 0.15f);
	}
	else if (bWorldHit)
	{
		DrawDebugSphere(World, VisualEnd, 3.0f, 6, FColor(255, 220, 50), false, 0.15f);
		if (WorldHit)
		{
			SpawnWorldImpact(*WorldHit, bBeamImpact);
		}
	}

	if (AShockPlayer* Player = Cast<AShockPlayer>(InstigatorActor))
	{
		if (bApplyRecoil)
		{
			Player->ApplyWeaponRecoil();
			Player->NotifyViewHandsWeaponFired();
		}
	}
}

bool AShockWeapon::FireAt(AActor* InstigatorActor, FVector Start, FVector Direction)
{
	switch (FireMode)
	{
	case EWeaponFireMode::Projectile:
		return FireAtProjectile(InstigatorActor, Start, Direction);
	case EWeaponFireMode::Melee:
		return FireAtMelee(InstigatorActor, Start, Direction);
	case EWeaponFireMode::Shotgun:
		return FireAtShotgun(InstigatorActor, Start, Direction);
	case EWeaponFireMode::Beam:
		return FireAtBeam(InstigatorActor, Start, Direction);
	default:
		return FireAtHitscan(InstigatorActor, Start, Direction);
	}
}

bool AShockWeapon::FireAtHitscan(AActor* InstigatorActor, FVector Start, FVector Direction)
{
	UWorld* World = GetWorld();
	if (!World || Direction.IsNearlyZero())
	{
		return false;
	}

	if (bEnforceAmmo && bIsReloading)
	{
		return false;
	}

	if (bEnforceAmmo && RoundsInMagazine <= 0)
	{
		UE_LOG(LogTemp, Display, TEXT("BIOSHOCK_WEAPON_DRY"));
		PlayDryFireFeedback(Start);
		TryAutoReloadOnEmpty();
		return false;
	}

	if (!CanFireNow(World))
	{
		return false;
	}

	LastFireWorldSeconds = World->GetTimeSeconds();
	if (bEnforceAmmo)
	{
		--RoundsInMagazine;
		LogAmmoState();
	}
	++FireCount;
	LastHitPawn = nullptr;
	PlayFireAudio();
	ABaseShockAI::BroadcastSuspiciousNoise(
		World,
		Start,
		1.0f,
		TEXT("WeaponFire"),
		InstigatorActor,
		2000.0f);

	const FVector NormDir = Direction.GetSafeNormal();
	const FVector End = Start + NormDir * HitscanRange;
	FHitResult Hit;
	FCollisionQueryParams Params(SCENE_QUERY_STAT(ShockWeaponFire), false, InstigatorActor);
	Params.AddIgnoredActor(this);
	Params.bReturnFaceIndex = true;
	Params.bReturnPhysicalMaterial = true;

	// Include world geometry so a wall between the shooter and the target stops the shot —
	// LineTraceSingleByObjectType returns the FIRST hit, and the Cast<AShockPawn> guard below
	// only applies damage when that first hit is a pawn. Without this, AI shoot through walls.
	FCollisionObjectQueryParams ObjectParams;
	ObjectParams.AddObjectTypesToQuery(ECC_Pawn);
	ObjectParams.AddObjectTypesToQuery(ECC_WorldStatic);
	ObjectParams.AddObjectTypesToQuery(ECC_WorldDynamic);
	const bool bPawnTraceHit =
		World->LineTraceSingleByObjectType(Hit, Start, End, ObjectParams, Params);

	bool bDamaged = false;
	const int32 AmmoIndex = ChamberedAmmoTypeIndex;
	const float ShotDamage = GetDamageForAmmoIndex(AmmoIndex);
	if (bPawnTraceHit)
	{
		if (AShockPawn* Victim = Cast<AShockPawn>(Hit.GetActor()))
		{
			UShockDamageLibrary::ApplyDamage(
				Victim, ShotDamage, InstigatorActor, NAME_None,
				(End - Start).GetSafeNormal(), Hit.ImpactPoint, Hit.BoneName);
			ApplyAmmoHitEffect(InstigatorActor, Victim, Hit.ImpactPoint, AmmoIndex);
			LastHitPawn = Victim;
			bDamaged = true;
		}
	}

	const FVector MuzzleLoc = ResolveMuzzleLocation(Start);
	FVector VisualEnd = End;
	bool bVisualPawnHit = false;
	bool bVisualWorldHit = false;
	FHitResult VisualHit;
	FCollisionObjectQueryParams VisualObjectParams;
	VisualObjectParams.AddObjectTypesToQuery(ECC_Pawn);
	VisualObjectParams.AddObjectTypesToQuery(ECC_WorldStatic);
	VisualObjectParams.AddObjectTypesToQuery(ECC_WorldDynamic);
	if (World->LineTraceSingleByObjectType(VisualHit, MuzzleLoc, End, VisualObjectParams, Params))
	{
		VisualEnd = VisualHit.ImpactPoint;
		if (Cast<AShockPawn>(VisualHit.GetActor()))
		{
			bVisualPawnHit = true;
		}
		else
		{
			bVisualWorldHit = true;
		}
	}

	PlayFireFeedback(
		InstigatorActor,
		MuzzleLoc,
		VisualEnd,
		bVisualPawnHit,
		bVisualWorldHit,
		true,
		bVisualWorldHit ? &VisualHit : nullptr,
		false);

	if (bEnforceAmmo && RoundsInMagazine <= 0)
	{
		TryAutoReloadOnEmpty();
	}
	return bDamaged;
}

bool AShockWeapon::FireAtProjectile(AActor* InstigatorActor, FVector Start, FVector Direction)
{
	UWorld* World = GetWorld();
	if (!World || Direction.IsNearlyZero())
	{
		return false;
	}

	if (bEnforceAmmo && bIsReloading)
	{
		return false;
	}

	if (bEnforceAmmo && RoundsInMagazine <= 0)
	{
		UE_LOG(LogTemp, Display, TEXT("BIOSHOCK_WEAPON_DRY"));
		PlayDryFireFeedback(Start);
		TryAutoReloadOnEmpty();
		return false;
	}

	if (!CanFireNow(World))
	{
		return false;
	}

	const TSubclassOf<AShockProjectile> SpawnClass =
		ProjectileClass ? ProjectileClass : TSubclassOf<AShockProjectile>(AShockProjectile::StaticClass());

	LastFireWorldSeconds = World->GetTimeSeconds();
	if (bEnforceAmmo)
	{
		--RoundsInMagazine;
		LogAmmoState();
	}
	++FireCount;
	LastHitPawn = nullptr;
	PlayFireAudio();

	const FVector NormDir = Direction.GetSafeNormal();
	const FVector MuzzleLoc = ResolveMuzzleLocation(Start);
	const FRotator SpawnRot = NormDir.Rotation();

	FActorSpawnParameters SpawnParams;
	SpawnParams.Owner = this;
	SpawnParams.Instigator = Cast<APawn>(InstigatorActor);
	SpawnParams.SpawnCollisionHandlingOverride = ESpawnActorCollisionHandlingMethod::AlwaysSpawn;

	AShockProjectile* Projectile = World->SpawnActor<AShockProjectile>(
		SpawnClass,
		MuzzleLoc,
		SpawnRot,
		SpawnParams);
	if (Projectile)
	{
		Projectile->ConfigureFromWeapon(
			DefWeaponName,
			HitscanDamage,
			DefProjectileImpactRadius,
			DefProjectileInitialSpeed,
			DefProjectileLifeSeconds,
			InstigatorActor,
			NormDir);
	}

	PlayFireFeedback(InstigatorActor, MuzzleLoc, MuzzleLoc + NormDir * 500.0f, false, false);

	if (bEnforceAmmo && RoundsInMagazine <= 0)
	{
		TryAutoReloadOnEmpty();
	}
	return Projectile != nullptr;
}

bool AShockWeapon::FireAtMelee(AActor* InstigatorActor, FVector Start, FVector Direction)
{
	UWorld* World = GetWorld();
	if (!World || Direction.IsNearlyZero() || MeleeReach <= 0.0f)
	{
		return false;
	}

	if (!CanMeleeNow(World))
	{
		return false;
	}

	LastMeleeWorldSeconds = World->GetTimeSeconds();
	++FireCount;
	LastHitPawn = nullptr;
	PlayFireAudio();

	const FVector NormDir = Direction.GetSafeNormal();
	const FVector TraceEnd = Start + NormDir * MeleeReach;
	FCollisionQueryParams Params(SCENE_QUERY_STAT(ShockWeaponMelee), false, InstigatorActor);
	Params.AddIgnoredActor(this);

	FCollisionObjectQueryParams ObjectParams;
	ObjectParams.AddObjectTypesToQuery(ECC_Pawn);

	FHitResult Hit;
	const bool bHit = World->SweepSingleByObjectType(
		Hit,
		Start,
		TraceEnd,
		FQuat::Identity,
		ObjectParams,
		FCollisionShape::MakeSphere(FMath::Max(10.0f, MeleeReach * 0.15f)),
		Params);

	bool bDamaged = false;
	if (bHit)
	{
		if (AShockPawn* Victim = Cast<AShockPawn>(Hit.GetActor()))
		{
			UShockDamageLibrary::ApplyDamage(
				Victim, HitscanDamage, InstigatorActor, NAME_None,
				(TraceEnd - Start).GetSafeNormal(), Hit.ImpactPoint, Hit.BoneName);
			LastHitPawn = Victim;
			bDamaged = true;
		}
	}
	if (bHit)
	{
		PlayMeleeImpactAudio();
	}

	const FVector MuzzleLoc = ResolveMuzzleLocation(Start);
	PlayFireFeedback(InstigatorActor, MuzzleLoc, Hit.bBlockingHit ? Hit.ImpactPoint : TraceEnd, bDamaged, false);
	return bDamaged;
}

bool AShockWeapon::FireAtShotgun(AActor* InstigatorActor, FVector Start, FVector Direction)
{
	UWorld* World = GetWorld();
	if (!World || Direction.IsNearlyZero())
	{
		return false;
	}

	if (bEnforceAmmo && bIsReloading)
	{
		return false;
	}

	if (bEnforceAmmo && RoundsInMagazine <= 0)
	{
		UE_LOG(LogTemp, Display, TEXT("BIOSHOCK_WEAPON_DRY"));
		PlayDryFireFeedback(Start);
		TryAutoReloadOnEmpty();
		return false;
	}

	if (!CanFireNow(World))
	{
		return false;
	}

	LastFireWorldSeconds = World->GetTimeSeconds();
	if (bEnforceAmmo)
	{
		--RoundsInMagazine;
		LogAmmoState();
	}
	++FireCount;
	LastHitPawn = nullptr;
	PlayFireAudio();

	const FVector NormDir = Direction.GetSafeNormal();
	const FVector MuzzleLoc = ResolveMuzzleLocation(Start);
	const int32 TraceCount = FMath::Max(1, PelletCount);
	const FRotator BaseRot = NormDir.Rotation();
	FCollisionQueryParams Params(SCENE_QUERY_STAT(ShockWeaponShotgun), false, InstigatorActor);
	Params.AddIgnoredActor(this);
	Params.bReturnFaceIndex = true;
	Params.bReturnPhysicalMaterial = true;
	FCollisionObjectQueryParams ObjectParams;
	ObjectParams.AddObjectTypesToQuery(ECC_Pawn);
	ObjectParams.AddObjectTypesToQuery(ECC_WorldStatic);
	ObjectParams.AddObjectTypesToQuery(ECC_WorldDynamic);
	FCollisionObjectQueryParams VisualObjectParams;
	VisualObjectParams.AddObjectTypesToQuery(ECC_Pawn);
	VisualObjectParams.AddObjectTypesToQuery(ECC_WorldStatic);
	VisualObjectParams.AddObjectTypesToQuery(ECC_WorldDynamic);

	int32 HitCount = 0;
	int32 SpawnedWorldImpacts = 0;
	bool bAnyDamaged = false;
	for (int32 PelletIndex = 0; PelletIndex < TraceCount; ++PelletIndex)
	{
		const float FanT = TraceCount > 1 ? (static_cast<float>(PelletIndex) / static_cast<float>(TraceCount - 1)) - 0.5f : 0.0f;
		const float YawOffset = FanT * PelletSpreadDeg * 2.0f;
		const float PitchOffset =
			((PelletIndex % 2) == 0 ? 1.0f : -1.0f) * (static_cast<float>(PelletIndex % 3) + 1.0f) * 0.12f * PelletSpreadDeg;
		const FVector PelletDir = (BaseRot + FRotator(PitchOffset, YawOffset, 0.0f)).Vector();
		const FVector End = Start + PelletDir * HitscanRange;

		FHitResult Hit;
		const bool bPawnTraceHit =
			World->LineTraceSingleByObjectType(Hit, Start, End, ObjectParams, Params);

		bool bDamaged = false;
		if (bPawnTraceHit)
		{
			if (AShockPawn* Victim = Cast<AShockPawn>(Hit.GetActor()))
			{
				const int32 AmmoIndex = ChamberedAmmoTypeIndex;
				const float PelletDamage = GetDamageForAmmoIndex(AmmoIndex);
				UShockDamageLibrary::ApplyDamage(
					Victim, PelletDamage, InstigatorActor, NAME_None,
					(End - Start).GetSafeNormal(), Hit.ImpactPoint, Hit.BoneName);
				ApplyAmmoHitEffect(InstigatorActor, Victim, Hit.ImpactPoint, AmmoIndex);
				LastHitPawn = Victim;
				bDamaged = true;
				++HitCount;
			}
		}
		if (bDamaged)
		{
			bAnyDamaged = true;
		}

		FVector VisualEnd = End;
		bool bVisualPawnHit = false;
		bool bVisualWorldHit = false;
		FHitResult VisualHit;
		if (World->LineTraceSingleByObjectType(VisualHit, MuzzleLoc, End, VisualObjectParams, Params))
		{
			VisualEnd = VisualHit.ImpactPoint;
			if (Cast<AShockPawn>(VisualHit.GetActor()))
			{
				bVisualPawnHit = true;
			}
			else
			{
				bVisualWorldHit = true;
			}
		}

		const bool bApplyRecoil = PelletIndex == 0;
		const bool bSpawnWorldImpact = bVisualWorldHit && SpawnedWorldImpacts < 4;
		PlayFireFeedback(
			InstigatorActor,
			MuzzleLoc,
			VisualEnd,
			bVisualPawnHit,
			bVisualWorldHit,
			bApplyRecoil,
			bSpawnWorldImpact ? &VisualHit : nullptr,
			false);
		if (bSpawnWorldImpact)
		{
			++SpawnedWorldImpacts;
		}
	}

	UE_LOG(LogTemp, Display, TEXT("BIOSHOCK_SHOTGUN pellets=%d hits=%d"), TraceCount, HitCount);

	if (bEnforceAmmo && RoundsInMagazine <= 0)
	{
		TryAutoReloadOnEmpty();
	}
	return bAnyDamaged;
}

bool AShockWeapon::CanBeamTickNow(UWorld* World) const
{
	return CanFireNow(World);
}

bool AShockWeapon::FireAtBeam(AActor* InstigatorActor, FVector Start, FVector Direction)
{
	UWorld* World = GetWorld();
	if (!World || Direction.IsNearlyZero())
	{
		return false;
	}

	if (bEnforceAmmo && bIsReloading)
	{
		return false;
	}

	if (bEnforceAmmo && RoundsInMagazine <= 0)
	{
		UE_LOG(LogTemp, Display, TEXT("BIOSHOCK_WEAPON_DRY"));
		PlayDryFireFeedback(Start);
		TryAutoReloadOnEmpty();
		bBeamActive = false;
		return false;
	}

	if (!CanBeamTickNow(World))
	{
		return false;
	}

	const bool bStartingBeam = !bBeamActive;
	bBeamActive = true;
	LastFireWorldSeconds = World->GetTimeSeconds();

	++BeamAmmoTickCounter;
	if (BeamAmmoTickCounter >= BeamAmmoTicksPerRound)
	{
		BeamAmmoTickCounter = 0;
		if (bEnforceAmmo)
		{
			--RoundsInMagazine;
			LogAmmoState();
		}
	}

	++FireCount;
	LastHitPawn = nullptr;
	if (bStartingBeam)
	{
		PlayFireAudio();
	}

	const FVector NormDir = Direction.GetSafeNormal();
	const FVector MuzzleLoc = ResolveMuzzleLocation(Start);
	const FVector End = MuzzleLoc + NormDir * BeamRange;
	FHitResult Hit;
	FCollisionQueryParams Params(SCENE_QUERY_STAT(ShockWeaponBeam), false, InstigatorActor);
	Params.AddIgnoredActor(this);
	Params.bReturnFaceIndex = true;
	Params.bReturnPhysicalMaterial = true;
	FCollisionObjectQueryParams ObjectParams;
	ObjectParams.AddObjectTypesToQuery(ECC_Pawn);
	ObjectParams.AddObjectTypesToQuery(ECC_WorldStatic);
	ObjectParams.AddObjectTypesToQuery(ECC_WorldDynamic);
	const bool bPawnTraceHit =
		World->LineTraceSingleByObjectType(Hit, MuzzleLoc, End, ObjectParams, Params);

	bool bDamaged = false;
	AShockPawn* VictimPawn = nullptr;
	if (bPawnTraceHit)
	{
		VictimPawn = Cast<AShockPawn>(Hit.GetActor());
		if (VictimPawn)
		{
			UShockDamageLibrary::ApplyDamage(
				VictimPawn, HitscanDamage, InstigatorActor, NAME_None,
				(End - MuzzleLoc).GetSafeNormal(), Hit.ImpactPoint, Hit.BoneName);
			LastHitPawn = VictimPawn;
			bDamaged = true;

			if (ABaseShockAI* VictimAI = Cast<ABaseShockAI>(VictimPawn))
			{
				switch (BeamStatus)
				{
				case EBeamStatus::Burning:
					// weapons-config Napalm Burning 1.2 — refresh ~1s linger after beam stops.
					VictimAI->Ignite(1.0f, 1.2f, InstigatorActor);
					break;
				case EBeamStatus::Electric:
					VictimAI->ReactToPlasmidStun(0.3f, InstigatorActor);
					break;
				case EBeamStatus::Freeze:
					VictimAI->ApplyChill(0.3f);
					break;
				default:
					break;
				}
			}
		}
	}

	FString StatusName = TEXT("None");
	switch (BeamStatus)
	{
	case EBeamStatus::Burning:
		StatusName = TEXT("Burning");
		break;
	case EBeamStatus::Electric:
		StatusName = TEXT("Electric");
		break;
	case EBeamStatus::Freeze:
		StatusName = TEXT("Freeze");
		break;
	default:
		break;
	}
	UE_LOG(
		LogTemp,
		Display,
		TEXT("BIOSHOCK_BEAM status=%s hit=%d"),
		*StatusName,
		bDamaged ? 1 : 0);

	FVector VisualEnd = End;
	bool bVisualPawnHit = false;
	bool bVisualWorldHit = false;
	FHitResult VisualHit;
	FCollisionObjectQueryParams VisualObjectParams;
	VisualObjectParams.AddObjectTypesToQuery(ECC_Pawn);
	VisualObjectParams.AddObjectTypesToQuery(ECC_WorldStatic);
	VisualObjectParams.AddObjectTypesToQuery(ECC_WorldDynamic);
	if (World->LineTraceSingleByObjectType(VisualHit, MuzzleLoc, End, VisualObjectParams, Params))
	{
		VisualEnd = VisualHit.ImpactPoint;
		if (Cast<AShockPawn>(VisualHit.GetActor()))
		{
			bVisualPawnHit = true;
		}
		else
		{
			bVisualWorldHit = true;
		}
	}

	PlayFireFeedback(
		InstigatorActor,
		MuzzleLoc,
		VisualEnd,
		bVisualPawnHit,
		bVisualWorldHit,
		false,
		bVisualWorldHit ? &VisualHit : nullptr,
		true);

	if (bEnforceAmmo && RoundsInMagazine <= 0)
	{
		TryAutoReloadOnEmpty();
		bBeamActive = false;
	}
	return bDamaged;
}
