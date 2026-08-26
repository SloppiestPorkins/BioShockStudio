#include "ShockActionCompleteQuestObjective.h"

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
