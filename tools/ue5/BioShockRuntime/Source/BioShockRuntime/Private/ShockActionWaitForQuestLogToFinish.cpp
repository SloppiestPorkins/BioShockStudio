#include "ShockActionWaitForQuestLogToFinish.h"

#include "Engine/World.h"
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

bool UShockActionWaitForQuestLogToFinish::PrepareWait(UWorld* World, float WorldTimeSeconds)
{
	if (!RequestWait() || !World)
	{
		return false;
	}
	AShockPlayer* Player = AShockPlayer::FindLocalOrFirst(World);
	if (!Player)
	{
		return false;
	}
	Player->SetQuestLogWait(QuestLogClassName);
	WaitStartedAt = WorldTimeSeconds;
	bLastTimedOut = false;
	return true;
}

bool UShockActionWaitForQuestLogToFinish::IsReady(UWorld* World, float WorldTimeSeconds)
{
	AShockPlayer* Player = AShockPlayer::FindLocalOrFirst(World);
	if (!Player || !Player->IsQuestLogPlaying(QuestLogClassName))
	{
		return true;
	}
	if (TimeoutSeconds > 0.0f && WaitStartedAt >= 0.0f
		&& WorldTimeSeconds - WaitStartedAt >= TimeoutSeconds)
	{
		bLastTimedOut = true;
		return true;
	}
	return false;
}

int32 UShockActionWaitForQuestLogToFinish::ApplyInWorld(UWorld* World)
{
	if (!World)
	{
		return 0;
	}
	const float Now = World->GetTimeSeconds();
	return PrepareWait(World, Now) && IsReady(World, Now) ? 1 : 0;
}

bool UShockActionWaitForQuestLogToFinish::ApplyInWorld(const FShockActionContext& Ctx)
{
	return ApplyInWorld(Ctx.World) > 0;
}
