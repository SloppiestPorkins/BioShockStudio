#include "ShockActionInitiateQuest.h"

#include "ShockPlayer.h"

UShockActionInitiateQuest::UShockActionInitiateQuest()
{
	ActionClassName = TEXT("ActionInitiateQuest");
	NewQuestMessage = TEXT("New Goal");
	bSetAsActiveQuest = true;
	bShowHUDFeedBack = true;
}

void UShockActionInitiateQuest::Configure(FName InQuest, bool bInShowHud, bool bInSetActive, const FString& InMessage)
{
	QuestName = InQuest;
	bShowHUDFeedBack = bInShowHud;
	bSetAsActiveQuest = bInSetActive;
	NewQuestMessage = InMessage;
}

bool UShockActionInitiateQuest::RequestInitiate()
{
	if (QuestName.IsNone())
	{
		return false;
	}
	LastQuestName = QuestName;
	return true;
}

int32 UShockActionInitiateQuest::ApplyInWorld(UWorld* World)
{
	if (!RequestInitiate() || !World)
	{
		return 0;
	}
	AShockPlayer* Player = AShockPlayer::FindLocalOrFirst(World);
	if (!Player)
	{
		return 0;
	}
	Player->InitiateQuest(QuestName, bSetAsActiveQuest);
	return 1;
}
