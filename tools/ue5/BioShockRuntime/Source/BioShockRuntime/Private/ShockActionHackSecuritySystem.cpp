#include "ShockActionHackSecuritySystem.h"

#include "ShockPlayer.h"

UShockActionHackSecuritySystem::UShockActionHackSecuritySystem()
{
	ActionClassName = TEXT("ActionHackSecuritySystem");
	ShutdownTime = 30.f;
}
void UShockActionHackSecuritySystem::Configure(float InSeconds)
{
	ShutdownTime = InSeconds;
}
bool UShockActionHackSecuritySystem::RequestHack()
{
	return ShutdownTime > 0.f;
}

int32 UShockActionHackSecuritySystem::ApplyInWorld(UWorld* World)
{
	if (!RequestHack() || !World)
	{
		return 0;
	}
	AShockPlayer* Player = AShockPlayer::FindLocalOrFirst(World);
	if (!Player)
	{
		return 0;
	}
	Player->SetSecurityHacked(true, ShutdownTime);
	return 1;
}

bool UShockActionHackSecuritySystem::ApplyInWorld(const FShockActionContext& Ctx)
{
	return ApplyInWorld(Ctx.World) > 0;
}
