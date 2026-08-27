#include "ShockActionSetPlayerFOV.h"

UShockActionSetPlayerFOV::UShockActionSetPlayerFOV()
{
	ActionClassName = TEXT("ActionSetPlayerFOV");
}
void UShockActionSetPlayerFOV::Configure(float InFOV)
{
	FOV = InFOV;
}
bool UShockActionSetPlayerFOV::RequestSet()
{
	LastFOV = FOV;
	return true;
}
