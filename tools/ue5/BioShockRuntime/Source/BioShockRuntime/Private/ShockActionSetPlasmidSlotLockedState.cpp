#include "ShockActionSetPlasmidSlotLockedState.h"

UShockActionSetPlasmidSlotLockedState::UShockActionSetPlasmidSlotLockedState()
{
	ActionClassName = TEXT("ActionSetPlasmidSlotLockedState");
}
void UShockActionSetPlasmidSlotLockedState::Configure(int32 InTrack, bool bInLock)
{
	Track = InTrack;
	bLock = bInLock;
}
bool UShockActionSetPlasmidSlotLockedState::RequestSet()
{
	return true;
}
