#include "ShockActionWaitForQuestLogToFinish.h"

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
