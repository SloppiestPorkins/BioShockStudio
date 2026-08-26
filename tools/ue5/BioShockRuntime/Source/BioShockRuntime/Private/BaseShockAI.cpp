#include "BaseShockAI.h"

ABaseShockAI::ABaseShockAI()
{
	SchemaClassName = TEXT("BaseShockAI");
	AutoPossessAI = EAutoPossessAI::Disabled;
}

void ABaseShockAI::ConfigureIdentity(FName InType, FName InLabel)
{
	AITypeName = InType;
	ScriptLabel = InLabel;
}
