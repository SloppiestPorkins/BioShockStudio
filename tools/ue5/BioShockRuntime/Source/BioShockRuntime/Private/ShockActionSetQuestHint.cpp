#include "ShockActionSetQuestHint.h"

#include "ShockPlayer.h"

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

int32 UShockActionSetQuestHint::ApplyInWorld(UWorld* World)
{
	if (!RequestSet() || !World)
	{
		return 0;
	}
	AShockPlayer* Player = AShockPlayer::FindLocalOrFirst(World);
	if (!Player)
	{
		return 0;
	}
	Player->SetQuestHint(QuestName, HintName);
	return 1;
}
