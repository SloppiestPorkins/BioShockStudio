#include "ShockActionUnHackSecuritySystem.h"

UShockActionUnHackSecuritySystem::UShockActionUnHackSecuritySystem()
{
	ActionClassName = TEXT("ActionUnHackSecuritySystem");
}
bool UShockActionUnHackSecuritySystem::RequestUnHack()
{
	bUnHackRequested = true;
	return true;
}
