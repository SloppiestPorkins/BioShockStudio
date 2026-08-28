#include "ShockActionCompleteQuest.h"

#include "ShockPlayer.h"

UShockActionCompleteQuest::UShockActionCompleteQuest()
{
	ActionClassName = TEXT("ActionCompleteQuest");
	bShowHUDFeedBack = true;
}

void UShockActionCompleteQuest::Configure(FName InQuest, bool bInShowHud)
{
	QuestName = InQuest;
	bShowHUDFeedBack = bInShowHud;
}

bool UShockActionCompleteQuest::RequestComplete()
{
	if (QuestName.IsNone())
	{
		return false;
	}
	LastQuestName = QuestName;
	return true;
}

int32 UShockActionCompleteQuest::ApplyInWorld(UWorld* World)
{
	if (!RequestComplete() || !World)
	{
		return 0;
	}
	AShockPlayer* Player = AShockPlayer::FindLocalOrFirst(World);
	if (!Player)
	{
		return 0;
	}
	Player->CompleteQuest(QuestName);
	return 1;
}
