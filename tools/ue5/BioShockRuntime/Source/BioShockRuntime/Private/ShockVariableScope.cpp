#include "ShockVariableScope.h"

#include "ShockGameInstance.h"
#include "ShockScriptRegistry.h"
#include "ShockScriptRunner.h"
#include "ShockVariable.h"

#include "Engine/Engine.h"
#include "Engine/World.h"
#include "UObject/Package.h"
#include "UObject/StrongObjectPtr.h"

namespace
{
	bool SplitDottedName(FName Name, FName& OutScriptLabel, FName& OutVarName)
	{
		const FString Text = Name.ToString();
		int32 DotIndex = INDEX_NONE;
		if (!Text.FindChar(TEXT('.'), DotIndex) || DotIndex <= 0 || DotIndex >= Text.Len() - 1)
		{
			return false;
		}
		// Only one segment pair: ScriptLabel.varname (no nested dots).
		int32 SecondDot = INDEX_NONE;
		if (Text.RightChop(DotIndex + 1).FindChar(TEXT('.'), SecondDot))
		{
			return false;
		}
		OutScriptLabel = FName(*Text.Left(DotIndex));
		OutVarName = FName(*Text.Mid(DotIndex + 1));
		return !OutScriptLabel.IsNone() && !OutVarName.IsNone();
	}
}

bool UShockVariableScope::IsGlobalName(FName Name)
{
	if (Name.IsNone())
	{
		return false;
	}
	return Name.ToString().StartsWith(TEXT("Global_"), ESearchCase::IgnoreCase);
}

UShockVariableScope* UShockVariableScope::GetOrCreateFallbackGlobals()
{
	// TStrongObjectPtr roots the object across GC (same pattern as ShockWeaponDef cache).
	static TStrongObjectPtr<UShockVariableScope> Fallback;
	if (!Fallback.IsValid())
	{
		Fallback.Reset(NewObject<UShockVariableScope>(GetTransientPackage(), NAME_None, RF_Transient));
	}
	return Fallback.Get();
}

UShockVariableScope* UShockVariableScope::GetSharedGlobals(UObject* ContextObject)
{
	auto TryFromWorld = [](const UWorld* World) -> UShockVariableScope*
	{
		if (UShockGameInstance* GI = UShockGameInstance::GetShockInstance(World))
		{
			return GI->EnsureGlobalVariables();
		}
		return nullptr;
	};

	if (ContextObject)
	{
		if (UShockGameInstance* AsGI = Cast<UShockGameInstance>(ContextObject))
		{
			return AsGI->EnsureGlobalVariables();
		}
		if (UShockVariableScope* FromWorld = TryFromWorld(ContextObject->GetWorld()))
		{
			return FromWorld;
		}
		for (const UObject* Outer = ContextObject->GetOuter(); Outer; Outer = Outer->GetOuter())
		{
			if (const UShockGameInstance* GI = Cast<UShockGameInstance>(Outer))
			{
				return const_cast<UShockGameInstance*>(GI)->EnsureGlobalVariables();
			}
			if (UShockVariableScope* FromOuterWorld = TryFromWorld(Outer->GetWorld()))
			{
				return FromOuterWorld;
			}
		}
	}

	if (GEngine)
	{
		for (const FWorldContext& Ctx : GEngine->GetWorldContexts())
		{
			if (UShockVariableScope* Found = TryFromWorld(Ctx.World()))
			{
				return Found;
			}
		}
	}

	return GetOrCreateFallbackGlobals();
}

void UShockVariableScope::BindRegistry(UShockScriptRegistry* InRegistry)
{
	BoundRegistry = InRegistry;
}

UShockVariableScope* UShockVariableScope::ResolveTargetScope(FName Name, FName& OutLocalName, bool bForWrite) const
{
	OutLocalName = Name;
	if (Name.IsNone())
	{
		return nullptr;
	}

	if (IsGlobalName(Name))
	{
		OutLocalName = Name;
		return GetSharedGlobals(const_cast<UShockVariableScope*>(this));
	}

	FName ScriptLabel;
	FName VarName;
	if (SplitDottedName(Name, ScriptLabel, VarName))
	{
		if (bForWrite)
		{
			// SCR-G06: assigning ScriptLabel.varname is not allowed.
			return nullptr;
		}
		UShockScriptRegistry* Registry = BoundRegistry.Get();
		if (!Registry)
		{
			return nullptr;
		}
		UShockScriptRunner* Other = Registry->FindScript(ScriptLabel);
		if (!Other)
		{
			return nullptr;
		}
		UShockVariableScope* OtherScope = Other->EnsureVariables();
		if (!OtherScope)
		{
			return nullptr;
		}
		OutLocalName = VarName;
		// Read the other script's *local* map only (Find/Set access Values directly).
		return OtherScope;
	}

	return const_cast<UShockVariableScope*>(this);
}

bool UShockVariableScope::Contains(FName Name) const
{
	return Find(Name) != nullptr;
}

bool UShockVariableScope::TryGet(FName Name, FString& OutValue) const
{
	if (UShockVariable* Variable = Find(Name))
	{
		OutValue = Variable->Value;
		return true;
	}
	return false;
}

FString UShockVariableScope::GetValueOrEmpty(FName Name) const
{
	if (UShockVariable* Variable = Find(Name))
	{
		return Variable->Value;
	}
	return FString();
}

bool UShockVariableScope::Set(FName Name, const FString& Value)
{
	FName LocalName;
	UShockVariableScope* Target = ResolveTargetScope(Name, LocalName, /*bForWrite=*/true);
	if (!Target)
	{
		return false;
	}

	if (TObjectPtr<UShockVariable>* Existing = Target->Values.Find(LocalName); Existing && *Existing)
	{
		(*Existing)->Value = Value;
		return true;
	}
	UShockVariable* Variable = NewObject<UShockVariable>(Target);
	Variable->Configure(Value, UShockVariable::InferVariableClass(Value));
	Target->Values.Add(LocalName, Variable);
	return true;
}

UShockVariable* UShockVariableScope::Find(FName Name) const
{
	FName LocalName;
	UShockVariableScope* Target = ResolveTargetScope(Name, LocalName, /*bForWrite=*/false);
	if (!Target)
	{
		return nullptr;
	}
	if (const TObjectPtr<UShockVariable>* Found = Target->Values.Find(LocalName))
	{
		return Found->Get();
	}
	return nullptr;
}
