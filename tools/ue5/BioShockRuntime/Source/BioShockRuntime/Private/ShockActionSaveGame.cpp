#include "ShockActionSaveGame.h"

#include "ShockPlayer.h"
#include "ShockSaveGame.h"

UShockActionSaveGame::UShockActionSaveGame()
{
	ActionClassName = TEXT("ActionSaveGame");
}

void UShockActionSaveGame::Configure(const FString& InSaveGameName)
{
	SaveGameName = InSaveGameName;
}

bool UShockActionSaveGame::RequestSave()
{
	if (SaveGameName.IsEmpty())
	{
		return false;
	}
	LastSavedName = SaveGameName;
	return true;
}

int32 UShockActionSaveGame::ApplyInWorld(UWorld* World)
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
	bLastSaveOk = UShockSaveGame::SaveScripted(Player, SaveGameName);
	return bLastSaveOk ? 1 : 0;
}

bool UShockActionSaveGame::ApplyInWorld(const FShockActionContext& Ctx)
{
	return ApplyInWorld(Ctx.World) > 0;
}
