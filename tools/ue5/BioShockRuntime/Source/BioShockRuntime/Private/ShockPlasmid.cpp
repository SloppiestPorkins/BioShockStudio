#include "ShockPlasmid.h"

#include "ShockElectroBoltPlasmid.h"
#include "ShockPlayer.h"

bool UShockPlasmid::Cast(AShockPlayer* Caster, const FHitResult& Aim)
{
	(void)Caster;
	(void)Aim;
	return false;
}

TSubclassOf<UShockPlasmid> UShockPlasmid::ResolvePlasmidClass(FName Name)
{
	const FString Key = Name.ToString();
	if (Key.Equals(TEXT("ElectroBolt"), ESearchCase::IgnoreCase)
		|| Key.Equals(TEXT("ElectricBolt"), ESearchCase::IgnoreCase))
	{
		return UShockElectroBoltPlasmid::StaticClass();
	}
	return nullptr;
}
