#include "ShockActionFailQuest.h"

#include "ShockPlayer.h"

UShockActionFailQuest::UShockActionFailQuest()
{
	ActionClassName = TEXT("ActionFailQuest");
	FailQuestMessage = TEXT("Goal Failed");
}

void UShockActionFailQuest::Configure(FName InQuest, const FString& InMessage)
{
	QuestName = InQuest;
	FailQuestMessage = InMessage;
}

bool UShockActionFailQuest::RequestFail()
{
	if (QuestName.IsNone())
	{
		return false;
	}
	LastQuestName = QuestName;
	return true;
}

int32 UShockActionFailQuest::ApplyInWorld(UWorld* World)
{
	if (!RequestFail() || !World)
	{
		return 0;
	}
	AShockPlayer* Player = AShockPlayer::FindLocalOrFirst(World);
	if (!Player)
	{
		return 0;
	}
	Player->FailQuest(QuestName);
	return 1;
}
