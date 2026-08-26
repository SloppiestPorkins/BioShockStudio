#include "ShockActionAssignNextSecurityBotSpawnLocation.h"

UShockActionAssignNextSecurityBotSpawnLocation::UShockActionAssignNextSecurityBotSpawnLocation()
{
	ActionClassName = TEXT("ActionAssignNextSecurityBotSpawnLocation");
}

void UShockActionAssignNextSecurityBotSpawnLocation::Configure(FName InLabel)
{
	SpawnLocationLabel = InLabel;
}

bool UShockActionAssignNextSecurityBotSpawnLocation::RequestAssign()
{
	if (SpawnLocationLabel.IsNone())
	{
		return false;
	}
	LastSpawnLocationLabel = SpawnLocationLabel;
	return true;
}
