#include "ShockActionWaitForQuestLogToFinish.h"

#include "ShockPlayer.h"

UShockActionWaitForQuestLogToFinish::UShockActionWaitForQuestLogToFinish()
{
	ActionClassName = TEXT("ActionWaitForQuestLogToFinish");
}

void UShockActionWaitForQuestLogToFinish::Configure(FName InQuestLogClass, float InTimeout)
{
	QuestLogClassName = InQuestLogClass;
	TimeoutSeconds = InTimeout;
}

bool UShockActionWaitForQuestLogToFinish::RequestWait()
{
	if (QuestLogClassName.IsNone())
	{
		return false;
	}
	LastQuestLogClassName = QuestLogClassName;
	return true;
}

int32 UShockActionWaitForQuestLogToFinish::ApplyInWorld(UWorld* World)
{
	if (!RequestWait() || !World)
	{
		return 0;
	}
	AShockPlayer* Player = AShockPlayer::FindLocalOrFirst(World);
	if (!Player)
	{
		return 0;
	}
	Player->SetQuestLogWait(QuestLogClassName);
	return 1;
}
