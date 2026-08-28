#include "ShockActionDisplayOnScreenDebugMessage.h"

#include "Engine/Engine.h"

UShockActionDisplayOnScreenDebugMessage::UShockActionDisplayOnScreenDebugMessage()
{
	ActionClassName = TEXT("ActionDisplayOnScreenDebugMessage");
	Message = TEXT("<message text>");
}

void UShockActionDisplayOnScreenDebugMessage::Configure(const FString& InMessage)
{
	Message = InMessage;
}

bool UShockActionDisplayOnScreenDebugMessage::RequestDisplay()
{
	if (Message.IsEmpty())
	{
		return false;
	}
	LastMessage = Message;
	return true;
}

int32 UShockActionDisplayOnScreenDebugMessage::ApplyInWorld(UWorld* World)
{
	bLastDisplayed = false;
	if (!RequestDisplay() || !GEngine)
	{
		return 0;
	}
	(void)World;
	GEngine->AddOnScreenDebugMessage(INDEX_NONE, 5.0f, FColor::White, Message);
	bLastDisplayed = true;
	return 1;
}
