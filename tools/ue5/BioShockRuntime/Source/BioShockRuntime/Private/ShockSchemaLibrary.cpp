#include "ShockSchemaLibrary.h"

#include "ShockAction.h"
#include "ShockActionActivateResurrectionStation.h"
#include "ShockActionAISpeech.h"
#include "ShockActionAssassinTeleport.h"
#include "ShockActionAssertFact.h"
#include "ShockActionAttackTarget.h"
#include "ShockActionBlockingExecuteScript.h"
#include "ShockActionChangeCollision.h"
#include "ShockActionChangePawnPhysics.h"
#include "ShockActionChangePressure.h"
#include "ShockActionChangeQuestArrowActor.h"
#include "ShockActionChangeSkinAtIndex.h"
#include "ShockActionCinematicFadeView.h"
#include "ShockActionCloseDoor.h"
#include "ShockActionCompleteQuest.h"
#include "ShockActionCompleteQuestObjective.h"
#include "ShockActionControlScriptedSequence.h"
#include "ShockActionDealDamage.h"
#include "ShockActionDestroyActor.h"
#include "ShockActionDisableOrEnableConcept.h"
#include "ShockActionDisplayOnScreenDebugMessage.h"
#include "ShockActionEnableOrDisableLevelSaving.h"
#include "ShockActionExecuteScript.h"
#include "ShockActionExitScript.h"
#include "ShockActionFadeVolumeOverride.h"
#include "ShockActionFreezeHavokActor.h"
#include "ShockActionGiveItemsToPlayer.h"
#include "ShockActionHideOrShowActor.h"
#include "ShockActionInitiateDamage.h"
#include "ShockActionInitiateQuest.h"
#include "ShockActionLockDoor.h"
#include "ShockActionLog.h"
#include "ShockActionLoop.h"
#include "ShockActionManipulateSpawnZoneRepopulation.h"
#include "ShockActionMuteAI.h"
#include "ShockActionNonBlockingExecuteScript.h"
#include "ShockActionOpenDoor.h"
#include "ShockActionPlayAnimation.h"
#include "ShockActionPlayEffect.h"
#include "ShockActionPlayScriptedHandAnimation.h"
#include "ShockActionPostMovementGoal.h"
#include "ShockActionRemoveGoal.h"
#include "ShockActionRetractFact.h"
#include "ShockActionRunConsoleCommand.h"
#include "ShockActionScriptNote.h"
#include "ShockActionSendTriggerMessage.h"
#include "ShockActionSetActorLabel.h"
#include "ShockActionSetAINormalLODOverrideTime.h"
#include "ShockActionSetAIPatrol.h"
#include "ShockActionSetAIVulnerability.h"
#include "ShockActionSetHUDDisplayState.h"
#include "ShockActionSetLightProperties.h"
#include "ShockActionSetMaterialSwitchIndex.h"
#include "ShockActionSetMovableSpotlightState.h"
#include "ShockActionSetMovableSpotlightTarget.h"
#include "ShockActionSetOrUnsetInputContext.h"
#include "ShockActionSetPawnInvincibility.h"
#include "ShockActionSetPlayerInvincibility.h"
#include "ShockActionSetProperty.h"
#include "ShockActionSetQuestHint.h"
#include "ShockActionSetTipPriority.h"
#include "ShockActionShockInventory.h"
#include "ShockActionShowTrainingMessage.h"
#include "ShockActionSpawnAI.h"
#include "ShockActionSpawnReactiveActor.h"
#include "ShockActionSpawnSecurityBot.h"
#include "ShockActionSpawnTurret.h"
#include "ShockActionStartScriptedHandAnimationSequence.h"
#include "ShockActionStopEffect.h"
#include "ShockActionStopScriptedHandAnimationSequence.h"
#include "ShockActionTeleportPawnToLocation.h"
#include "ShockActionToggleAIAttachmentVisibility.h"
#include "ShockActionToggleAIAttacking.h"
#include "ShockActionToggleAIReactions.h"
#include "ShockActionToggleAIWeaponVisibility.h"
#include "ShockActionTriggerHavokForceActor.h"
#include "ShockActionTweakAIHearing.h"
#include "ShockActionTweakAIVision.h"
#include "ShockActionUnlockBathysphereDestination.h"
#include "ShockActionUnlockDoor.h"
#include "ShockActionVariableAssign.h"
#include "ShockActionVariableDecrement.h"
#include "ShockActionVariableIncrement.h"
#include "ShockActionWait.h"
#include "ShockActionWaitForGoal.h"
#include "ShockActionWaitForQuestLogToFinish.h"
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
			if (UShockActionStopEffect* Stop = Cast<UShockActionStopEffect>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("EffectEvent"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Stop->EffectEvent = FName(*Unquote(Text));
					Applied.Add(TEXT("EffectEvent"));
				}
				if (Lookup(Classes, ClassName, TEXT("EffectTag"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Stop->EffectTag = FName(*Unquote(Text));
					Applied.Add(TEXT("EffectTag"));
				}
				if (Lookup(Classes, ClassName, TEXT("ActorLabel"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Stop->ActorLabel = FName(*Unquote(Text));
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
			if (UShockActionPlayAnimation* Anim = Cast<UShockActionPlayAnimation>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("TargetLabel"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Anim->TargetLabel = FName(*Unquote(Text));
					Applied.Add(TEXT("TargetLabel"));
				}
				if (Lookup(Classes, ClassName, TEXT("Animation"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Anim->Animation = FName(*Unquote(Text));
					Applied.Add(TEXT("Animation"));
				}
				float Rate = 0.0f;
				if (Lookup(Classes, ClassName, TEXT("AnimationRate"), Text) && ParseFloat(Text, Rate))
				{
					Anim->AnimationRate = Rate;
					Applied.Add(TEXT("AnimationRate"));
				}
				if (Lookup(Classes, ClassName, TEXT("bOnlyPlayOnAlivePawns"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Anim->bOnlyPlayOnAlivePawns = Text.Equals(TEXT("true"), ESearchCase::IgnoreCase);
					Applied.Add(TEXT("bOnlyPlayOnAlivePawns"));
				}
			}
			if (UShockActionScriptNote* Note = Cast<UShockActionScriptNote>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("Note"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Note->Note = Unquote(Text);
					Applied.Add(TEXT("Note"));
				}
			}
			if (UShockActionDestroyActor* Destroy = Cast<UShockActionDestroyActor>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("Target"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Destroy->TargetLabel = FName(*Unquote(Text));
					Applied.Add(TEXT("Target"));
				}
			}
			if (UShockActionAttackTarget* Attack = Cast<UShockActionAttackTarget>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("AILabel"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Attack->AILabel = FName(*Unquote(Text));
					Applied.Add(TEXT("AILabel"));
				}
				if (Lookup(Classes, ClassName, TEXT("TargetLabel"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Attack->TargetLabel = FName(*Unquote(Text));
					Applied.Add(TEXT("TargetLabel"));
				}
				if (Lookup(Classes, ClassName, TEXT("bAttackOnSight"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Attack->bAttackOnSight = Text.Equals(TEXT("true"), ESearchCase::IgnoreCase);
					Applied.Add(TEXT("bAttackOnSight"));
				}
			}
			if (UShockActionShockInventory* Inv = Cast<UShockActionShockInventory>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("ItemClass"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Inv->ItemClass = FName(*Unquote(Text));
					Applied.Add(TEXT("ItemClass"));
				}
				int32 Stack = 0;
				if (Lookup(Classes, ClassName, TEXT("StackSize"), Text) && !Text.StartsWith(TEXT("<")))
				{
					LexFromString(Stack, *Text);
					Inv->StackSize = Stack;
					Applied.Add(TEXT("StackSize"));
				}
			}
			if (UShockActionChangeCollision* Coll = Cast<UShockActionChangeCollision>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("Target"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Coll->TargetLabel = FName(*Unquote(Text));
					Applied.Add(TEXT("Target"));
				}
				auto ParseChange = [](const FString& Text, EShockCollisionChange& Out) -> bool
				{
					if (Text.StartsWith(TEXT("<")))
					{
						return false;
					}
					int32 V = 0;
					LexFromString(V, *Text);
					if (V < 0 || V > 2)
					{
						return false;
					}
					Out = static_cast<EShockCollisionChange>(V);
					return true;
				};
				EShockCollisionChange Change = EShockCollisionChange::DoNotChange;
				if (Lookup(Classes, ClassName, TEXT("CollideActors"), Text) && ParseChange(Text, Change))
				{
					Coll->CollideActors = Change;
					Applied.Add(TEXT("CollideActors"));
				}
				if (Lookup(Classes, ClassName, TEXT("CollideWorld"), Text) && ParseChange(Text, Change))
				{
					Coll->CollideWorld = Change;
					Applied.Add(TEXT("CollideWorld"));
				}
				if (Lookup(Classes, ClassName, TEXT("BlockActors"), Text) && ParseChange(Text, Change))
				{
					Coll->BlockActors = Change;
					Applied.Add(TEXT("BlockActors"));
				}
				if (Lookup(Classes, ClassName, TEXT("BlockPlayers"), Text) && ParseChange(Text, Change))
				{
					Coll->BlockPlayers = Change;
					Applied.Add(TEXT("BlockPlayers"));
				}
				if (Lookup(Classes, ClassName, TEXT("BlockNonZeroExtentTraces"), Text) && ParseChange(Text, Change))
				{
					Coll->BlockNonZeroExtentTraces = Change;
					Applied.Add(TEXT("BlockNonZeroExtentTraces"));
				}
				if (Lookup(Classes, ClassName, TEXT("WorldGeometry"), Text) && ParseChange(Text, Change))
				{
					Coll->WorldGeometry = Change;
					Applied.Add(TEXT("WorldGeometry"));
				}
				if (Lookup(Classes, ClassName, TEXT("blockHavok"), Text) && ParseChange(Text, Change))
				{
					Coll->BlockHavok = Change;
					Applied.Add(TEXT("blockHavok"));
				}
			}
			if (UShockActionTweakAIVision* Vision = Cast<UShockActionTweakAIVision>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("AILabel"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Vision->AILabel = FName(*Unquote(Text));
					Applied.Add(TEXT("AILabel"));
				}
				if (Lookup(Classes, ClassName, TEXT("AIClass"), Text) && !Text.StartsWith(TEXT("<")))
				{
					// Class'ShockAI.ShockAI' → ShockAI
					FString ClassText = Unquote(Text);
					ClassText.ReplaceInline(TEXT("Class'"), TEXT(""));
					ClassText.ReplaceInline(TEXT("'"), TEXT(""));
					if (ClassText.Contains(TEXT(".")))
					{
						ClassText = ClassText.RightChop(ClassText.Find(TEXT("."), ESearchCase::CaseSensitive, ESearchDir::FromEnd) + 1);
					}
					Vision->AIClass = FName(*ClassText);
					Applied.Add(TEXT("AIClass"));
				}
				if (Lookup(Classes, ClassName, TEXT("bTurnVisionOn"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Vision->bTurnVisionOn = Text.Equals(TEXT("true"), ESearchCase::IgnoreCase);
					Applied.Add(TEXT("bTurnVisionOn"));
				}
			}
			if (UShockActionTweakAIHearing* Hearing = Cast<UShockActionTweakAIHearing>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("AILabel"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Hearing->AILabel = FName(*Unquote(Text));
					Applied.Add(TEXT("AILabel"));
				}
				if (Lookup(Classes, ClassName, TEXT("AIClass"), Text) && !Text.StartsWith(TEXT("<")))
				{
					FString ClassText = Unquote(Text);
					ClassText.ReplaceInline(TEXT("Class'"), TEXT(""));
					ClassText.ReplaceInline(TEXT("'"), TEXT(""));
					if (ClassText.Contains(TEXT(".")))
					{
						ClassText = ClassText.RightChop(ClassText.Find(TEXT("."), ESearchCase::CaseSensitive, ESearchDir::FromEnd) + 1);
					}
					Hearing->AIClass = FName(*ClassText);
					Applied.Add(TEXT("AIClass"));
				}
				if (Lookup(Classes, ClassName, TEXT("bTurnHearingOn"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Hearing->bTurnHearingOn = Text.Equals(TEXT("true"), ESearchCase::IgnoreCase);
					Applied.Add(TEXT("bTurnHearingOn"));
				}
			}
			if (UShockActionVariableIncrement* Incr = Cast<UShockActionVariableIncrement>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("Target"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Incr->Target = FName(*Unquote(Text));
					Applied.Add(TEXT("Target"));
				}
			}
			if (UShockActionLog* LogAction = Cast<UShockActionLog>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("Text"), Text) && !Text.StartsWith(TEXT("<")))
				{
					LogAction->Text = Unquote(Text);
					Applied.Add(TEXT("Text"));
				}
			}
			if (UShockActionExitScript* Exit = Cast<UShockActionExitScript>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("targetScript"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Exit->TargetScript = FName(*Unquote(Text));
					Applied.Add(TEXT("targetScript"));
				}
			}
			if (UShockActionFreezeHavokActor* Freeze = Cast<UShockActionFreezeHavokActor>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("Target"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Freeze->TargetLabel = FName(*Unquote(Text));
					Applied.Add(TEXT("Target"));
				}
				if (Lookup(Classes, ClassName, TEXT("Freeze"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Freeze->bFreeze = Text.Equals(TEXT("true"), ESearchCase::IgnoreCase);
					Applied.Add(TEXT("Freeze"));
				}
				if (Lookup(Classes, ClassName, TEXT("ActivateWhenUnfreezing"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Freeze->bActivateWhenUnfreezing = Text.Equals(TEXT("true"), ESearchCase::IgnoreCase);
					Applied.Add(TEXT("ActivateWhenUnfreezing"));
				}
			}
			if (UShockActionUnlockDoor* Unlock = Cast<UShockActionUnlockDoor>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("DoorLabel"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Unlock->DoorLabel = FName(*Unquote(Text));
					Applied.Add(TEXT("DoorLabel"));
				}
			}
			if (UShockActionMuteAI* Mute = Cast<UShockActionMuteAI>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("AILabel"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Mute->AILabel = FName(*Unquote(Text));
					Applied.Add(TEXT("AILabel"));
				}
				if (Lookup(Classes, ClassName, TEXT("bShouldMuteAI"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Mute->bShouldMuteAI = Text.Equals(TEXT("true"), ESearchCase::IgnoreCase);
					Applied.Add(TEXT("bShouldMuteAI"));
				}
			}
			if (UShockActionSetTipPriority* Tip = Cast<UShockActionSetTipPriority>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("TipName"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Tip->TipName = FName(*Unquote(Text));
					Applied.Add(TEXT("TipName"));
				}
				int32 Prio = 0;
				if (Lookup(Classes, ClassName, TEXT("Priority"), Text) && !Text.StartsWith(TEXT("<")))
				{
					LexFromString(Prio, *Text);
					Tip->Priority = Prio;
					Applied.Add(TEXT("Priority"));
				}
			}
			if (UShockActionPostMovementGoal* Move = Cast<UShockActionPostMovementGoal>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("Target"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Move->TargetLabel = FName(*Unquote(Text));
					Applied.Add(TEXT("Target"));
				}
				if (Lookup(Classes, ClassName, TEXT("DestinationLabel"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Move->DestinationLabel = FName(*Unquote(Text));
					Applied.Add(TEXT("DestinationLabel"));
				}
				if (Lookup(Classes, ClassName, TEXT("goalName"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Move->GoalName = Unquote(Text);
					Applied.Add(TEXT("goalName"));
				}
				int32 Prio = 0;
				if (Lookup(Classes, ClassName, TEXT("Priority"), Text) && !Text.StartsWith(TEXT("<")))
				{
					LexFromString(Prio, *Text);
					Move->Priority = Prio;
					Applied.Add(TEXT("Priority"));
				}
				if (Lookup(Classes, ClassName, TEXT("bShouldRun"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Move->bShouldRun = Text.Equals(TEXT("true"), ESearchCase::IgnoreCase);
					Applied.Add(TEXT("bShouldRun"));
				}
			}
			if (UShockActionCinematicFadeView* Fade = Cast<UShockActionCinematicFadeView>(Action))
			{
				FString Text;
				float V = 0.0f;
				if (Lookup(Classes, ClassName, TEXT("fadeAlphaStart"), Text) && ParseFloat(Text, V))
				{
					Fade->FadeAlphaStart = V;
					Applied.Add(TEXT("fadeAlphaStart"));
				}
				if (Lookup(Classes, ClassName, TEXT("fadeAlphaEnd"), Text) && ParseFloat(Text, V))
				{
					Fade->FadeAlphaEnd = V;
					Applied.Add(TEXT("fadeAlphaEnd"));
				}
				if (Lookup(Classes, ClassName, TEXT("Duration"), Text) && ParseFloat(Text, V))
				{
					Fade->Duration = V;
					Applied.Add(TEXT("Duration"));
				}
				if (Lookup(Classes, ClassName, TEXT("holdDuration"), Text) && ParseFloat(Text, V))
				{
					Fade->HoldDuration = V;
					Applied.Add(TEXT("holdDuration"));
				}
			}
			if (UShockActionDisableOrEnableConcept* Concept = Cast<UShockActionDisableOrEnableConcept>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("ConceptName"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Concept->ConceptName = FName(*Unquote(Text));
					Applied.Add(TEXT("ConceptName"));
				}
				if (Lookup(Classes, ClassName, TEXT("Enable"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Concept->bEnable = Text.Equals(TEXT("true"), ESearchCase::IgnoreCase);
					Applied.Add(TEXT("Enable"));
				}
			}
			if (UShockActionControlScriptedSequence* Seq = Cast<UShockActionControlScriptedSequence>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("TargetLabel"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Seq->TargetLabel = FName(*Unquote(Text));
					Applied.Add(TEXT("TargetLabel"));
				}
				int32 Run = 0;
				if (Lookup(Classes, ClassName, TEXT("RunNow"), Text) && !Text.StartsWith(TEXT("<")))
				{
					LexFromString(Run, *Text);
					Seq->RunNow = Run;
					Applied.Add(TEXT("RunNow"));
				}
			}
			if (UShockActionDealDamage* Dmg = Cast<UShockActionDealDamage>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("Target"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Dmg->TargetLabel = FName(*Unquote(Text));
					Applied.Add(TEXT("Target"));
				}
				float V = 0.0f;
				if (Lookup(Classes, ClassName, TEXT("DamageAmount"), Text) && ParseFloat(Text, V))
				{
					Dmg->DamageAmount = V;
					Applied.Add(TEXT("DamageAmount"));
				}
				if (Lookup(Classes, ClassName, TEXT("DamageChance"), Text) && ParseFloat(Text, V))
				{
					Dmg->DamageChance = V;
					Applied.Add(TEXT("DamageChance"));
				}
			}
			if (UShockActionWaitForGoal* WaitGoal = Cast<UShockActionWaitForGoal>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("Target"), Text) && !Text.StartsWith(TEXT("<")))
				{
					WaitGoal->TargetLabel = FName(*Unquote(Text));
					Applied.Add(TEXT("Target"));
				}
				if (Lookup(Classes, ClassName, TEXT("goalName"), Text) && !Text.StartsWith(TEXT("<")))
				{
					WaitGoal->GoalName = Unquote(Text);
					Applied.Add(TEXT("goalName"));
				}
				float V = 0.0f;
				if (Lookup(Classes, ClassName, TEXT("TimeOut"), Text) && ParseFloat(Text, V))
				{
					WaitGoal->TimeOut = V;
					Applied.Add(TEXT("TimeOut"));
				}
			}
			if (UShockActionChangeSkinAtIndex* Skin = Cast<UShockActionChangeSkinAtIndex>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("TargetLabel"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Skin->TargetLabel = FName(*Unquote(Text));
					Applied.Add(TEXT("TargetLabel"));
				}
				if (Lookup(Classes, ClassName, TEXT("Material"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Skin->MaterialName = FName(*Unquote(Text));
					Applied.Add(TEXT("Material"));
				}
				int32 Idx = 0;
				if (Lookup(Classes, ClassName, TEXT("Index"), Text) && !Text.StartsWith(TEXT("<")))
				{
					LexFromString(Idx, *Text);
					Skin->Index = Idx;
					Applied.Add(TEXT("Index"));
				}
			}
			if (UShockActionOpenDoor* Open = Cast<UShockActionOpenDoor>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("DoorLabel"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Open->DoorLabel = FName(*Unquote(Text));
					Applied.Add(TEXT("DoorLabel"));
				}
				if (Lookup(Classes, ClassName, TEXT("StayOpen"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Open->bStayOpen = Text.Equals(TEXT("true"), ESearchCase::IgnoreCase);
					Applied.Add(TEXT("StayOpen"));
				}
			}
			if (UShockActionAISpeech* Speech = Cast<UShockActionAISpeech>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("AILabel"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Speech->AILabel = FName(*Unquote(Text));
					Applied.Add(TEXT("AILabel"));
				}
				if (Lookup(Classes, ClassName, TEXT("SpeechEventLabel"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Speech->SpeechEventLabel = FName(*Unquote(Text));
					Applied.Add(TEXT("SpeechEventLabel"));
				}
				if (Lookup(Classes, ClassName, TEXT("bStopSpeech"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Speech->bStopSpeech = Text.Equals(TEXT("true"), ESearchCase::IgnoreCase);
					Applied.Add(TEXT("bStopSpeech"));
				}
			}
			if (UShockActionAssertFact* Fact = Cast<UShockActionAssertFact>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("Slot_1"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Fact->Slot1 = FName(*Unquote(Text));
					Applied.Add(TEXT("Slot_1"));
				}
				if (Lookup(Classes, ClassName, TEXT("Slot_2"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Fact->Slot2 = Unquote(Text);
					Applied.Add(TEXT("Slot_2"));
				}
				if (Lookup(Classes, ClassName, TEXT("Slot_3"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Fact->Slot3 = Unquote(Text);
					Applied.Add(TEXT("Slot_3"));
				}
			}
			if (UShockActionLoop* Loop = Cast<UShockActionLoop>(Action))
			{
				FString Text;
				int32 Idx = 0;
				if (Lookup(Classes, ClassName, TEXT("CurrentIndex"), Text) && !Text.StartsWith(TEXT("<")))
				{
					LexFromString(Idx, *Text);
					Loop->CurrentIndex = Idx;
					Applied.Add(TEXT("CurrentIndex"));
				}
			}
			if (UShockActionTeleportPawnToLocation* Tele = Cast<UShockActionTeleportPawnToLocation>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("PawnLabel"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Tele->PawnLabel = FName(*Unquote(Text));
					Applied.Add(TEXT("PawnLabel"));
				}
				if (Lookup(Classes, ClassName, TEXT("MarkerLabel"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Tele->MarkerLabel = FName(*Unquote(Text));
					Applied.Add(TEXT("MarkerLabel"));
				}
			}
			if (UShockActionSetOrUnsetInputContext* Ctx = Cast<UShockActionSetOrUnsetInputContext>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("Context"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Ctx->Context = FName(*Unquote(Text));
					Applied.Add(TEXT("Context"));
				}
				if (Lookup(Classes, ClassName, TEXT("Unset"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Ctx->bUnset = Text.Equals(TEXT("true"), ESearchCase::IgnoreCase);
					Applied.Add(TEXT("Unset"));
				}
			}
			if (UShockActionManipulateSpawnZoneRepopulation* Zone = Cast<UShockActionManipulateSpawnZoneRepopulation>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("SpawnZoneName"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Zone->SpawnZoneName = FName(*Unquote(Text));
					Applied.Add(TEXT("SpawnZoneName"));
				}
				auto ParseRepop = [](const FString& Text, EShockSpawnZoneRepopulationState& Out) -> bool
				{
					if (Text.StartsWith(TEXT("<")))
					{
						return false;
					}
					int32 V = 0;
					LexFromString(V, *Text);
					if (V < 0 || V > 2)
					{
						return false;
					}
					Out = static_cast<EShockSpawnZoneRepopulationState>(V);
					return true;
				};
				EShockSpawnZoneRepopulationState State = EShockSpawnZoneRepopulationState::NoChange;
				if (Lookup(Classes, ClassName, TEXT("AggressorRepopulationState"), Text) && ParseRepop(Text, State))
				{
					Zone->AggressorState = State;
					Applied.Add(TEXT("AggressorRepopulationState"));
				}
				if (Lookup(Classes, ClassName, TEXT("ProtectorRepopulationState"), Text) && ParseRepop(Text, State))
				{
					Zone->ProtectorState = State;
					Applied.Add(TEXT("ProtectorRepopulationState"));
				}
			}
			if (UShockActionInitiateQuest* Quest = Cast<UShockActionInitiateQuest>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("QuestName"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Quest->QuestName = FName(*Unquote(Text));
					Applied.Add(TEXT("QuestName"));
				}
				if (Lookup(Classes, ClassName, TEXT("ShowHUDFeedBack"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Quest->bShowHUDFeedBack = Text.Equals(TEXT("true"), ESearchCase::IgnoreCase);
					Applied.Add(TEXT("ShowHUDFeedBack"));
				}
				if (Lookup(Classes, ClassName, TEXT("SetAsActiveQuest"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Quest->bSetAsActiveQuest = Text.Equals(TEXT("true"), ESearchCase::IgnoreCase);
					Applied.Add(TEXT("SetAsActiveQuest"));
				}
				if (Lookup(Classes, ClassName, TEXT("NewQuestMessage"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Quest->NewQuestMessage = Unquote(Text);
					Applied.Add(TEXT("NewQuestMessage"));
				}
			}
			if (UShockActionSetMovableSpotlightTarget* Spot = Cast<UShockActionSetMovableSpotlightTarget>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("SpotlightLabel"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Spot->SpotlightLabel = FName(*Unquote(Text));
					Applied.Add(TEXT("SpotlightLabel"));
				}
				if (Lookup(Classes, ClassName, TEXT("TargetActorLabel"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Spot->TargetActorLabel = FName(*Unquote(Text));
					Applied.Add(TEXT("TargetActorLabel"));
				}
			}
			if (UShockActionChangePressure* Press = Cast<UShockActionChangePressure>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("RegionName"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Press->RegionName = FName(*Unquote(Text));
					Applied.Add(TEXT("RegionName"));
				}
				int32 V = 0;
				if (Lookup(Classes, ClassName, TEXT("DesiredPressure"), Text) && !Text.StartsWith(TEXT("<")))
				{
					LexFromString(V, *Text);
					Press->DesiredPressure = static_cast<uint8>(FMath::Clamp(V, 0, 255));
					Applied.Add(TEXT("DesiredPressure"));
				}
			}
			if (UShockActionWaitForQuestLogToFinish* QuestLog = Cast<UShockActionWaitForQuestLogToFinish>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("QuestLog"), Text) && !Text.StartsWith(TEXT("<")))
				{
					QuestLog->QuestLogClassName = FName(*Unquote(Text));
					Applied.Add(TEXT("QuestLog"));
				}
				float V = 0.0f;
				if (Lookup(Classes, ClassName, TEXT("TimeoutSeconds"), Text) && ParseFloat(Text, V))
				{
					QuestLog->TimeoutSeconds = V;
					Applied.Add(TEXT("TimeoutSeconds"));
				}
			}
			if (UShockActionSetMovableSpotlightState* SpotState = Cast<UShockActionSetMovableSpotlightState>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("SpotlightLabel"), Text) && !Text.StartsWith(TEXT("<")))
				{
					SpotState->SpotlightLabel = FName(*Unquote(Text));
					Applied.Add(TEXT("SpotlightLabel"));
				}
				if (Lookup(Classes, ClassName, TEXT("SpotlightOn"), Text) && !Text.StartsWith(TEXT("<")))
				{
					SpotState->bSpotlightOn = Text.Equals(TEXT("true"), ESearchCase::IgnoreCase);
					Applied.Add(TEXT("SpotlightOn"));
				}
			}
			if (UShockActionCloseDoor* Close = Cast<UShockActionCloseDoor>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("DoorLabel"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Close->DoorLabel = FName(*Unquote(Text));
					Applied.Add(TEXT("DoorLabel"));
				}
				if (Lookup(Classes, ClassName, TEXT("ForceClose"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Close->bForceClose = Text.Equals(TEXT("true"), ESearchCase::IgnoreCase);
					Applied.Add(TEXT("ForceClose"));
				}
			}
			if (UShockActionToggleAIReactions* React = Cast<UShockActionToggleAIReactions>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("AILabel"), Text) && !Text.StartsWith(TEXT("<")))
				{
					React->AILabel = FName(*Unquote(Text));
					Applied.Add(TEXT("AILabel"));
				}
				auto ParseToggle = [](const FString& Text, EShockToggleHitReactions& Out) -> bool
				{
					if (Text.StartsWith(TEXT("<")))
					{
						return false;
					}
					int32 V = 0;
					LexFromString(V, *Text);
					if (V < 0 || V > 2)
					{
						return false;
					}
					Out = static_cast<EShockToggleHitReactions>(V);
					return true;
				};
				EShockToggleHitReactions Toggle = EShockToggleHitReactions::DoNotChange;
				if (Lookup(Classes, ClassName, TEXT("FullBodyHitReactions"), Text) && ParseToggle(Text, Toggle))
				{
					React->FullBodyHitReactions = Toggle;
					Applied.Add(TEXT("FullBodyHitReactions"));
				}
				if (Lookup(Classes, ClassName, TEXT("QuickHitReactions"), Text) && ParseToggle(Text, Toggle))
				{
					React->QuickHitReactions = Toggle;
					Applied.Add(TEXT("QuickHitReactions"));
				}
				if (Lookup(Classes, ClassName, TEXT("FallDownHitReactions"), Text) && ParseToggle(Text, Toggle))
				{
					React->FallDownHitReactions = Toggle;
					Applied.Add(TEXT("FallDownHitReactions"));
				}
				if (Lookup(Classes, ClassName, TEXT("EventReactions"), Text) && ParseToggle(Text, Toggle))
				{
					React->EventReactions = Toggle;
					Applied.Add(TEXT("EventReactions"));
				}
			}
			if (UShockActionSendTriggerMessage* Trig = Cast<UShockActionSendTriggerMessage>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("Instigator"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Trig->InstigatorLabel = FName(*Unquote(Text));
					Applied.Add(TEXT("Instigator"));
				}
			}
			if (UShockActionDisplayOnScreenDebugMessage* Dbg = Cast<UShockActionDisplayOnScreenDebugMessage>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("Message"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Dbg->Message = Unquote(Text);
					Applied.Add(TEXT("Message"));
				}
			}
			if (UShockActionSetPlayerInvincibility* Inv = Cast<UShockActionSetPlayerInvincibility>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("bInvincible"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Inv->bInvincible = Text.Equals(TEXT("true"), ESearchCase::IgnoreCase);
					Applied.Add(TEXT("bInvincible"));
				}
			}
			if (UShockActionRunConsoleCommand* Cmd = Cast<UShockActionRunConsoleCommand>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("Command"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Cmd->Command = Unquote(Text);
					Applied.Add(TEXT("Command"));
				}
			}
			if (UShockActionSetAIPatrol* Patrol = Cast<UShockActionSetAIPatrol>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("AggressorLabel"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Patrol->AggressorLabel = FName(*Unquote(Text));
					Applied.Add(TEXT("AggressorLabel"));
				}
				if (Lookup(Classes, ClassName, TEXT("PatrolName"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Patrol->PatrolName = FName(*Unquote(Text));
					Applied.Add(TEXT("PatrolName"));
				}
			}
			if (UShockActionChangePawnPhysics* Phys = Cast<UShockActionChangePawnPhysics>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("Target"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Phys->TargetLabel = FName(*Unquote(Text));
					Applied.Add(TEXT("Target"));
				}
				if (Lookup(Classes, ClassName, TEXT("DisablePhysics"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Phys->bDisablePhysics = Text.Equals(TEXT("true"), ESearchCase::IgnoreCase);
					Applied.Add(TEXT("DisablePhysics"));
				}
				if (Lookup(Classes, ClassName, TEXT("EnableRootMotionWhenPhysicsDisabled"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Phys->bEnableRootMotionWhenPhysicsDisabled = Text.Equals(TEXT("true"), ESearchCase::IgnoreCase);
					Applied.Add(TEXT("EnableRootMotionWhenPhysicsDisabled"));
				}
			}
			if (UShockActionSetPawnInvincibility* PawnInv = Cast<UShockActionSetPawnInvincibility>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("PawnLabel"), Text) && !Text.StartsWith(TEXT("<")))
				{
					PawnInv->PawnLabel = FName(*Unquote(Text));
					Applied.Add(TEXT("PawnLabel"));
				}
				if (Lookup(Classes, ClassName, TEXT("bInvincible"), Text) && !Text.StartsWith(TEXT("<")))
				{
					PawnInv->bInvincible = Text.Equals(TEXT("true"), ESearchCase::IgnoreCase);
					Applied.Add(TEXT("bInvincible"));
				}
			}
			if (UShockActionSetAINormalLODOverrideTime* Lod = Cast<UShockActionSetAINormalLODOverrideTime>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("AILabel"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Lod->AILabel = FName(*Unquote(Text));
					Applied.Add(TEXT("AILabel"));
				}
				float V = 0.0f;
				if (Lookup(Classes, ClassName, TEXT("LODOverrideTime"), Text) && ParseFloat(Text, V))
				{
					Lod->LODOverrideTime = V;
					Applied.Add(TEXT("LODOverrideTime"));
				}
			}
			if (UShockActionSpawnReactiveActor* Reactive = Cast<UShockActionSpawnReactiveActor>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("ActorLabel"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Reactive->ActorLabel = FName(*Unquote(Text));
					Applied.Add(TEXT("ActorLabel"));
				}
				if (Lookup(Classes, ClassName, TEXT("TargetActorLabel"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Reactive->TargetActorLabel = FName(*Unquote(Text));
					Applied.Add(TEXT("TargetActorLabel"));
				}
				if (Lookup(Classes, ClassName, TEXT("ReactiveActorClass"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Reactive->ReactiveActorClassName = FName(*Unquote(Text));
					Applied.Add(TEXT("ReactiveActorClass"));
				}
				if (Lookup(Classes, ClassName, TEXT("StartsPhysical"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Reactive->bStartsPhysical = Text.Equals(TEXT("true"), ESearchCase::IgnoreCase);
					Applied.Add(TEXT("StartsPhysical"));
				}
			}
			if (UShockActionActivateResurrectionStation* Station = Cast<UShockActionActivateResurrectionStation>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("ResurrectionStationLabel"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Station->ResurrectionStationLabel = FName(*Unquote(Text));
					Applied.Add(TEXT("ResurrectionStationLabel"));
				}
				if (Lookup(Classes, ClassName, TEXT("ActivateStation"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Station->bActivateStation = Text.Equals(TEXT("true"), ESearchCase::IgnoreCase);
					Applied.Add(TEXT("ActivateStation"));
				}
			}
			if (UShockActionLockDoor* Lock = Cast<UShockActionLockDoor>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("DoorLabel"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Lock->DoorLabel = FName(*Unquote(Text));
					Applied.Add(TEXT("DoorLabel"));
				}
			}
			if (UShockActionShowTrainingMessage* Train = Cast<UShockActionShowTrainingMessage>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("MessageName"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Train->MessageName = FName(*Unquote(Text));
					Applied.Add(TEXT("MessageName"));
				}
			}
			if (UShockActionCompleteQuest* Complete = Cast<UShockActionCompleteQuest>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("QuestName"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Complete->QuestName = FName(*Unquote(Text));
					Applied.Add(TEXT("QuestName"));
				}
				if (Lookup(Classes, ClassName, TEXT("ShowHUDFeedBack"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Complete->bShowHUDFeedBack = Text.Equals(TEXT("true"), ESearchCase::IgnoreCase);
					Applied.Add(TEXT("ShowHUDFeedBack"));
				}
			}
			if (UShockActionRemoveGoal* Remove = Cast<UShockActionRemoveGoal>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("Target"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Remove->TargetLabel = FName(*Unquote(Text));
					Applied.Add(TEXT("Target"));
				}
				if (Lookup(Classes, ClassName, TEXT("goalName"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Remove->GoalName = Unquote(Text);
					Applied.Add(TEXT("goalName"));
				}
			}
			if (UShockActionToggleAIAttacking* Attack = Cast<UShockActionToggleAIAttacking>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("AILabel"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Attack->AILabel = FName(*Unquote(Text));
					Applied.Add(TEXT("AILabel"));
				}
				if (Lookup(Classes, ClassName, TEXT("bCanAttack"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Attack->bCanAttack = Text.Equals(TEXT("true"), ESearchCase::IgnoreCase);
					Applied.Add(TEXT("bCanAttack"));
				}
			}
			if (UShockActionSetActorLabel* Relabel = Cast<UShockActionSetActorLabel>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("ActorLabel"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Relabel->ActorLabel = FName(*Unquote(Text));
					Applied.Add(TEXT("ActorLabel"));
				}
				if (Lookup(Classes, ClassName, TEXT("NewLabel"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Relabel->NewLabel = FName(*Unquote(Text));
					Applied.Add(TEXT("NewLabel"));
				}
			}
			if (UShockActionFadeVolumeOverride* FadeVol = Cast<UShockActionFadeVolumeOverride>(Action))
			{
				FString Text;
				float V = 0.0f;
				if (Lookup(Classes, ClassName, TEXT("Volume"), Text) && ParseFloat(Text, V))
				{
					FadeVol->Volume = V;
					Applied.Add(TEXT("Volume"));
				}
				if (Lookup(Classes, ClassName, TEXT("Duration"), Text) && ParseFloat(Text, V))
				{
					FadeVol->Duration = V;
					Applied.Add(TEXT("Duration"));
				}
			}
			if (UShockActionInitiateDamage* InitDmg = Cast<UShockActionInitiateDamage>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("DamagerLabel"), Text) && !Text.StartsWith(TEXT("<")))
				{
					InitDmg->DamagerLabel = FName(*Unquote(Text));
					Applied.Add(TEXT("DamagerLabel"));
				}
				if (Lookup(Classes, ClassName, TEXT("SourceLabel"), Text) && !Text.StartsWith(TEXT("<")))
				{
					InitDmg->SourceLabel = FName(*Unquote(Text));
					Applied.Add(TEXT("SourceLabel"));
				}
				if (Lookup(Classes, ClassName, TEXT("TargetLabel"), Text) && !Text.StartsWith(TEXT("<")))
				{
					InitDmg->TargetLabel = FName(*Unquote(Text));
					Applied.Add(TEXT("TargetLabel"));
				}
				if (Lookup(Classes, ClassName, TEXT("DamageClass"), Text) && !Text.StartsWith(TEXT("<")))
				{
					InitDmg->DamageClassName = FName(*Unquote(Text));
					Applied.Add(TEXT("DamageClass"));
				}
				float V = 0.0f;
				if (Lookup(Classes, ClassName, TEXT("OverrideInitialVelocity"), Text) && ParseFloat(Text, V))
				{
					InitDmg->OverrideInitialVelocity = V;
					Applied.Add(TEXT("OverrideInitialVelocity"));
				}
			}
			if (UShockActionTriggerHavokForceActor* Force = Cast<UShockActionTriggerHavokForceActor>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("Target"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Force->TargetLabel = FName(*Unquote(Text));
					Applied.Add(TEXT("Target"));
				}
			}
			if (UShockActionChangeQuestArrowActor* Arrow = Cast<UShockActionChangeQuestArrowActor>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("QuestName"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Arrow->QuestName = FName(*Unquote(Text));
					Applied.Add(TEXT("QuestName"));
				}
				if (Lookup(Classes, ClassName, TEXT("ArrowActor"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Arrow->ArrowActor = FName(*Unquote(Text));
					Applied.Add(TEXT("ArrowActor"));
				}
				if (Lookup(Classes, ClassName, TEXT("ArrowActorLevelLabel"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Arrow->ArrowActorLevelLabel = FName(*Unquote(Text));
					Applied.Add(TEXT("ArrowActorLevelLabel"));
				}
			}
			if (UShockActionEnableOrDisableLevelSaving* Save = Cast<UShockActionEnableOrDisableLevelSaving>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("DisableLevelSaving"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Save->bDisableLevelSaving = Text.Equals(TEXT("true"), ESearchCase::IgnoreCase);
					Applied.Add(TEXT("DisableLevelSaving"));
				}
			}
			if (UShockActionRetractFact* Retract = Cast<UShockActionRetractFact>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("Slot_1"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Retract->Slot1 = FName(*Unquote(Text));
					Applied.Add(TEXT("Slot_1"));
				}
				if (Lookup(Classes, ClassName, TEXT("Slot_2"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Retract->Slot2 = Unquote(Text);
					Applied.Add(TEXT("Slot_2"));
				}
				if (Lookup(Classes, ClassName, TEXT("Slot_3"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Retract->Slot3 = Unquote(Text);
					Applied.Add(TEXT("Slot_3"));
				}
			}
			if (UShockActionSetAIVulnerability* Vuln = Cast<UShockActionSetAIVulnerability>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("AILabel"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Vuln->AILabel = FName(*Unquote(Text));
					Applied.Add(TEXT("AILabel"));
				}
				if (Lookup(Classes, ClassName, TEXT("bVulnerable"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Vuln->bVulnerable = Text.Equals(TEXT("true"), ESearchCase::IgnoreCase);
					Applied.Add(TEXT("bVulnerable"));
				}
				if (Lookup(Classes, ClassName, TEXT("bCannotDie"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Vuln->bCannotDie = Text.Equals(TEXT("true"), ESearchCase::IgnoreCase);
					Applied.Add(TEXT("bCannotDie"));
				}
				if (Lookup(Classes, ClassName, TEXT("bCannotBecomeUnconscious"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Vuln->bCannotBecomeUnconscious = Text.Equals(TEXT("true"), ESearchCase::IgnoreCase);
					Applied.Add(TEXT("bCannotBecomeUnconscious"));
				}
			}
			if (UShockActionVariableDecrement* Dec = Cast<UShockActionVariableDecrement>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("Target"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Dec->Target = FName(*Unquote(Text));
					Applied.Add(TEXT("Target"));
				}
			}
			if (UShockActionSetMaterialSwitchIndex* MatSwitch = Cast<UShockActionSetMaterialSwitchIndex>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("Material"), Text) && !Text.StartsWith(TEXT("<")))
				{
					MatSwitch->MaterialSwitchName = FName(*Unquote(Text));
					Applied.Add(TEXT("Material"));
				}
				float V = 0.0f;
				if (Lookup(Classes, ClassName, TEXT("Index"), Text) && ParseFloat(Text, V))
				{
					MatSwitch->Index = V;
					Applied.Add(TEXT("Index"));
				}
			}
			if (UShockActionToggleAIAttachmentVisibility* Attach = Cast<UShockActionToggleAIAttachmentVisibility>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("AILabel"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Attach->AILabel = FName(*Unquote(Text));
					Applied.Add(TEXT("AILabel"));
				}
				if (Lookup(Classes, ClassName, TEXT("AttachmentCategory"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Attach->AttachmentCategory = FName(*Unquote(Text));
					Applied.Add(TEXT("AttachmentCategory"));
				}
				if (Lookup(Classes, ClassName, TEXT("bHideAttachments"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Attach->bHideAttachments = Text.Equals(TEXT("true"), ESearchCase::IgnoreCase);
					Applied.Add(TEXT("bHideAttachments"));
				}
			}
			if (UShockActionPlayScriptedHandAnimation* Hand = Cast<UShockActionPlayScriptedHandAnimation>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("HandAnimation"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Hand->HandAnimation = FName(*Unquote(Text));
					Applied.Add(TEXT("HandAnimation"));
				}
				if (Lookup(Classes, ClassName, TEXT("AttachmentAnimation"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Hand->AttachmentAnimation = FName(*Unquote(Text));
					Applied.Add(TEXT("AttachmentAnimation"));
				}
				int32 End = 0;
				if (Lookup(Classes, ClassName, TEXT("AnimationEndBehavior"), Text) && !Text.StartsWith(TEXT("<")))
				{
					LexFromString(End, *Text);
					Hand->AnimationEndBehavior = End;
					Applied.Add(TEXT("AnimationEndBehavior"));
				}
				float V = 0.0f;
				if (Lookup(Classes, ClassName, TEXT("EaseIn"), Text) && ParseFloat(Text, V))
				{
					Hand->EaseIn = V;
					Applied.Add(TEXT("EaseIn"));
				}
				if (Lookup(Classes, ClassName, TEXT("WaitForAnimationToFinish"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Hand->bWaitForAnimationToFinish = Text.Equals(TEXT("true"), ESearchCase::IgnoreCase);
					Applied.Add(TEXT("WaitForAnimationToFinish"));
				}
			}
			if (UShockActionCompleteQuestObjective* Obj = Cast<UShockActionCompleteQuestObjective>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("QuestName"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Obj->QuestName = FName(*Unquote(Text));
					Applied.Add(TEXT("QuestName"));
				}
				if (Lookup(Classes, ClassName, TEXT("ShowHUDFeedBack"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Obj->bShowHUDFeedBack = Text.Equals(TEXT("true"), ESearchCase::IgnoreCase);
					Applied.Add(TEXT("ShowHUDFeedBack"));
				}
				int32 Count = 0;
				if (Lookup(Classes, ClassName, TEXT("NumberOfObjectivesCompleted"), Text) && !Text.StartsWith(TEXT("<")))
				{
					LexFromString(Count, *Text);
					Obj->NumberOfObjectivesCompleted = Count;
					Applied.Add(TEXT("NumberOfObjectivesCompleted"));
				}
			}
			if (UShockActionSetHUDDisplayState* Hud = Cast<UShockActionSetHUDDisplayState>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("EnableHUD"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Hud->bEnableHUD = Text.Equals(TEXT("true"), ESearchCase::IgnoreCase);
					Applied.Add(TEXT("EnableHUD"));
				}
			}
			if (UShockActionAssassinTeleport* Assassin = Cast<UShockActionAssassinTeleport>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("AssassinLabel"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Assassin->AssassinLabel = FName(*Unquote(Text));
					Applied.Add(TEXT("AssassinLabel"));
				}
				if (Lookup(Classes, ClassName, TEXT("TeleportLabel"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Assassin->TeleportLabel = FName(*Unquote(Text));
					Applied.Add(TEXT("TeleportLabel"));
				}
				if (Lookup(Classes, ClassName, TEXT("TeleportRotationLabel"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Assassin->TeleportRotationLabel = FName(*Unquote(Text));
					Applied.Add(TEXT("TeleportRotationLabel"));
				}
				if (Lookup(Classes, ClassName, TEXT("bUseTeleportOutEffects"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Assassin->bUseTeleportOutEffects = Text.Equals(TEXT("true"), ESearchCase::IgnoreCase);
					Applied.Add(TEXT("bUseTeleportOutEffects"));
				}
				if (Lookup(Classes, ClassName, TEXT("bSkipEtherTime"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Assassin->bSkipEtherTime = Text.Equals(TEXT("true"), ESearchCase::IgnoreCase);
					Applied.Add(TEXT("bSkipEtherTime"));
				}
			}
			if (UShockActionSetQuestHint* Hint = Cast<UShockActionSetQuestHint>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("QuestName"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Hint->QuestName = FName(*Unquote(Text));
					Applied.Add(TEXT("QuestName"));
				}
				if (Lookup(Classes, ClassName, TEXT("HintName"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Hint->HintName = FName(*Unquote(Text));
					Applied.Add(TEXT("HintName"));
				}
			}
			if (UShockActionSpawnTurret* Turret = Cast<UShockActionSpawnTurret>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("Spawner"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Turret->SpawnerLabel = FName(*Unquote(Text));
					Applied.Add(TEXT("Spawner"));
				}
			}
			if (UShockActionSpawnSecurityBot* Bot = Cast<UShockActionSpawnSecurityBot>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("Spawner"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Bot->SpawnerLabel = FName(*Unquote(Text));
					Applied.Add(TEXT("Spawner"));
				}
				if (Lookup(Classes, ClassName, TEXT("ImmediatelyGiveBotToPawn"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Bot->bImmediatelyGiveBotToPawn = Text.Equals(TEXT("true"), ESearchCase::IgnoreCase);
					Applied.Add(TEXT("ImmediatelyGiveBotToPawn"));
				}
				if (Lookup(Classes, ClassName, TEXT("ReceivingPawnLabel"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Bot->ReceivingPawnLabel = FName(*Unquote(Text));
					Applied.Add(TEXT("ReceivingPawnLabel"));
				}
			}
			if (UShockActionToggleAIWeaponVisibility* Weapon = Cast<UShockActionToggleAIWeaponVisibility>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("AILabel"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Weapon->AILabel = FName(*Unquote(Text));
					Applied.Add(TEXT("AILabel"));
				}
				if (Lookup(Classes, ClassName, TEXT("bShowWeapon"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Weapon->bShowWeapon = Text.Equals(TEXT("true"), ESearchCase::IgnoreCase);
					Applied.Add(TEXT("bShowWeapon"));
				}
			}
			if (UShockActionUnlockBathysphereDestination* Bath = Cast<UShockActionUnlockBathysphereDestination>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("MapName"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Bath->MapName = FName(*Unquote(Text));
					Applied.Add(TEXT("MapName"));
				}
				if (Lookup(Classes, ClassName, TEXT("BathysphereSystem"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Bath->BathysphereSystem = FName(*Unquote(Text));
					Applied.Add(TEXT("BathysphereSystem"));
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
