#include "ShockPlasmid.h"

#include "ShockElectroBoltPlasmid.h"
#include "ShockIncineratePlasmid.h"
#include "ShockPlayer.h"
#include "ShockTelekinesisPlasmid.h"

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
	return nullptr;
}
