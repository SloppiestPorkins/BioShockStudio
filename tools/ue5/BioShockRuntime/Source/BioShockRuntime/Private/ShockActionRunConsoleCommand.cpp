#include "ShockActionRunConsoleCommand.h"

#include "Engine/Engine.h"
#include "Engine/World.h"

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

int32 UShockActionRunConsoleCommand::ApplyInWorld(UWorld* World)
{
	bLastExecuted = false;
	if (!RequestRun() || !GEngine || !World)
	{
		return 0;
	}
	bLastExecuted = GEngine->Exec(World, *Command);
	return bLastExecuted ? 1 : 0;
}
