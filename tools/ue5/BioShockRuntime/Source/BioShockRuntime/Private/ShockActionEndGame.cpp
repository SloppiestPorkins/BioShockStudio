#include "ShockActionEndGame.h"

UShockActionEndGame::UShockActionEndGame()
{
	ActionClassName = TEXT("ActionEndGame");
	NumberOfGatherersKilledToGetBadEnding = 14;
}

void UShockActionEndGame::Configure(int32 InNumberOfGatherersKilledToGetBadEnding)
{
	NumberOfGatherersKilledToGetBadEnding = InNumberOfGatherersKilledToGetBadEnding;
}

bool UShockActionEndGame::RequestEnd()
{
	bEndRequested = true;
	return true;
}
