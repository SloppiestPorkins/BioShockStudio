#include "ShockScriptReflection.h"

#include "GameFramework/Actor.h"
#include "ShockPhysicsLibrary.h"
#include "UObject/UnrealType.h"

namespace ShockScriptReflection
{

AActor* ResolveTargetActor(UWorld* World, FName Label)
{
	// UShockPhysicsLibrary::FindActorByLabel already chains editor label -> AI script label
	// (UShockDamageLibrary) -> BioShockKey=/plain tag fallback. One resolver for every action
	// that finds a target by label, matching R2.1's "shared ResolveTargetActor helper" ask.
	return UShockPhysicsLibrary::FindActorByLabel(World, Label);
}

UObject* ResolvePropertyContainer(AActor* Target, const FString& PropertyPath, FString& OutPropertyName)
{
	OutPropertyName.Reset();
	if (!Target)
	{
		return nullptr;
	}

	int32 DotIndex = INDEX_NONE;
	if (!PropertyPath.FindChar(TEXT('.'), DotIndex))
	{
		OutPropertyName = PropertyPath;
		return Target;
	}

	const FString Selector = PropertyPath.Left(DotIndex);
	OutPropertyName = PropertyPath.Mid(DotIndex + 1);
	if (Selector.IsEmpty() || OutPropertyName.IsEmpty())
	{
		return nullptr;
	}

	TArray<UActorComponent*> Components;
	Target->GetComponents(Components);
	for (UActorComponent* Comp : Components)
	{
		if (!Comp)
		{
			continue;
		}
		if (Comp->GetName().Equals(Selector, ESearchCase::IgnoreCase)
			|| Comp->GetClass()->GetName().Equals(Selector, ESearchCase::IgnoreCase))
		{
			return Comp;
		}
	}
	// Named a component that isn't on this actor: fail rather than silently write the actor.
	return nullptr;
}

bool IsPropertyWritable(UObject* Container, FProperty* Property, FString* OutReason)
{
	auto Reject = [OutReason](const TCHAR* Reason) {
		if (OutReason)
		{
			*OutReason = Reason;
		}
		return false;
	};

	if (!Container || !Property)
	{
		return Reject(TEXT("null_container_or_property"));
	}
	if (Container->HasAnyFlags(RF_ClassDefaultObject | RF_ArchetypeObject))
	{
		return Reject(TEXT("refuses_cdo_or_archetype"));
	}
	if (AActor* Owner = Cast<AActor>(Container))
	{
		if (Owner->HasAnyFlags(RF_ClassDefaultObject) || !Owner->GetWorld())
		{
			return Reject(TEXT("refuses_non_level_actor"));
		}
	}
	if (Property->HasAnyPropertyFlags(CPF_Transient))
	{
		return Reject(TEXT("refuses_transient"));
	}
	if (Property->HasAnyPropertyFlags(CPF_EditorOnly))
	{
		return Reject(TEXT("refuses_editor_only"));
	}
	if (Property->HasAnyPropertyFlags(CPF_Deprecated))
	{
		return Reject(TEXT("refuses_deprecated"));
	}
	return true;
}

bool SetPropertyFromText(AActor* Target, const FString& PropertyPath, const FString& ValueText, FString* OutError)
{
	auto Fail = [OutError](const TCHAR* Reason) {
		if (OutError)
		{
			*OutError = Reason;
		}
		return false;
	};

	FString PropName;
	UObject* Container = ResolvePropertyContainer(Target, PropertyPath, PropName);
	if (!Container)
	{
		return Fail(TEXT("container_not_found"));
	}
	FProperty* Property = Container->GetClass()->FindPropertyByName(FName(*PropName));
	if (!Property)
	{
		return Fail(TEXT("property_not_found"));
	}
	FString Reason;
	if (!IsPropertyWritable(Container, Property, &Reason))
	{
		if (OutError)
		{
			*OutError = Reason;
		}
		return false;
	}

	void* ValuePtr = Property->ContainerPtrToValuePtr<void>(Container);
	const TCHAR* Result = Property->ImportText_Direct(*ValueText, ValuePtr, Container, PPF_None);
	if (!Result)
	{
		return Fail(TEXT("import_text_failed"));
	}
	return true;
}

bool GetPropertyAsText(AActor* Target, const FString& PropertyPath, FString& OutText)
{
	OutText.Reset();
	FString PropName;
	UObject* Container = ResolvePropertyContainer(Target, PropertyPath, PropName);
	if (!Container)
	{
		return false;
	}
	FProperty* Property = Container->GetClass()->FindPropertyByName(FName(*PropName));
	if (!Property)
	{
		return false;
	}
	const void* ValuePtr = Property->ContainerPtrToValuePtr<const void>(Container);
	Property->ExportTextItem_Direct(OutText, ValuePtr, nullptr, Container, PPF_None);
	return true;
}

} // namespace ShockScriptReflection
