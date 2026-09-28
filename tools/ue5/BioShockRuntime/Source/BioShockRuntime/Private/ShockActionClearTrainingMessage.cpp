#include "ShockActionClearTrainingMessage.h"

#include "ShockPlayer.h"

UShockActionClearTrainingMessage::UShockActionClearTrainingMessage()
{
	ActionClassName = TEXT("ActionClearTrainingMessage");
}

void UShockActionClearTrainingMessage::Configure(FName InMessage)
{
	MessageName = InMessage;
}

bool UShockActionClearTrainingMessage::RequestClear()
{
	LastMessageName = MessageName;
	return true;
}

int32 UShockActionClearTrainingMessage::ApplyInWorld(UWorld* World)
{
	RequestClear();
	AShockPlayer* Player = AShockPlayer::FindLocalOrFirst(World);
	if (!Player)
	{
		return 0;
	}
	Player->SetTrainingMessage(NAME_None);
	return 1;
}

bool UShockActionClearTrainingMessage::ApplyInWorld(const FShockActionContext& Ctx)
{
	return ApplyInWorld(Ctx.World) > 0;
}
