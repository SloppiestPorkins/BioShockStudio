#include "ShockActionScriptNote.h"

UShockActionScriptNote::UShockActionScriptNote()
{
	ActionClassName = TEXT("ActionScriptNote");
}

void UShockActionScriptNote::Configure(const FString& InNote)
{
	Note = InNote;
}

bool UShockActionScriptNote::EvaluateBool() const
{
	// Runtime execute returns none; notes are not boolean tests.
	return false;
}
