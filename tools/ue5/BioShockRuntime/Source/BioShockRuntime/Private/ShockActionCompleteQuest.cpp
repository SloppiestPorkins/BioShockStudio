#include "ShockActionCompleteQuest.h"

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
