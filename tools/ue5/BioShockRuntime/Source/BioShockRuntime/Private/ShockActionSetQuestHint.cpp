#include "ShockActionSetQuestHint.h"

UShockActionSetQuestHint::UShockActionSetQuestHint()
{
	// Matches shipped class name casing from ActionUsageCensus.
	ActionClassName = TEXT("actionSetQuestHint");
}

void UShockActionSetQuestHint::Configure(FName InQuest, FName InHint)
{
	QuestName = InQuest;
	HintName = InHint;
}

bool UShockActionSetQuestHint::RequestSet()
{
	if (QuestName.IsNone() || HintName.IsNone())
	{
		return false;
	}
	LastHintName = HintName;
	return true;
}
