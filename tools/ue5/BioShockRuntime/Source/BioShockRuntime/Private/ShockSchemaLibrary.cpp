#include "ShockSchemaLibrary.h"

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
