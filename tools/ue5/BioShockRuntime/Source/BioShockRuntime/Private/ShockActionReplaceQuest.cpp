#include "ShockActionReplaceQuest.h"

UShockActionReplaceQuest::UShockActionReplaceQuest()
{
	ActionClassName = TEXT("ActionReplaceQuest");
	bCopyObjectivesCompleted = true;
	UpdatedMessage = TEXT("Goal Updated");
}

void UShockActionReplaceQuest::Configure(FName InQuest, FName InReplacement, bool bInCopy, const FString& InMessage)
{
	QuestName = InQuest;
	ReplacementQuestName = InReplacement;
	bCopyObjectivesCompleted = bInCopy;
	UpdatedMessage = InMessage;
}

bool UShockActionReplaceQuest::RequestReplace()
{
	if (QuestName.IsNone() || ReplacementQuestName.IsNone())
	{
		return false;
	}
	LastReplacementQuestName = ReplacementQuestName;
	return true;
}
