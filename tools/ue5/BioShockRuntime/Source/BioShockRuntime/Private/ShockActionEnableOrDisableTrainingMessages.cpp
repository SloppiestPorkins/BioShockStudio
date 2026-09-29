#include "ShockActionEnableOrDisableTrainingMessages.h"

#include "ShockPlayer.h"

UShockActionEnableOrDisableTrainingMessages::UShockActionEnableOrDisableTrainingMessages()
{
	ActionClassName = TEXT("ActionEnableOrDisableTrainingMessages");
}

void UShockActionEnableOrDisableTrainingMessages::Configure(bool bInEnable)
{
	bEnableTrainingMessages = bInEnable;
}

bool UShockActionEnableOrDisableTrainingMessages::RequestSet()
{
	bLastEnableTrainingMessages = bEnableTrainingMessages;
	return true;
}

int32 UShockActionEnableOrDisableTrainingMessages::ApplyInWorld(UWorld* World)
{
	if (!RequestSet())
	{
		return 0;
	}
	AShockPlayer* Player = AShockPlayer::FindLocalOrFirst(World);
	if (!Player)
	{
		return 0;
	}
	Player->SetTrainingMessagesEnabled(bEnableTrainingMessages);
	return 1;
}

bool UShockActionEnableOrDisableTrainingMessages::ApplyInWorld(const FShockActionContext& Ctx)
{
	return ApplyInWorld(Ctx.World) > 0;
}
