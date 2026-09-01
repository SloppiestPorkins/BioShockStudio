#include "ShockActionAssignNextSecurityBotSpawnLocation.h"

#include "Engine/World.h"
#include "ShockSecuritySubsystem.h"

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

int32 UShockActionAssignNextSecurityBotSpawnLocation::ApplyInWorld(UWorld* World)
{
	if (!RequestAssign() || !World)
	{
		return 0;
	}

	if (UShockSecuritySubsystem* Security = UShockSecuritySubsystem::Get(World))
	{
		Security->SetNextSpawnLocationLabel(SpawnLocationLabel);
		return 1;
	}
	return 0;
}

bool UShockActionAssignNextSecurityBotSpawnLocation::ApplyInWorld(const FShockActionContext& Ctx)
{
	return ApplyInWorld(Ctx.World) > 0;
}
