#include "ShockActionPrintClientMessage.h"

#include "ShockPlayer.h"

UShockActionPrintClientMessage::UShockActionPrintClientMessage()
{
	ActionClassName = TEXT("ActionPrintClientMessage");
}
void UShockActionPrintClientMessage::Configure(const FString& InText, FName InType)
{
	MessageText = InText;
	MessageType = InType;
}
bool UShockActionPrintClientMessage::RequestPrint()
{
	if (MessageText.IsEmpty())
	{
		return false;
	}
	LastPrintedText = MessageText;
	return true;
}

int32 UShockActionPrintClientMessage::ApplyInWorld(UWorld* World)
{
	if (!RequestPrint() || !World)
	{
		return 0;
	}
	AShockPlayer* Player = AShockPlayer::FindLocalOrFirst(World);
	if (!Player)
	{
		return 0;
	}
	Player->SetClientMessage(MessageText);
	return 1;
}
