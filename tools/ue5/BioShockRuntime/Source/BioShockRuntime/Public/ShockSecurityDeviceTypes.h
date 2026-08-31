#pragma once

#include "ShockSecurityDeviceTypes.generated.h"

UENUM(BlueprintType)
enum class EShockDeviceAllegiance : uint8
{
	Neutral,
	Hostile,
	Friendly,
	Disabled
};
