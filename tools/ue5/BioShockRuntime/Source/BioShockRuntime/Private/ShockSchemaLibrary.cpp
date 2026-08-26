#include "ShockSchemaLibrary.h"

#include "ShockAction.h"
#include "ShockActionExecuteScript.h"
#include "ShockActionHideOrShowActor.h"
#include "ShockActionNonBlockingExecuteScript.h"
#include "ShockActionPlayEffect.h"
#include "ShockActionSetLightProperties.h"
#include "ShockActionSetProperty.h"
#include "ShockActionSpawnAI.h"
#include "ShockActionVariableAssign.h"
#include "ShockActionWait.h"
#include "ShockPawn.h"
#include "Components/CapsuleComponent.h"
#include "GameFramework/Character.h"
#include "GameFramework/CharacterMovementComponent.h"
#include "Dom/JsonObject.h"
#include "Dom/JsonValue.h"
#include "Misc/FileHelper.h"
#include "Serialization/JsonReader.h"
#include "Serialization/JsonSerializer.h"
#include "Serialization/JsonWriter.h"
#include "Templates/Function.h"

namespace
{
	struct FSchemaClass
	{
		FString Name;
		FString Super;
		TMap<FString, FString> Defaults;
	};

	bool ParseFloat(const FString& Text, float& Out)
	{
		if (Text.IsEmpty() || Text.StartsWith(TEXT("<")))
		{
			return false;
		}
		Out = FCString::Atof(*Text);
		return FMath::IsFinite(Out);
	}

	FString Unquote(const FString& Text)
	{
		FString Out = Text.TrimStartAndEnd();
		if (Out.Len() >= 2 && Out.StartsWith(TEXT("\"")) && Out.EndsWith(TEXT("\"")))
		{
			Out = Out.Mid(1, Out.Len() - 2);
		}
		return Out;
	}

	bool LoadSchema(const FString& Path, TMap<FString, FSchemaClass>& Out, FString& Error)
	{
		FString Json;
		if (!FFileHelper::LoadFileToString(Json, *Path))
		{
			Error = FString::Printf(TEXT("could not read schema %s"), *Path);
			return false;
		}

		const TSharedRef<TJsonReader<>> Reader = TJsonReaderFactory<>::Create(Json);
		TArray<TSharedPtr<FJsonValue>> Rows;
		if (!FJsonSerializer::Deserialize(Reader, Rows))
		{
			Error = TEXT("schema JSON is not an array of classes");
			return false;
		}

		for (const TSharedPtr<FJsonValue>& Row : Rows)
		{
			const TSharedPtr<FJsonObject> Object = Row.IsValid() ? Row->AsObject() : nullptr;
			if (!Object.IsValid())
			{
				continue;
			}

			FSchemaClass Entry;
			Entry.Name = Object->GetStringField(TEXT("name"));
			Object->TryGetStringField(TEXT("super"), Entry.Super);
			const TArray<TSharedPtr<FJsonValue>>* Defaults = nullptr;
			if (Object->TryGetArrayField(TEXT("defaults"), Defaults))
			{
				for (const TSharedPtr<FJsonValue>& DefaultRow : *Defaults)
				{
					const TSharedPtr<FJsonObject> Default = DefaultRow.IsValid() ? DefaultRow->AsObject() : nullptr;
					if (!Default.IsValid())
					{
						continue;
					}
					const FString Name = Default->GetStringField(TEXT("name"));
					if (Name.IsEmpty() || Entry.Defaults.Contains(Name))
					{
						// Static-array entries share a name; the first scalar/index-0 wins for this
						// slice. Indexed defaults are not applied as floats.
						continue;
					}
					Entry.Defaults.Add(Name, Default->GetStringField(TEXT("value")));
				}
			}
			if (!Entry.Name.IsEmpty())
			{
				Out.Add(Entry.Name, MoveTemp(Entry));
			}
		}

		if (Out.Num() == 0)
		{
			Error = TEXT("schema JSON contained no classes");
			return false;
		}
		return true;
	}

	bool Lookup(const TMap<FString, FSchemaClass>& Classes, const FString& ClassName, const FString& Property, FString& Value)
	{
		FString Current = ClassName;
		TSet<FString> Seen;
		while (!Current.IsEmpty() && !Seen.Contains(Current))
		{
			Seen.Add(Current);
			const FSchemaClass* Entry = Classes.Find(Current);
			if (!Entry)
			{
				return false;
			}
			if (const FString* Found = Entry->Defaults.Find(Property))
			{
				Value = *Found;
				return true;
			}
			Current = Entry->Super;
		}
		return false;
	}
}

FString UShockSchemaLibrary::ApplyClassDefaults(AActor* Actor, const FString& SchemaJsonPath, const FString& ClassName)
{
	TArray<FString> Applied;
	FString Error;
	bool Ok = false;

	if (!Actor)
	{
		Error = TEXT("actor is null");
	}
	else
	{
		TMap<FString, FSchemaClass> Classes;
		if (!LoadSchema(SchemaJsonPath, Classes, Error))
		{
			Ok = false;
		}
		else if (!Classes.Contains(ClassName))
		{
			Error = FString::Printf(TEXT("class %s is not in %s"), *ClassName, *SchemaJsonPath);
		}
		else
		{
			if (AShockPawn* Pawn = Cast<AShockPawn>(Actor))
			{
				Pawn->SchemaClassName = ClassName;
			}

			auto ApplyFloat = [&](const TCHAR* Property, const TFunctionRef<void(float)>& Sink)
			{
				FString Text;
				float Value = 0.0f;
				if (Lookup(Classes, ClassName, Property, Text) && ParseFloat(Text, Value))
				{
					Sink(Value);
					Applied.Add(Property);
				}
			};

			if (ACharacter* Character = Cast<ACharacter>(Actor))
			{
				ApplyFloat(TEXT("CollisionRadius"), [&](float Value)
				{
					Character->GetCapsuleComponent()->SetCapsuleRadius(Value, false);
				});
				ApplyFloat(TEXT("CollisionHeight"), [&](float Value)
				{
					Character->GetCapsuleComponent()->SetCapsuleHalfHeight(Value, false);
				});
				ApplyFloat(TEXT("GroundSpeed"), [&](float Value)
				{
					Character->GetCharacterMovement()->MaxWalkSpeed = Value;
				});
				ApplyFloat(TEXT("JumpZ"), [&](float Value)
				{
					Character->GetCharacterMovement()->JumpZVelocity = Value;
				});
				ApplyFloat(TEXT("BaseEyeHeight"), [&](float Value)
				{
					Character->BaseEyeHeight = Value;
				});
				ApplyFloat(TEXT("CrouchHeight"), [&](float Value)
				{
					Character->GetCharacterMovement()->SetCrouchedHalfHeight(Value);
				});
			}

			if (AShockPawn* Pawn = Cast<AShockPawn>(Actor))
			{
				ApplyFloat(TEXT("Health"), [&](float Value) { Pawn->AuthoredHealth = Value; });
				ApplyFloat(TEXT("MaxHealth"), [&](float Value) { Pawn->AuthoredMaxHealth = Value; });
			}
			Ok = true;
		}
	}

	TSharedRef<FJsonObject> Report = MakeShared<FJsonObject>();
	Report->SetBoolField(TEXT("ok"), Ok);
	Report->SetStringField(TEXT("error"), Error);
	TArray<TSharedPtr<FJsonValue>> AppliedJson;
	for (const FString& Name : Applied)
	{
		AppliedJson.Add(MakeShared<FJsonValueString>(Name));
	}
	Report->SetArrayField(TEXT("applied"), AppliedJson);
	FString Output;
	const TSharedRef<TJsonWriter<>> Writer = TJsonWriterFactory<>::Create(&Output);
	FJsonSerializer::Serialize(Report, Writer);
	return Output;
}

FString UShockSchemaLibrary::ApplyActionDefaults(UShockAction* Action, const FString& SchemaJsonPath, const FString& ClassName)
{
	TArray<FString> Applied;
	FString Error;
	bool Ok = false;

	if (!Action)
	{
		Error = TEXT("action is null");
	}
	else
	{
		TMap<FString, FSchemaClass> Classes;
		if (!LoadSchema(SchemaJsonPath, Classes, Error))
		{
			Ok = false;
		}
		else if (!Classes.Contains(ClassName))
		{
			Error = FString::Printf(TEXT("class %s is not in %s"), *ClassName, *SchemaJsonPath);
		}
		else
		{
			Action->ActionClassName = ClassName;

			auto ApplyFloat = [&](const TCHAR* Property, const TFunctionRef<void(float)>& Sink)
			{
				FString Text;
				float Value = 0.0f;
				if (Lookup(Classes, ClassName, Property, Text) && ParseFloat(Text, Value))
				{
					Sink(Value);
					Applied.Add(Property);
				}
			};

			if (UShockActionWait* Wait = Cast<UShockActionWait>(Action))
			{
				ApplyFloat(TEXT("Seconds"), [&](float Value) { Wait->Seconds = Value; });
			}
			if (UShockActionSetProperty* SetProp = Cast<UShockActionSetProperty>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("Object"), Text) && !Text.StartsWith(TEXT("<")))
				{
					SetProp->ObjectLabel = FName(*Unquote(Text));
					Applied.Add(TEXT("Object"));
				}
				if (Lookup(Classes, ClassName, TEXT("Property"), Text) && !Text.StartsWith(TEXT("<")))
				{
					SetProp->PropertyName = FName(*Unquote(Text));
					Applied.Add(TEXT("Property"));
				}
				if (Lookup(Classes, ClassName, TEXT("NewValue"), Text) && !Text.StartsWith(TEXT("<")))
				{
					SetProp->NewValue = Unquote(Text);
					Applied.Add(TEXT("NewValue"));
				}
			}
			if (UShockActionPlayEffect* Play = Cast<UShockActionPlayEffect>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("EffectEvent"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Play->EffectEvent = FName(*Unquote(Text));
					Applied.Add(TEXT("EffectEvent"));
				}
				if (Lookup(Classes, ClassName, TEXT("EffectTag"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Play->EffectTag = FName(*Unquote(Text));
					Applied.Add(TEXT("EffectTag"));
				}
				if (Lookup(Classes, ClassName, TEXT("ActorLabel"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Play->ActorLabel = FName(*Unquote(Text));
					Applied.Add(TEXT("ActorLabel"));
				}
			}
			if (UShockActionExecuteScript* Exec = Cast<UShockActionExecuteScript>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("targetScript"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Exec->TargetScript = FName(*Unquote(Text));
					Applied.Add(TEXT("targetScript"));
				}
				if (Lookup(Classes, ClassName, TEXT("block"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Exec->bBlock = Text.Equals(TEXT("true"), ESearchCase::IgnoreCase);
					Applied.Add(TEXT("block"));
				}
			}
			if (UShockActionSetLightProperties* Light = Cast<UShockActionSetLightProperties>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("Object"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Light->ObjectLabel = FName(*Unquote(Text));
					Applied.Add(TEXT("Object"));
				}
			}
			if (UShockActionVariableAssign* Assign = Cast<UShockActionVariableAssign>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("lhs"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Assign->Lhs = FName(*Unquote(Text));
					Applied.Add(TEXT("lhs"));
				}
				if (Lookup(Classes, ClassName, TEXT("rhs"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Assign->Rhs = Unquote(Text);
					Applied.Add(TEXT("rhs"));
				}
			}
			if (UShockActionHideOrShowActor* Hide = Cast<UShockActionHideOrShowActor>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("ActorLabel"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Hide->ActorLabel = FName(*Unquote(Text));
					Applied.Add(TEXT("ActorLabel"));
				}
				if (Lookup(Classes, ClassName, TEXT("HideActor"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Hide->bHideActor = Text.Equals(TEXT("true"), ESearchCase::IgnoreCase);
					Applied.Add(TEXT("HideActor"));
				}
			}
			if (UShockActionSpawnAI* Spawn = Cast<UShockActionSpawnAI>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("SpawnLocationLabel"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Spawn->SpawnLocationLabel = FName(*Unquote(Text));
					Applied.Add(TEXT("SpawnLocationLabel"));
				}
				if (Lookup(Classes, ClassName, TEXT("SpawnedAILabel"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Spawn->SpawnedAILabel = FName(*Unquote(Text));
					Applied.Add(TEXT("SpawnedAILabel"));
				}
				if (Lookup(Classes, ClassName, TEXT("bCorpseCanBeRemoved"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Spawn->bCorpseCanBeRemoved = Text.Equals(TEXT("true"), ESearchCase::IgnoreCase);
					Applied.Add(TEXT("bCorpseCanBeRemoved"));
				}
				if (Lookup(Classes, ClassName, TEXT("bForceSpawn"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Spawn->bForceSpawn = Text.Equals(TEXT("true"), ESearchCase::IgnoreCase);
					Applied.Add(TEXT("bForceSpawn"));
				}
			}
			Ok = true;
		}
	}

	TSharedRef<FJsonObject> Report = MakeShared<FJsonObject>();
	Report->SetBoolField(TEXT("ok"), Ok);
	Report->SetStringField(TEXT("error"), Error);
	TArray<TSharedPtr<FJsonValue>> AppliedJson;
	for (const FString& Name : Applied)
	{
		AppliedJson.Add(MakeShared<FJsonValueString>(Name));
	}
	Report->SetArrayField(TEXT("applied"), AppliedJson);
	FString Output;
	const TSharedRef<TJsonWriter<>> Writer = TJsonWriterFactory<>::Create(&Output);
	FJsonSerializer::Serialize(Report, Writer);
	return Output;
}
