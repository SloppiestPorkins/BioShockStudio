#include "ShockActionShowTrainingMessage.h"

#include "ShockPlayer.h"

UShockActionShowTrainingMessage::UShockActionShowTrainingMessage()
{
	ActionClassName = TEXT("ActionShowTrainingMessage");
}

void UShockActionShowTrainingMessage::Configure(FName InMessageName)
{
	MessageName = InMessageName;
}

bool UShockActionShowTrainingMessage::RequestShow()
{
	if (MessageName.IsNone())
	{
		return false;
	}
	LastMessageName = MessageName;
	return true;
}

int32 UShockActionShowTrainingMessage::ApplyInWorld(UWorld* World)
{
	if (!RequestShow())
	{
		return 0;
	}
	AShockPlayer* Player = AShockPlayer::FindLocalOrFirst(World);
	if (!Player)
	{
		return 0;
	}
	Player->SetTrainingMessage(MessageName);
	return 1;
}
