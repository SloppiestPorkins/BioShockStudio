#include "ShockActionRunConsoleCommand.h"

UShockActionRunConsoleCommand::UShockActionRunConsoleCommand()
{
	ActionClassName = TEXT("ActionRunConsoleCommand");
}

void UShockActionRunConsoleCommand::Configure(const FString& InCommand)
{
	Command = InCommand;
}

bool UShockActionRunConsoleCommand::RequestRun()
{
	if (Command.IsEmpty())
	{
		return false;
	}
	LastCommand = Command;
	return true;
}
