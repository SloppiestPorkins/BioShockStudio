#include "ShockActionGetLevelLabel.h"

#include "Engine/World.h"
#include "Misc/PackageName.h"
#include "ShockVariable.h"

UShockActionGetLevelLabel::UShockActionGetLevelLabel()
{
	ActionClassName = TEXT("ActionGetLevelLabel");
}

bool UShockActionGetLevelLabel::ApplyInWorld(const FShockActionContext& Ctx)
{
	ClearReturnValue();
	FString Label;
	if (Ctx.World)
	{
		Label = Ctx.World->GetMapName();
		// Strip PIE / streaming prefixes (UEDPIE_0_1-Medical → 1-Medical).
		Label = FPackageName::GetShortName(Label);
		Label.ToLowerInline();
	}
	SetReturnValueText(Label, TEXT("VariableString"));
	return true;
}
