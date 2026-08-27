#include "ShockActionToggleQuestVisibility.h"

UShockActionToggleQuestVisibility::UShockActionToggleQuestVisibility()
{
	ActionClassName = TEXT("ActionToggleQuestVisibility");
}
void UShockActionToggleQuestVisibility::Configure(FName InQuest)
{
	QuestName = InQuest;
}
bool UShockActionToggleQuestVisibility::RequestToggle()
{
	if (QuestName.IsNone()) return false;
	LastQuestName = QuestName;
	return true;
}
