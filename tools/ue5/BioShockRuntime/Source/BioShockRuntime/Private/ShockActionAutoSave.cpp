#include "ShockActionAutoSave.h"

#include "ShockPlayer.h"

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
	if (Command.IsEmpty())
	{
		return false;
	}
	LastSavedCommand = Command;
	return true;
}

int32 UShockActionAutoSave::ApplyInWorld(UWorld* World)
{
	if (!RequestSave() || !World)
	{
		return 0;
	}
	AShockPlayer* Player = AShockPlayer::FindLocalOrFirst(World);
	if (!Player)
	{
		return 0;
	}
	Player->SetAutoSaveCommand(Command);
	return 1;
}
