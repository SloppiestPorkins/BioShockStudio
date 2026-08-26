#include "ShockSchemaLibrary.h"

#include "ShockAction.h"
#include "ShockActionActivateResurrectionStation.h"
#include "ShockActionAISpeech.h"
#include "ShockActionApplyImpulse.h"
#include "ShockActionApplyScriptedHandAttachment.h"
#include "ShockActionAssassinTeleport.h"
#include "ShockActionAssertFact.h"
#include "ShockActionAssignNextGathererBooty.h"
#include "ShockActionTellAIToContinue.h"
#include "ShockActionShowBathysphereUI.h"
#include "ShockActionSetAIState.h"
#include "ShockActionFor.h"
#include "ShockActionDoorKeypadUsed.h"
#include "ShockActionDealDamageInRadius.h"
#include "ShockActionChangeStaticMesh.h"
#include "ShockActionAssignNextSecurityBotSpawnLocation.h"
#include "ShockActionGathererCrawlThroughDoor.h"
#include "ShockActionStopAIHeadTracking.h"
#include "ShockActionForcePlayerMove.h"
#include "ShockActionSpawnPickup.h"
#include "ShockActionChangeLevel.h"
#include "ShockActionChangeResistanceSet.h"
#include "ShockActionToggleSecurityCameraSpotlight.h"
#include "ShockActionDestroyAIs.h"
#include "ShockActionStopTimer.h"
#include "ShockActionEnableOrDisableHudMessages.h"
#include "ShockActionPlayMovie.h"
#include "ShockActionSetAIRangedWeaponAccuracy.h"
#include "ShockActionEnableOrDisableTrainingMessages.h"
#include "ShockActionHackTurret.h"
#include "ShockActionControlPlant.h"
#include "ShockActionSetEffectsSystemContext.h"
#include "ShockActionResetProtectorAttackTargets.h"
#include "ShockActionEnableOrDisableDamageVolume.h"
#include "ShockActionClearAIDamageStates.h"
#include "ShockActionSetCorpseCanBeRemoved.h"
#include "ShockActionUnEquipAllPlasmids.h"
#include "ShockActionStartTimer.h"
#include "ShockActionIncrementNumRosesPlayerPickedUp.h"
#include "ShockActionAttackTarget.h"
#include "ShockActionAwardAchievement.h"
#include "ShockActionBlockingExecuteScript.h"
#include "ShockActionChangeAnimationRate.h"
#include "ShockActionChangeCollision.h"
#include "ShockActionChangePawnPhysics.h"
#include "ShockActionChangePressure.h"
#include "ShockActionChangeQuestArrowActor.h"
#include "ShockActionChangeSkinAtIndex.h"
#include "ShockActionCinematicFadeView.h"
#include "ShockActionClearContainer.h"
#include "ShockActionClearTrainingMessage.h"
#include "ShockActionCloseDoor.h"
#include "ShockActionCompleteQuest.h"
#include "ShockActionCompleteQuestObjective.h"
#include "ShockActionControlScriptedSequence.h"
#include "ShockActionDealDamage.h"
#include "ShockActionDestroyActor.h"
#include "ShockActionDisableOrEnableConcept.h"
#include "ShockActionDisableOrEnableResurrectionStation.h"
#include "ShockActionDisablePlayerMovement.h"
#include "ShockActionDisplayOnScreenDebugMessage.h"
#include "ShockActionEnableOrDisableLevelSaving.h"
#include "ShockActionEnableOrDisableLevelSwitching.h"
#include "ShockActionExecuteScript.h"
#include "ShockActionExitScript.h"
#include "ShockActionFadeVolumeOverride.h"
#include "ShockActionFailQuest.h"
#include "ShockActionFilterItem.h"
#include "ShockActionFreezeHavokActor.h"
#include "ShockActionGiveItemsToPlayer.h"
#include "ShockActionHideOrShowActor.h"
#include "ShockActionInitiateDamage.h"
#include "ShockActionInitiateQuest.h"
#include "ShockActionLockDoor.h"
#include "ShockActionLog.h"
#include "ShockActionLoop.h"
#include "ShockActionMakeBotsAttack.h"
#include "ShockActionManipulateSpawnZoneRepopulation.h"
#include "ShockActionModifyLocomotionKeyword.h"
#include "ShockActionMuteAI.h"
#include "ShockActionNonBlockingExecuteScript.h"
#include "ShockActionOpenDoor.h"
#include "ShockActionPlayAnimation.h"
#include "ShockActionPlayEffect.h"
#include "ShockActionPlayScriptedHandAnimation.h"
#include "ShockActionPlaceItemInContainer.h"
#include "ShockActionPostMovementGoal.h"
#include "ShockActionRemoveGoal.h"
#include "ShockActionRemoveAvailableHoldable.h"
#include "ShockActionRemoveCraftingFormula.h"
#include "ShockActionRemoveItemsFromPlayer.h"
#include "ShockActionRemoveScriptedHandAttachment.h"
#include "ShockActionReplaceQuest.h"
#include "ShockActionRetractFact.h"
#include "ShockActionRunConsoleCommand.h"
#include "ShockActionScriptNote.h"
#include "ShockActionSendTriggerMessage.h"
#include "ShockActionSetActorLabel.h"
#include "ShockActionSetAINormalLODOverrideTime.h"
#include "ShockActionSetAIPatrol.h"
#include "ShockActionSetAIVulnerability.h"
#include "ShockActionSetCollisionAvoidance.h"
#include "ShockActionSetGathererVentPlayerCanSpawn.h"
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
#include "ShockActionSetSpawnerRepopulationState.h"
#include "ShockActionSetTipPriority.h"
#include "ShockActionShockInventory.h"
#include "ShockActionShowTrainingMessage.h"
#include "ShockActionSpawnAI.h"
#include "ShockActionSpawnLinkedGathererAndProtector.h"
#include "ShockActionSpawnPlayerEscortedGatherer.h"
#include "ShockActionSpawnReactiveActor.h"
#include "ShockActionSpawnSecurityBot.h"
#include "ShockActionSpawnTurret.h"
#include "ShockActionStartAIHeadTracking.h"
#include "ShockActionStartScriptedHandAnimationSequence.h"
#include "ShockActionStartSecurityAlarm.h"
#include "ShockActionStopEffect.h"
#include "ShockActionStopScriptedHandAnimationSequence.h"
#include "ShockActionStopSecurityAlarm.h"
#include "ShockActionTeleportPawnToLocation.h"
#include "ShockActionTellAIToSendWeaponFireMessage.h"
#include "ShockActionTellAIToWait.h"
#include "ShockActionToggleAIAttachmentVisibility.h"
#include "ShockActionToggleAIAttacking.h"
#include "ShockActionToggleAIReactions.h"
#include "ShockActionToggleAIWeaponVisibility.h"
#include "ShockActionToggleCeilingCrawlerRangedAttack.h"
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
			if (UShockActionStartAIHeadTracking* Head = Cast<UShockActionStartAIHeadTracking>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("AILabel"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Head->AILabel = FName(*Unquote(Text));
					Applied.Add(TEXT("AILabel"));
				}
				if (Lookup(Classes, ClassName, TEXT("HeadTrackTargetLabel"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Head->HeadTrackTargetLabel = FName(*Unquote(Text));
					Applied.Add(TEXT("HeadTrackTargetLabel"));
				}
				if (Lookup(Classes, ClassName, TEXT("bIsQuickLook"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Head->bIsQuickLook = Text.Equals(TEXT("true"), ESearchCase::IgnoreCase);
					Applied.Add(TEXT("bIsQuickLook"));
				}
				float Duration = 0.0f;
				if (Lookup(Classes, ClassName, TEXT("Duration"), Text) && ParseFloat(Text, Duration))
				{
					Head->Duration = Duration;
					Applied.Add(TEXT("Duration"));
				}
			}
			if (UShockActionSetCollisionAvoidance* Avoid = Cast<UShockActionSetCollisionAvoidance>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("AILabel"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Avoid->AILabel = FName(*Unquote(Text));
					Applied.Add(TEXT("AILabel"));
				}
				if (Lookup(Classes, ClassName, TEXT("bShouldUseCollisionAvoidance"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Avoid->bShouldUseCollisionAvoidance = Text.Equals(TEXT("true"), ESearchCase::IgnoreCase);
					Applied.Add(TEXT("bShouldUseCollisionAvoidance"));
				}
			}
			if (UShockActionEnableOrDisableLevelSwitching* Switch = Cast<UShockActionEnableOrDisableLevelSwitching>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("DisableLevelSwitching"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Switch->bDisableLevelSwitching = Text.Equals(TEXT("true"), ESearchCase::IgnoreCase);
					Applied.Add(TEXT("DisableLevelSwitching"));
				}
			}
			if (UShockActionDisablePlayerMovement* Move = Cast<UShockActionDisablePlayerMovement>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("DisableMovement"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Move->bDisableMovement = Text.Equals(TEXT("true"), ESearchCase::IgnoreCase);
					Applied.Add(TEXT("DisableMovement"));
				}
			}
			if (UShockActionStopSecurityAlarm* Alarm = Cast<UShockActionStopSecurityAlarm>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("bBotsBecomeDormant"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Alarm->bBotsBecomeDormant = Text.Equals(TEXT("true"), ESearchCase::IgnoreCase);
					Applied.Add(TEXT("bBotsBecomeDormant"));
				}
			}
			if (UShockActionFailQuest* Fail = Cast<UShockActionFailQuest>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("QuestName"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Fail->QuestName = FName(*Unquote(Text));
					Applied.Add(TEXT("QuestName"));
				}
				if (Lookup(Classes, ClassName, TEXT("FailQuestMessage"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Fail->FailQuestMessage = Unquote(Text);
					Applied.Add(TEXT("FailQuestMessage"));
				}
			}
			if (UShockActionToggleCeilingCrawlerRangedAttack* Crawler = Cast<UShockActionToggleCeilingCrawlerRangedAttack>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("CeilingCrawlerLabel"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Crawler->CeilingCrawlerLabel = FName(*Unquote(Text));
					Applied.Add(TEXT("CeilingCrawlerLabel"));
				}
				if (Lookup(Classes, ClassName, TEXT("bEnableRangedAttack"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Crawler->bEnableRangedAttack = Text.Equals(TEXT("true"), ESearchCase::IgnoreCase);
					Applied.Add(TEXT("bEnableRangedAttack"));
				}
			}
			if (UShockActionDisableOrEnableResurrectionStation* Station = Cast<UShockActionDisableOrEnableResurrectionStation>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("StationLabel"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Station->StationLabel = FName(*Unquote(Text));
					Applied.Add(TEXT("StationLabel"));
				}
				if (Lookup(Classes, ClassName, TEXT("Enable"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Station->bEnable = Text.Equals(TEXT("true"), ESearchCase::IgnoreCase);
					Applied.Add(TEXT("Enable"));
				}
			}
			if (UShockActionRemoveAvailableHoldable* Holdable = Cast<UShockActionRemoveAvailableHoldable>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("HoldableClass"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Holdable->HoldableClass = FName(*Unquote(Text));
					Applied.Add(TEXT("HoldableClass"));
				}
			}
			if (UShockActionAwardAchievement* Award = Cast<UShockActionAwardAchievement>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("Achievement"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Award->Achievement = FName(*Unquote(Text));
					Applied.Add(TEXT("Achievement"));
				}
			}
			if (UShockActionTellAIToSendWeaponFireMessage* Fire = Cast<UShockActionTellAIToSendWeaponFireMessage>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("AILabel"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Fire->AILabel = FName(*Unquote(Text));
					Applied.Add(TEXT("AILabel"));
				}
				if (Lookup(Classes, ClassName, TEXT("WeaponLabel"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Fire->WeaponLabel = FName(*Unquote(Text));
					Applied.Add(TEXT("WeaponLabel"));
				}
				if (Lookup(Classes, ClassName, TEXT("weaponClass"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Fire->WeaponClass = FName(*Unquote(Text));
					Applied.Add(TEXT("weaponClass"));
				}
			}
			if (UShockActionSetSpawnerRepopulationState* Spawner = Cast<UShockActionSetSpawnerRepopulationState>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("SpawnerLabel"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Spawner->SpawnerLabel = FName(*Unquote(Text));
					Applied.Add(TEXT("SpawnerLabel"));
				}
				if (Lookup(Classes, ClassName, TEXT("Flag"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Spawner->bFlag = Text.Equals(TEXT("true"), ESearchCase::IgnoreCase);
					Applied.Add(TEXT("Flag"));
				}
			}
			if (UShockActionSpawnPlayerEscortedGatherer* Gatherer = Cast<UShockActionSpawnPlayerEscortedGatherer>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("GathererVentLabel"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Gatherer->GathererVentLabel = FName(*Unquote(Text));
					Applied.Add(TEXT("GathererVentLabel"));
				}
				if (Lookup(Classes, ClassName, TEXT("SpawnPositionLabel"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Gatherer->SpawnPositionLabel = FName(*Unquote(Text));
					Applied.Add(TEXT("SpawnPositionLabel"));
				}
				if (Lookup(Classes, ClassName, TEXT("SpawnedGathererLabel"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Gatherer->SpawnedGathererLabel = FName(*Unquote(Text));
					Applied.Add(TEXT("SpawnedGathererLabel"));
				}
				if (Lookup(Classes, ClassName, TEXT("bCorpseCanBeRemoved"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Gatherer->bCorpseCanBeRemoved = Text.Equals(TEXT("true"), ESearchCase::IgnoreCase);
					Applied.Add(TEXT("bCorpseCanBeRemoved"));
				}
				if (Lookup(Classes, ClassName, TEXT("bDontWaitForPlayer"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Gatherer->bDontWaitForPlayer = Text.Equals(TEXT("true"), ESearchCase::IgnoreCase);
					Applied.Add(TEXT("bDontWaitForPlayer"));
				}
				if (Lookup(Classes, ClassName, TEXT("bForceSpawn"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Gatherer->bForceSpawn = Text.Equals(TEXT("true"), ESearchCase::IgnoreCase);
					Applied.Add(TEXT("bForceSpawn"));
				}
				if (Lookup(Classes, ClassName, TEXT("bShouldPlayerEscort"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Gatherer->bShouldPlayerEscort = Text.Equals(TEXT("true"), ESearchCase::IgnoreCase);
					Applied.Add(TEXT("bShouldPlayerEscort"));
				}
				int32 Vuln = 0;
				if (Lookup(Classes, ClassName, TEXT("GathererVulnerableState"), Text) && !Text.StartsWith(TEXT("<")))
				{
					LexFromString(Vuln, *Text);
					Gatherer->GathererVulnerableState = Vuln;
					Applied.Add(TEXT("GathererVulnerableState"));
				}
			}
			if (UShockActionApplyScriptedHandAttachment* Hand = Cast<UShockActionApplyScriptedHandAttachment>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("AttachmentClass"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Hand->AttachmentClass = FName(*Unquote(Text));
					Applied.Add(TEXT("AttachmentClass"));
				}
				if (Lookup(Classes, ClassName, TEXT("AttachmentBone"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Hand->AttachmentBone = FName(*Unquote(Text));
					Applied.Add(TEXT("AttachmentBone"));
				}
			}
			if (UShockActionApplyImpulse* Impulse = Cast<UShockActionApplyImpulse>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("Target"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Impulse->Target = FName(*Unquote(Text));
					Applied.Add(TEXT("Target"));
				}
				if (Lookup(Classes, ClassName, TEXT("BoneName"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Impulse->BoneName = FName(*Unquote(Text));
					Applied.Add(TEXT("BoneName"));
				}
			}
			if (UShockActionSetGathererVentPlayerCanSpawn* Vent = Cast<UShockActionSetGathererVentPlayerCanSpawn>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("GathererVentLabel"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Vent->GathererVentLabel = FName(*Unquote(Text));
					Applied.Add(TEXT("GathererVentLabel"));
				}
				if (Lookup(Classes, ClassName, TEXT("Flag"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Vent->bFlag = Text.Equals(TEXT("true"), ESearchCase::IgnoreCase);
					Applied.Add(TEXT("Flag"));
				}
			}
			if (UShockActionTellAIToWait* WaitAI = Cast<UShockActionTellAIToWait>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("AILabel"), Text) && !Text.StartsWith(TEXT("<")))
				{
					WaitAI->AILabel = FName(*Unquote(Text));
					Applied.Add(TEXT("AILabel"));
				}
			}
			if (UShockActionClearContainer* Clear = Cast<UShockActionClearContainer>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("ContainerLabel"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Clear->ContainerLabel = FName(*Unquote(Text));
					Applied.Add(TEXT("ContainerLabel"));
				}
			}
			if (UShockActionModifyLocomotionKeyword* Loco = Cast<UShockActionModifyLocomotionKeyword>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("AILabel"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Loco->AILabel = FName(*Unquote(Text));
					Applied.Add(TEXT("AILabel"));
				}
				if (Lookup(Classes, ClassName, TEXT("keyword"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Loco->Keyword = FName(*Unquote(Text));
					Applied.Add(TEXT("keyword"));
				}
				int32 Priority = 0;
				if (Lookup(Classes, ClassName, TEXT("KeywordPriority"), Text) && !Text.StartsWith(TEXT("<")))
				{
					LexFromString(Priority, *Text);
					Loco->KeywordPriority = Priority;
					Applied.Add(TEXT("KeywordPriority"));
				}
				if (Lookup(Classes, ClassName, TEXT("bAddKeyword"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Loco->bAddKeyword = Text.Equals(TEXT("true"), ESearchCase::IgnoreCase);
					Applied.Add(TEXT("bAddKeyword"));
				}
			}
			if (UShockActionSpawnLinkedGathererAndProtector* Linked = Cast<UShockActionSpawnLinkedGathererAndProtector>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("ProtectorTypeToSpawn"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Linked->ProtectorTypeToSpawn = FName(*Unquote(Text));
					Applied.Add(TEXT("ProtectorTypeToSpawn"));
				}
				if (Lookup(Classes, ClassName, TEXT("AssociatedGathererVent"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Linked->AssociatedGathererVentLabel = FName(*Unquote(Text));
					Applied.Add(TEXT("AssociatedGathererVent"));
				}
				if (Lookup(Classes, ClassName, TEXT("ProtectorLabel"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Linked->ProtectorLabel = FName(*Unquote(Text));
					Applied.Add(TEXT("ProtectorLabel"));
				}
				if (Lookup(Classes, ClassName, TEXT("GathererLabel"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Linked->GathererLabel = FName(*Unquote(Text));
					Applied.Add(TEXT("GathererLabel"));
				}
				if (Lookup(Classes, ClassName, TEXT("ProtectorSpawnLocationLabel"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Linked->ProtectorSpawnLocationLabel = FName(*Unquote(Text));
					Applied.Add(TEXT("ProtectorSpawnLocationLabel"));
				}
				if (Lookup(Classes, ClassName, TEXT("GathererSpawnLocationLabel"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Linked->GathererSpawnLocationLabel = FName(*Unquote(Text));
					Applied.Add(TEXT("GathererSpawnLocationLabel"));
				}
				if (Lookup(Classes, ClassName, TEXT("bProtectorCorpseCanBeRemoved"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Linked->bProtectorCorpseCanBeRemoved = Text.Equals(TEXT("true"), ESearchCase::IgnoreCase);
					Applied.Add(TEXT("bProtectorCorpseCanBeRemoved"));
				}
				if (Lookup(Classes, ClassName, TEXT("bGathererCorpseCanBeRemoved"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Linked->bGathererCorpseCanBeRemoved = Text.Equals(TEXT("true"), ESearchCase::IgnoreCase);
					Applied.Add(TEXT("bGathererCorpseCanBeRemoved"));
				}
				int32 Vuln = 0;
				if (Lookup(Classes, ClassName, TEXT("GathererVulnerableState"), Text) && !Text.StartsWith(TEXT("<")))
				{
					LexFromString(Vuln, *Text);
					Linked->GathererVulnerableState = Vuln;
					Applied.Add(TEXT("GathererVulnerableState"));
				}
				if (Lookup(Classes, ClassName, TEXT("bForceSpawn"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Linked->bForceSpawn = Text.Equals(TEXT("true"), ESearchCase::IgnoreCase);
					Applied.Add(TEXT("bForceSpawn"));
				}
			}
			if (UShockActionChangeAnimationRate* AnimRate = Cast<UShockActionChangeAnimationRate>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("TargetLabel"), Text) && !Text.StartsWith(TEXT("<")))
				{
					AnimRate->TargetLabel = FName(*Unquote(Text));
					Applied.Add(TEXT("TargetLabel"));
				}
				if (Lookup(Classes, ClassName, TEXT("TargetAnimationName"), Text) && !Text.StartsWith(TEXT("<")))
				{
					AnimRate->TargetAnimationName = FName(*Unquote(Text));
					Applied.Add(TEXT("TargetAnimationName"));
				}
				float Rate = 0.0f;
				if (Lookup(Classes, ClassName, TEXT("TargetAnimationRate"), Text) && ParseFloat(Text, Rate))
				{
					AnimRate->TargetAnimationRate = Rate;
					Applied.Add(TEXT("TargetAnimationRate"));
				}
				float Time = 0.0f;
				if (Lookup(Classes, ClassName, TEXT("RateChangeTime"), Text) && ParseFloat(Text, Time))
				{
					AnimRate->RateChangeTime = Time;
					Applied.Add(TEXT("RateChangeTime"));
				}
			}
			if (UShockActionReplaceQuest* Replace = Cast<UShockActionReplaceQuest>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("QuestName"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Replace->QuestName = FName(*Unquote(Text));
					Applied.Add(TEXT("QuestName"));
				}
				if (Lookup(Classes, ClassName, TEXT("ReplacementQuestName"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Replace->ReplacementQuestName = FName(*Unquote(Text));
					Applied.Add(TEXT("ReplacementQuestName"));
				}
				if (Lookup(Classes, ClassName, TEXT("CopyObjectivesCompleted"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Replace->bCopyObjectivesCompleted = Text.Equals(TEXT("true"), ESearchCase::IgnoreCase);
					Applied.Add(TEXT("CopyObjectivesCompleted"));
				}
				if (Lookup(Classes, ClassName, TEXT("UpdatedMessage"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Replace->UpdatedMessage = Unquote(Text);
					Applied.Add(TEXT("UpdatedMessage"));
				}
			}
			if (UShockActionClearTrainingMessage* ClearTrain = Cast<UShockActionClearTrainingMessage>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("MessageName"), Text) && !Text.StartsWith(TEXT("<")))
				{
					ClearTrain->MessageName = FName(*Unquote(Text));
					Applied.Add(TEXT("MessageName"));
				}
			}
			if (UShockActionRemoveCraftingFormula* Formula = Cast<UShockActionRemoveCraftingFormula>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("FormulaClass"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Formula->FormulaClass = FName(*Unquote(Text));
					Applied.Add(TEXT("FormulaClass"));
				}
			}
			if (UShockActionStartSecurityAlarm* Alarm = Cast<UShockActionStartSecurityAlarm>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("TargetLabel"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Alarm->TargetLabel = FName(*Unquote(Text));
					Applied.Add(TEXT("TargetLabel"));
				}
				if (Lookup(Classes, ClassName, TEXT("SecurityBotClass"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Alarm->SecurityBotClass = FName(*Unquote(Text));
					Applied.Add(TEXT("SecurityBotClass"));
				}
				int32 Num = 0;
				if (Lookup(Classes, ClassName, TEXT("NumSecurityBotsToSpawn"), Text) && !Text.StartsWith(TEXT("<")))
				{
					LexFromString(Num, *Text);
					Alarm->NumSecurityBotsToSpawn = Num;
					Applied.Add(TEXT("NumSecurityBotsToSpawn"));
				}
				if (Lookup(Classes, ClassName, TEXT("bForceNewSecurityTarget"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Alarm->bForceNewSecurityTarget = Text.Equals(TEXT("true"), ESearchCase::IgnoreCase);
					Applied.Add(TEXT("bForceNewSecurityTarget"));
				}
				if (Lookup(Classes, ClassName, TEXT("bInfiniteAlarm"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Alarm->bInfiniteAlarm = Text.Equals(TEXT("true"), ESearchCase::IgnoreCase);
					Applied.Add(TEXT("bInfiniteAlarm"));
				}
			}
			if (UShockActionFilterItem* Filter = Cast<UShockActionFilterItem>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("ItemClass"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Filter->ItemClass = FName(*Unquote(Text));
					Applied.Add(TEXT("ItemClass"));
				}
				if (Lookup(Classes, ClassName, TEXT("UnFilter"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Filter->bUnFilter = Text.Equals(TEXT("true"), ESearchCase::IgnoreCase);
					Applied.Add(TEXT("UnFilter"));
				}
			}
			if (UShockActionMakeBotsAttack* Bots = Cast<UShockActionMakeBotsAttack>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("ControllerLabel"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Bots->ControllerLabel = FName(*Unquote(Text));
					Applied.Add(TEXT("ControllerLabel"));
				}
				if (Lookup(Classes, ClassName, TEXT("AttackeeLabel"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Bots->AttackeeLabel = FName(*Unquote(Text));
					Applied.Add(TEXT("AttackeeLabel"));
				}
			}
			if (UShockActionPlaceItemInContainer* Place = Cast<UShockActionPlaceItemInContainer>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("ContainerLabel"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Place->ContainerLabel = FName(*Unquote(Text));
					Applied.Add(TEXT("ContainerLabel"));
				}
			}
			if (UShockActionAssignNextGathererBooty* Booty = Cast<UShockActionAssignNextGathererBooty>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("NextGathererBooty"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Booty->NextGathererBootyLabel = FName(*Unquote(Text));
					Applied.Add(TEXT("NextGathererBooty"));
				}
				if (Lookup(Classes, ClassName, TEXT("NextGathererBootyLabel"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Booty->NextGathererBootyLabel = FName(*Unquote(Text));
					Applied.Add(TEXT("NextGathererBootyLabel"));
				}
				if (Lookup(Classes, ClassName, TEXT("GathererLabel"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Booty->GathererLabel = FName(*Unquote(Text));
					Applied.Add(TEXT("GathererLabel"));
				}
			}
			if (UShockActionFor* ForLoop = Cast<UShockActionFor>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("counterName"), Text) && !Text.StartsWith(TEXT("<")))
				{
					ForLoop->CounterName = FName(*Unquote(Text));
					Applied.Add(TEXT("counterName"));
				}
				float Begin = 0.0f;
				if (Lookup(Classes, ClassName, TEXT("beginValue"), Text) && ParseFloat(Text, Begin))
				{
					ForLoop->BeginValue = Begin;
					Applied.Add(TEXT("beginValue"));
				}
				float End = 0.0f;
				if (Lookup(Classes, ClassName, TEXT("EndValue"), Text) && ParseFloat(Text, End))
				{
					ForLoop->EndValue = End;
					Applied.Add(TEXT("EndValue"));
				}
				int32 Index = 0;
				if (Lookup(Classes, ClassName, TEXT("CurrentIndex"), Text) && !Text.StartsWith(TEXT("<")))
				{
					LexFromString(Index, *Text);
					ForLoop->CurrentIndex = Index;
					Applied.Add(TEXT("CurrentIndex"));
				}
			}
			if (UShockActionAssignNextSecurityBotSpawnLocation* BotSpawn = Cast<UShockActionAssignNextSecurityBotSpawnLocation>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("SpawnLocationLabel"), Text) && !Text.StartsWith(TEXT("<")))
				{
					BotSpawn->SpawnLocationLabel = FName(*Unquote(Text));
					Applied.Add(TEXT("SpawnLocationLabel"));
				}
			}
			if (UShockActionChangeStaticMesh* Mesh = Cast<UShockActionChangeStaticMesh>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("TargetLabel"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Mesh->TargetLabel = FName(*Unquote(Text));
					Applied.Add(TEXT("TargetLabel"));
				}
				if (Lookup(Classes, ClassName, TEXT("StaticMesh"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Mesh->StaticMeshName = FName(*Unquote(Text));
					Applied.Add(TEXT("StaticMesh"));
				}
			}
			if (UShockActionTellAIToContinue* Cont = Cast<UShockActionTellAIToContinue>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("AILabel"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Cont->AILabel = FName(*Unquote(Text));
					Applied.Add(TEXT("AILabel"));
				}
			}
			if (UShockActionSetAIState* State = Cast<UShockActionSetAIState>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("AILabel"), Text) && !Text.StartsWith(TEXT("<")))
				{
					State->AILabel = FName(*Unquote(Text));
					Applied.Add(TEXT("AILabel"));
				}
				int32 AIState = 0;
				if (Lookup(Classes, ClassName, TEXT("AIState"), Text) && !Text.StartsWith(TEXT("<")))
				{
					LexFromString(AIState, *Text);
					State->AIState = AIState;
					Applied.Add(TEXT("AIState"));
				}
			}
			if (UShockActionDealDamageInRadius* Radius = Cast<UShockActionDealDamageInRadius>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("SourceActorLabel"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Radius->SourceActorLabel = FName(*Unquote(Text));
					Applied.Add(TEXT("SourceActorLabel"));
				}
				float Dmg = 0.0f;
				if (Lookup(Classes, ClassName, TEXT("DamageAmount"), Text) && ParseFloat(Text, Dmg))
				{
					Radius->DamageAmount = Dmg;
					Applied.Add(TEXT("DamageAmount"));
				}
				int32 DType = 0;
				if (Lookup(Classes, ClassName, TEXT("DamageType"), Text) && !Text.StartsWith(TEXT("<")))
				{
					LexFromString(DType, *Text);
					Radius->DamageType = DType;
					Applied.Add(TEXT("DamageType"));
				}
				int32 Inner = 0;
				if (Lookup(Classes, ClassName, TEXT("InnerRadius"), Text) && !Text.StartsWith(TEXT("<")))
				{
					LexFromString(Inner, *Text);
					Radius->InnerRadius = Inner;
					Applied.Add(TEXT("InnerRadius"));
				}
				int32 Outer = 0;
				if (Lookup(Classes, ClassName, TEXT("OuterRadius"), Text) && !Text.StartsWith(TEXT("<")))
				{
					LexFromString(Outer, *Text);
					Radius->OuterRadius = Outer;
					Applied.Add(TEXT("OuterRadius"));
				}
			}
			if (UShockActionShowBathysphereUI* BathUI = Cast<UShockActionShowBathysphereUI>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("BathysphereSystem"), Text) && !Text.StartsWith(TEXT("<")))
				{
					BathUI->BathysphereSystem = FName(*Unquote(Text));
					Applied.Add(TEXT("BathysphereSystem"));
				}
			}
			if (UShockActionDoorKeypadUsed* Keypad = Cast<UShockActionDoorKeypadUsed>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("DoorKeypadControlLabel"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Keypad->DoorKeypadControlLabel = FName(*Unquote(Text));
					Applied.Add(TEXT("DoorKeypadControlLabel"));
				}
				if (Lookup(Classes, ClassName, TEXT("Success"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Keypad->bSuccess = Text.Equals(TEXT("true"), ESearchCase::IgnoreCase);
					Applied.Add(TEXT("Success"));
				}
			}
			if (UShockActionGathererCrawlThroughDoor* Crawl = Cast<UShockActionGathererCrawlThroughDoor>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("Target"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Crawl->Target = FName(*Unquote(Text));
					Applied.Add(TEXT("Target"));
				}
				if (Lookup(Classes, ClassName, TEXT("DoorLabel"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Crawl->DoorLabel = FName(*Unquote(Text));
					Applied.Add(TEXT("DoorLabel"));
				}
				if (Lookup(Classes, ClassName, TEXT("bShouldUnlock"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Crawl->bShouldUnlock = Text.Equals(TEXT("true"), ESearchCase::IgnoreCase);
					Applied.Add(TEXT("bShouldUnlock"));
				}
				if (Lookup(Classes, ClassName, TEXT("bShouldRun"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Crawl->bShouldRun = Text.Equals(TEXT("true"), ESearchCase::IgnoreCase);
					Applied.Add(TEXT("bShouldRun"));
				}
				if (Lookup(Classes, ClassName, TEXT("bShouldBeAggressive"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Crawl->bShouldBeAggressive = Text.Equals(TEXT("true"), ESearchCase::IgnoreCase);
					Applied.Add(TEXT("bShouldBeAggressive"));
				}
			}
			if (UShockActionStopAIHeadTracking* StopHead = Cast<UShockActionStopAIHeadTracking>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("AILabel"), Text) && !Text.StartsWith(TEXT("<")))
				{
					StopHead->AILabel = FName(*Unquote(Text));
					Applied.Add(TEXT("AILabel"));
				}
			}
			if (UShockActionForcePlayerMove* ForceMove = Cast<UShockActionForcePlayerMove>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("MarkerLabel"), Text) && !Text.StartsWith(TEXT("<")))
				{
					ForceMove->MarkerLabel = FName(*Unquote(Text));
					Applied.Add(TEXT("MarkerLabel"));
				}
				if (Lookup(Classes, ClassName, TEXT("MarkerBoneName"), Text) && !Text.StartsWith(TEXT("<")))
				{
					ForceMove->MarkerBoneName = FName(*Unquote(Text));
					Applied.Add(TEXT("MarkerBoneName"));
				}
				float V = 0.0f;
				if (Lookup(Classes, ClassName, TEXT("TimeOut"), Text) && ParseFloat(Text, V))
				{
					ForceMove->TimeOut = V;
					Applied.Add(TEXT("TimeOut"));
				}
				if (Lookup(Classes, ClassName, TEXT("LocationDeltaPerSecond"), Text) && ParseFloat(Text, V))
				{
					ForceMove->LocationDeltaPerSecond = V;
					Applied.Add(TEXT("LocationDeltaPerSecond"));
				}
				if (Lookup(Classes, ClassName, TEXT("RotationDeltaPerSecond"), Text) && ParseFloat(Text, V))
				{
					ForceMove->RotationDeltaPerSecond = V;
					Applied.Add(TEXT("RotationDeltaPerSecond"));
				}
			}
			if (UShockActionSpawnPickup* Pickup = Cast<UShockActionSpawnPickup>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("ActorLabel"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Pickup->ActorLabel = FName(*Unquote(Text));
					Applied.Add(TEXT("ActorLabel"));
				}
				if (Lookup(Classes, ClassName, TEXT("TargetActorLabel"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Pickup->TargetActorLabel = FName(*Unquote(Text));
					Applied.Add(TEXT("TargetActorLabel"));
				}
				if (Lookup(Classes, ClassName, TEXT("PickupClass"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Pickup->PickupClassName = FName(*Unquote(Text));
					Applied.Add(TEXT("PickupClass"));
				}
				if (Lookup(Classes, ClassName, TEXT("ItemClass"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Pickup->ItemClassName = FName(*Unquote(Text));
					Applied.Add(TEXT("ItemClass"));
				}
				int32 Stack = 0;
				if (Lookup(Classes, ClassName, TEXT("StackSize"), Text) && !Text.StartsWith(TEXT("<")))
				{
					LexFromString(Stack, *Text);
					Pickup->StackSize = Stack;
					Applied.Add(TEXT("StackSize"));
				}
				if (Lookup(Classes, ClassName, TEXT("StartsPhysical"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Pickup->bStartsPhysical = Text.Equals(TEXT("true"), ESearchCase::IgnoreCase);
					Applied.Add(TEXT("StartsPhysical"));
				}
			}
			if (UShockActionChangeLevel* Level = Cast<UShockActionChangeLevel>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("MapName"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Level->MapName = Unquote(Text);
					Applied.Add(TEXT("MapName"));
				}
				if (Lookup(Classes, ClassName, TEXT("StartLocationLabel"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Level->StartLocationLabel = Unquote(Text);
					Applied.Add(TEXT("StartLocationLabel"));
				}
				if (Lookup(Classes, ClassName, TEXT("bShowLoadingMessage"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Level->bShowLoadingMessage = Text.Equals(TEXT("true"), ESearchCase::IgnoreCase);
					Applied.Add(TEXT("bShowLoadingMessage"));
				}
				if (Lookup(Classes, ClassName, TEXT("persist"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Level->bPersist = Text.Equals(TEXT("true"), ESearchCase::IgnoreCase);
					Applied.Add(TEXT("persist"));
				}
			}
			if (UShockActionChangeResistanceSet* Resist = Cast<UShockActionChangeResistanceSet>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("Target"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Resist->Target = FName(*Unquote(Text));
					Applied.Add(TEXT("Target"));
				}
				if (Lookup(Classes, ClassName, TEXT("ResistanceSetName"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Resist->ResistanceSetName = FName(*Unquote(Text));
					Applied.Add(TEXT("ResistanceSetName"));
				}
			}
			if (UShockActionToggleSecurityCameraSpotlight* Spot = Cast<UShockActionToggleSecurityCameraSpotlight>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("CameraLabel"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Spot->CameraLabel = FName(*Unquote(Text));
					Applied.Add(TEXT("CameraLabel"));
				}
				if (Lookup(Classes, ClassName, TEXT("SpotlightOn"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Spot->bSpotlightOn = Text.Equals(TEXT("true"), ESearchCase::IgnoreCase);
					Applied.Add(TEXT("SpotlightOn"));
				}
			}
			if (UShockActionDestroyAIs* Destroy = Cast<UShockActionDestroyAIs>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("BaseClass"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Destroy->BaseClassName = FName(*Unquote(Text));
					Applied.Add(TEXT("BaseClass"));
				}
				if (Lookup(Classes, ClassName, TEXT("bOnlyLowDetailAIs"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Destroy->bOnlyLowDetailAIs = Text.Equals(TEXT("true"), ESearchCase::IgnoreCase);
					Applied.Add(TEXT("bOnlyLowDetailAIs"));
				}
			}
			if (UShockActionStopTimer* StopTimer = Cast<UShockActionStopTimer>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("scriptLabel"), Text) && !Text.StartsWith(TEXT("<")))
				{
					StopTimer->ScriptLabel = FName(*Unquote(Text));
					Applied.Add(TEXT("scriptLabel"));
				}
			}
			if (UShockActionEnableOrDisableHudMessages* Hud = Cast<UShockActionEnableOrDisableHudMessages>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("DisableHudMessages"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Hud->bDisableHudMessages = Text.Equals(TEXT("true"), ESearchCase::IgnoreCase);
					Applied.Add(TEXT("DisableHudMessages"));
				}
			}
			if (UShockActionPlayMovie* Movie = Cast<UShockActionPlayMovie>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("MovieName"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Movie->MovieName = FName(*Unquote(Text));
					Applied.Add(TEXT("MovieName"));
				}
			}
			if (UShockActionSetAIRangedWeaponAccuracy* Acc = Cast<UShockActionSetAIRangedWeaponAccuracy>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("RangedWeaponLabel"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Acc->RangedWeaponLabel = FName(*Unquote(Text));
					Applied.Add(TEXT("RangedWeaponLabel"));
				}
			}
			if (UShockActionEnableOrDisableTrainingMessages* Train = Cast<UShockActionEnableOrDisableTrainingMessages>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("EnableTrainingMessages"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Train->bEnableTrainingMessages = Text.Equals(TEXT("true"), ESearchCase::IgnoreCase);
					Applied.Add(TEXT("EnableTrainingMessages"));
				}
			}
			if (UShockActionHackTurret* Hack = Cast<UShockActionHackTurret>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("TurretLabel"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Hack->TurretLabel = FName(*Unquote(Text));
					Applied.Add(TEXT("TurretLabel"));
				}
				if (Lookup(Classes, ClassName, TEXT("SetHacked"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Hack->bSetHacked = Text.Equals(TEXT("true"), ESearchCase::IgnoreCase);
					Applied.Add(TEXT("SetHacked"));
				}
			}
			if (UShockActionControlPlant* Plant = Cast<UShockActionControlPlant>(Action))
			{
				FString Text;
				float Dur = 0.0f;
				if (Lookup(Classes, ClassName, TEXT("Duration"), Text) && ParseFloat(Text, Dur))
				{
					Plant->Duration = Dur;
					Applied.Add(TEXT("Duration"));
				}
				if (Lookup(Classes, ClassName, TEXT("bRevive"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Plant->bRevive = Text.Equals(TEXT("true"), ESearchCase::IgnoreCase);
					Applied.Add(TEXT("bRevive"));
				}
			}
			if (UShockActionSetEffectsSystemContext* FxCtx = Cast<UShockActionSetEffectsSystemContext>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("Context"), Text) && !Text.StartsWith(TEXT("<")))
				{
					FxCtx->Context = FName(*Unquote(Text));
					Applied.Add(TEXT("Context"));
				}
				int32 Target = 0;
				if (Lookup(Classes, ClassName, TEXT("ContextAppliesTo"), Text) && !Text.StartsWith(TEXT("<")))
				{
					LexFromString(Target, *Text);
					FxCtx->ContextAppliesTo = static_cast<uint8>(FMath::Clamp(Target, 0, 255));
					Applied.Add(TEXT("ContextAppliesTo"));
				}
				if (Lookup(Classes, ClassName, TEXT("RemoveInsteadOfAdd"), Text) && !Text.StartsWith(TEXT("<")))
				{
					FxCtx->bRemoveInsteadOfAdd = Text.Equals(TEXT("true"), ESearchCase::IgnoreCase);
					Applied.Add(TEXT("RemoveInsteadOfAdd"));
				}
				if (Lookup(Classes, ClassName, TEXT("LogTriggerInfo"), Text) && !Text.StartsWith(TEXT("<")))
				{
					FxCtx->bLogTriggerInfo = Text.Equals(TEXT("true"), ESearchCase::IgnoreCase);
					Applied.Add(TEXT("LogTriggerInfo"));
				}
			}
			if (UShockActionResetProtectorAttackTargets* Protector = Cast<UShockActionResetProtectorAttackTargets>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("ProtectorLabel"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Protector->ProtectorLabel = FName(*Unquote(Text));
					Applied.Add(TEXT("ProtectorLabel"));
				}
			}
			if (UShockActionEnableOrDisableDamageVolume* DmgVol = Cast<UShockActionEnableOrDisableDamageVolume>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("VolumeLabel"), Text) && !Text.StartsWith(TEXT("<")))
				{
					DmgVol->VolumeLabel = FName(*Unquote(Text));
					Applied.Add(TEXT("VolumeLabel"));
				}
				if (Lookup(Classes, ClassName, TEXT("EnableVolume"), Text) && !Text.StartsWith(TEXT("<")))
				{
					DmgVol->bEnableVolume = Text.Equals(TEXT("true"), ESearchCase::IgnoreCase);
					Applied.Add(TEXT("EnableVolume"));
				}
			}
			if (UShockActionClearAIDamageStates* ClearDmg = Cast<UShockActionClearAIDamageStates>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("AILabel"), Text) && !Text.StartsWith(TEXT("<")))
				{
					ClearDmg->AILabel = FName(*Unquote(Text));
					Applied.Add(TEXT("AILabel"));
				}
			}
			if (UShockActionSetCorpseCanBeRemoved* Corpse = Cast<UShockActionSetCorpseCanBeRemoved>(Action))
			{
				FString Text;
				if (Lookup(Classes, ClassName, TEXT("CorpseLabel"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Corpse->CorpseLabel = FName(*Unquote(Text));
					Applied.Add(TEXT("CorpseLabel"));
				}
				if (Lookup(Classes, ClassName, TEXT("bCorpseCanBeRemoved"), Text) && !Text.StartsWith(TEXT("<")))
				{
					Corpse->bCorpseCanBeRemoved = Text.Equals(TEXT("true"), ESearchCase::IgnoreCase);
					Applied.Add(TEXT("bCorpseCanBeRemoved"));
				}
			}
			if (UShockActionStartTimer* StartTimer = Cast<UShockActionStartTimer>(Action))
			{
				FString Text;
				float Sec = 0.0f;
				if (Lookup(Classes, ClassName, TEXT("Seconds"), Text) && ParseFloat(Text, Sec))
				{
					StartTimer->Seconds = Sec;
					Applied.Add(TEXT("Seconds"));
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
