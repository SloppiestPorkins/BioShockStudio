#include "ShockActionHackSecuritySystem.h"

UShockActionHackSecuritySystem::UShockActionHackSecuritySystem()
{
	ActionClassName = TEXT("ActionHackSecuritySystem");
	ShutdownTime = 30.f;
}
void UShockActionHackSecuritySystem::Configure(float InSeconds)
{
	ShutdownTime = InSeconds;
}
bool UShockActionHackSecuritySystem::RequestHack()
{
	return ShutdownTime > 0.f;
}
