#include "ShockActionGathererCrawlThroughDoor.h"

UShockActionGathererCrawlThroughDoor::UShockActionGathererCrawlThroughDoor()
{
	ActionClassName = TEXT("ActionGathererCrawlThroughDoor");
}

void UShockActionGathererCrawlThroughDoor::Configure(
	FName InTarget,
	FName InDoor,
	bool bInUnlock,
	bool bInRun,
	bool bInAggressive)
{
	Target = InTarget;
	DoorLabel = InDoor;
	bShouldUnlock = bInUnlock;
	bShouldRun = bInRun;
	bShouldBeAggressive = bInAggressive;
}

bool UShockActionGathererCrawlThroughDoor::RequestCrawl()
{
	if (Target.IsNone() || DoorLabel.IsNone())
	{
		return false;
	}
	LastDoorLabel = DoorLabel;
	return true;
}
