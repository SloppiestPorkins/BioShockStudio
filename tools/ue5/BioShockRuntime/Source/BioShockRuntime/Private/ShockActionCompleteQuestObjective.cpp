#include "ShockActionCompleteQuestObjective.h"

#include "ShockPlayer.h"

UShockActionCompleteQuestObjective::UShockActionCompleteQuestObjective()
{
	ActionClassName = TEXT("ActionCompleteQuestObjective");
	NumberOfObjectivesCompleted = 1;
	bShowHUDFeedBack = true;
}

void UShockActionCompleteQuestObjective::Configure(FName InQuest, bool bInShowHud, int32 InCount)
{
	QuestName = InQuest;
	bShowHUDFeedBack = bInShowHud;
	NumberOfObjectivesCompleted = InCount;
}

bool UShockActionCompleteQuestObjective::RequestComplete()
{
	if (QuestName.IsNone())
	{
		return false;
	}
	LastQuestName = QuestName;
	return true;
}

int32 UShockActionCompleteQuestObjective::ApplyInWorld(UWorld* World)
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
	Player->CompleteQuestObjective(QuestName, NumberOfObjectivesCompleted);
	return 1;
}
