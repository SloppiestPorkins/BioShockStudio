#include "ShockActionActivateResurrectionStation.h"

#include "ShockPlayer.h"
#include "ShockVitaChamber.h"
#include "EngineUtils.h"

UShockActionActivateResurrectionStation::UShockActionActivateResurrectionStation()
{
	ActionClassName = TEXT("ActionActivateResurrectionStation");
	bActivateStation = true;
}

void UShockActionActivateResurrectionStation::Configure(FName InStation, bool bInActivate)
{
	ResurrectionStationLabel = InStation;
	bActivateStation = bInActivate;
}

bool UShockActionActivateResurrectionStation::RequestActivate()
{
	if (ResurrectionStationLabel.IsNone())
	{
		return false;
	}
	LastStationLabel = ResurrectionStationLabel;
	return true;
}

int32 UShockActionActivateResurrectionStation::ApplyInWorld(UWorld* World)
{
	if (!RequestActivate() || !World)
	{
		return 0;
	}
	int32 Applied = 0;
	for (TActorIterator<AShockVitaChamber> It(World); It; ++It)
	{
		if (It->ScriptLabel == ResurrectionStationLabel
			|| It->GetActorLabel().Equals(
				ResurrectionStationLabel.ToString(), ESearchCase::CaseSensitive))
		{
			It->SetActive(bActivateStation);
			++Applied;
		}
	}
	if (AShockPlayer* Player = AShockPlayer::FindLocalOrFirst(World))
	{
		// Keep the travel-state mirror consumed by existing script-world-state callers.
		Player->SetResurrectionStationActivated(ResurrectionStationLabel, bActivateStation);
		Applied = FMath::Max(Applied, 1);
	}
	return Applied;
}

bool UShockActionActivateResurrectionStation::ApplyInWorld(const FShockActionContext& Ctx)
{
	return ApplyInWorld(Ctx.World) > 0;
}
