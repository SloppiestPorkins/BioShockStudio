#include "ShockPlasmid.h"

#include "ShockAirBlastPlasmid.h"
#include "ShockCycloneTrapPlasmid.h"
#include "ShockElectroBoltPlasmid.h"
#include "ShockEnragePlasmid.h"
#include "ShockIncineratePlasmid.h"
#include "ShockInsectSwarmPlasmid.h"
#include "ShockPlayer.h"
#include "ShockPlasmidFx.h"
#include "ShockSecurityBullseyePlasmid.h"
#include "ShockTargetDummyPlasmid.h"
#include "ShockTelekinesisPlasmid.h"
#include "ShockWinterBlastPlasmid.h"

bool UShockPlasmid::Cast(AShockPlayer* Caster, const FHitResult& Aim)
{
	(void)Caster;
	(void)Aim;
	return false;
}

float UShockPlasmid::GetCastEveCost(const AShockPlayer* Caster) const
{
	(void)Caster;
	return EveCost;
}

bool UShockPlasmid::EnforcesCastCooldown(const AShockPlayer* Caster) const
{
	(void)Caster;
	return true;
}

void UShockPlasmid::RememberFx(AShockPlasmidFx* Fx)
{
	LastFxActor = Fx;
}

AShockPlasmidFx* UShockPlasmid::SpawnCastBurst(
	AShockPlayer* Caster,
	const FVector& WorldLocation,
	const FRotator& WorldRotation,
	float LifeSeconds,
	float Radius)
{
	AShockPlasmidFx* Fx = AShockPlasmidFx::SpawnBurst(
		Caster ? Caster->GetWorld() : nullptr,
		CastFxAssetPath,
		WorldLocation,
		WorldRotation,
		HandTint,
		LifeSeconds,
		Radius);
	RememberFx(Fx);
	return Fx;
}

AShockPlasmidFx* UShockPlasmid::SpawnCastBeam(
	AShockPlayer* Caster,
	const FVector& Start,
	const FVector& End,
	float LifeSeconds,
	float Radius)
{
	AShockPlasmidFx* Fx = AShockPlasmidFx::SpawnBeam(
		Caster ? Caster->GetWorld() : nullptr,
		CastFxAssetPath,
		Start,
		End,
		HandTint,
		LifeSeconds,
		Radius);
	RememberFx(Fx);
	return Fx;
}

UNiagaraComponent* UShockPlasmid::GetLastFxComponentForVerify() const
{
	return IsValid(LastFxActor) ? LastFxActor->GetNiagaraComponentForVerify() : nullptr;
}

TSubclassOf<UShockPlasmid> UShockPlasmid::ResolvePlasmidClass(FName Name)
{
	const FString Key = Name.ToString();
	if (Key.Equals(TEXT("ElectroBolt"), ESearchCase::IgnoreCase)
		|| Key.Equals(TEXT("ElectricBolt"), ESearchCase::IgnoreCase))
	{
		return UShockElectroBoltPlasmid::StaticClass();
	}
	if (Key.Equals(TEXT("Incinerate"), ESearchCase::IgnoreCase)
		|| Key.Equals(TEXT("Incineration"), ESearchCase::IgnoreCase))
	{
		return UShockIncineratePlasmid::StaticClass();
	}
	if (Key.Equals(TEXT("Telekinesis"), ESearchCase::IgnoreCase)
		|| Key.Equals(TEXT("TelePlasmid"), ESearchCase::IgnoreCase))
	{
		return UShockTelekinesisPlasmid::StaticClass();
	}
	if (Key.Equals(TEXT("WinterBlast"), ESearchCase::IgnoreCase)
		|| Key.Equals(TEXT("IcicleAssault"), ESearchCase::IgnoreCase))
	{
		return UShockWinterBlastPlasmid::StaticClass();
	}
	if (Key.Equals(TEXT("InsectSwarm"), ESearchCase::IgnoreCase))
	{
		return UShockInsectSwarmPlasmid::StaticClass();
	}
	if (Key.Equals(TEXT("Enrage"), ESearchCase::IgnoreCase))
	{
		return UShockEnragePlasmid::StaticClass();
	}
	if (Key.Equals(TEXT("AirBlast"), ESearchCase::IgnoreCase)
		|| Key.Equals(TEXT("SonicBoom"), ESearchCase::IgnoreCase))
	{
		return UShockAirBlastPlasmid::StaticClass();
	}
	if (Key.Equals(TEXT("SecurityBeacon"), ESearchCase::IgnoreCase)
		|| Key.Equals(TEXT("SecurityBullseye"), ESearchCase::IgnoreCase))
	{
		return UShockSecurityBullseyePlasmid::StaticClass();
	}
	if (Key.Equals(TEXT("DecoyHuman"), ESearchCase::IgnoreCase)
		|| Key.Equals(TEXT("TargetDummy"), ESearchCase::IgnoreCase))
	{
		return UShockTargetDummyPlasmid::StaticClass();
	}
	if (Key.Equals(TEXT("SpringBoardTrap"), ESearchCase::IgnoreCase)
		|| Key.Equals(TEXT("SpringboardTrap"), ESearchCase::IgnoreCase)
		|| Key.Equals(TEXT("CycloneTrap"), ESearchCase::IgnoreCase))
	{
		return UShockCycloneTrapPlasmid::StaticClass();
	}
	return nullptr;
}
