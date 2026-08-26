#include "ShockActionChangeQuestArrowActor.h"

UShockActionChangeQuestArrowActor::UShockActionChangeQuestArrowActor()
{
	ActionClassName = TEXT("ActionChangeQuestArrowActor");
}

void UShockActionChangeQuestArrowActor::Configure(FName InQuest, FName InArrow, FName InLevelLabel)
{
	QuestName = InQuest;
	ArrowActor = InArrow;
	ArrowActorLevelLabel = InLevelLabel;
}

bool UShockActionChangeQuestArrowActor::RequestChange()
{
	if (QuestName.IsNone())
	{
		return false;
	}
	LastArrowActor = ArrowActor;
	return true;
}
