#include "ShockActionLog.h"

UShockActionLog::UShockActionLog()
{
	ActionClassName = TEXT("ActionLog");
}

void UShockActionLog::Configure(const FString& InText)
{
	Text = InText;
}

bool UShockActionLog::Emit()
{
	LastLoggedText = Text;
	UE_LOG(LogTemp, Log, TEXT("[BioShock ActionLog] %s"), *Text);
	return true;
}
