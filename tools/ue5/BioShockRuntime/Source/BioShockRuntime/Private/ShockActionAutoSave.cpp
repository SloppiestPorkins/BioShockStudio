#include "ShockActionAutoSave.h"

UShockActionAutoSave::UShockActionAutoSave()
{
	ActionClassName = TEXT("ActionAutoSave");
	Command = TEXT("savegame autosave");
}
void UShockActionAutoSave::Configure(const FString& InCommand)
{
	Command = InCommand;
}
bool UShockActionAutoSave::RequestSave()
{
	return !Command.IsEmpty();
}
