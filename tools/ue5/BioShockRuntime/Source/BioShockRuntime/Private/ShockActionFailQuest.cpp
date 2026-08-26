#include "ShockActionFailQuest.h"

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
