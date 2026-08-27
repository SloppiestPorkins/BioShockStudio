"""One-shot generator for Phase 4 census tail actions (batch40-44)."""
from __future__ import annotations

import os
from textwrap import dedent

ROOT = r"C:\Users\Jack\Documents\BioshockHavok\tools\ue5\BioShockRuntime\Source\BioShockRuntime"
TOOLS = r"C:\Users\Jack\Documents\BioshockHavok\tools\ue5"

ACTIONS = [
    # batch40
    dict(
        cls="ShockActionSetPlayerFOV", uc="ActionSetPlayerFOV", pkg="shockgame",
        header=dedent(
            """
            /** UnrealScript `ActionSetPlayerFOV`. Records desired FOV; no camera yet. */
            UCLASS(BlueprintType)
            class BIOSHOCKRUNTIME_API UShockActionSetPlayerFOV : public UShockAction
            {
            \tGENERATED_BODY()
            public:
            \tUShockActionSetPlayerFOV();
            \tUPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
            \tfloat FOV = 0.f;
            \tUPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
            \tfloat LastFOV = 0.f;
            \tUFUNCTION(BlueprintCallable, Category="BioShock|Action")
            \tvoid Configure(float InFOV);
            \tUFUNCTION(BlueprintCallable, Category="BioShock|Action")
            \tfloat GetFOV() const { return FOV; }
            \tUFUNCTION(BlueprintCallable, Category="BioShock|Action")
            \tbool RequestSet();
            };
            """
        ),
        cpp=dedent(
            """
            UShockActionSetPlayerFOV::UShockActionSetPlayerFOV()
            {
            \tActionClassName = TEXT("ActionSetPlayerFOV");
            }
            void UShockActionSetPlayerFOV::Configure(float InFOV)
            {
            \tFOV = InFOV;
            }
            bool UShockActionSetPlayerFOV::RequestSet()
            {
            \tLastFOV = FOV;
            \treturn true;
            }
            """
        ),
        schema=[
            ('FOV', 'float', 'FOV'),
        ],
        verify='a.configure(90.f)\n    if not a.request_set() or abs(float(a.get_fov()) - 90.0) > 0.01:\n        f.append("FOV")',
    ),
    dict(
        cls="ShockActionTrainingCondition", uc="TrainingCondition", pkg="shockgame",
        header=dedent(
            """
            /** UnrealScript `TrainingCondition`. Nested tests/actions deferred; params only. */
            UCLASS(BlueprintType)
            class BIOSHOCKRUNTIME_API UShockActionTrainingCondition : public UShockAction
            {
            \tGENERATED_BODY()
            public:
            \tUShockActionTrainingCondition();
            \tUPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
            \tfloat Weight = 0.f;
            \tUPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
            \tint32 TickDelay = 10;
            \tUPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
            \tint32 Priority = 0;
            \tUPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
            \tFName ConceptName;
            \tUPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
            \tbool bConditionRequested = false;
            \tUFUNCTION(BlueprintCallable, Category="BioShock|Action")
            \tvoid Configure(float InWeight, int32 InTickDelay, int32 InPriority, FName InConcept);
            \tUFUNCTION(BlueprintCallable, Category="BioShock|Action")
            \tint32 GetTickDelay() const { return TickDelay; }
            \tUFUNCTION(BlueprintCallable, Category="BioShock|Action")
            \tbool RequestEvaluate();
            };
            """
        ),
        cpp=dedent(
            """
            UShockActionTrainingCondition::UShockActionTrainingCondition()
            {
            \tActionClassName = TEXT("TrainingCondition");
            \tTickDelay = 10;
            }
            void UShockActionTrainingCondition::Configure(float InWeight, int32 InTickDelay, int32 InPriority, FName InConcept)
            {
            \tWeight = InWeight;
            \tTickDelay = InTickDelay;
            \tPriority = InPriority;
            \tConceptName = InConcept;
            }
            bool UShockActionTrainingCondition::RequestEvaluate()
            {
            \tbConditionRequested = true;
            \treturn !ConceptName.IsNone();
            }
            """
        ),
        schema=[
            ('Weight', 'float', 'Weight'),
            ('TickDelay', 'int', 'TickDelay'),
            ('Priority', 'int', 'Priority'),
            ('Concept', 'name', 'ConceptName'),
        ],
        verify='apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(a, shockgame, "TrainingCondition"))\n    if not apply.get("ok") or int(a.get_tick_delay()) != 10:\n        f.append("Training defaults")\n    a.configure(1.5, 5, 2, "Concept_A")\n    if not a.request_evaluate():\n        f.append("Training")',
    ),
    dict(
        cls="ShockActionSetGrenadierSuicideState", uc="ActionSetGrenadierSuicideState", pkg="shockai",
        header=dedent(
            """
            /** UnrealScript `ActionSetGrenadierSuicideState`. Records grenadier + suicide enum. */
            UCLASS(BlueprintType)
            class BIOSHOCKRUNTIME_API UShockActionSetGrenadierSuicideState : public UShockAction
            {
            \tGENERATED_BODY()
            public:
            \tUShockActionSetGrenadierSuicideState();
            \tUPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
            \tFName GrenadierLabel;
            \tUPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
            \tint32 SpecialCommitSuicideState = 0;
            \tUPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
            \tFName LastGrenadierLabel;
            \tUFUNCTION(BlueprintCallable, Category="BioShock|Action")
            \tvoid Configure(FName InLabel, int32 InState);
            \tUFUNCTION(BlueprintCallable, Category="BioShock|Action")
            \tbool RequestSet();
            };
            """
        ),
        cpp=dedent(
            """
            UShockActionSetGrenadierSuicideState::UShockActionSetGrenadierSuicideState()
            {
            \tActionClassName = TEXT("ActionSetGrenadierSuicideState");
            }
            void UShockActionSetGrenadierSuicideState::Configure(FName InLabel, int32 InState)
            {
            \tGrenadierLabel = InLabel;
            \tSpecialCommitSuicideState = InState;
            }
            bool UShockActionSetGrenadierSuicideState::RequestSet()
            {
            \tif (GrenadierLabel.IsNone()) return false;
            \tLastGrenadierLabel = GrenadierLabel;
            \treturn true;
            }
            """
        ),
        schema=[
            ('GrenadierLabel', 'name', 'GrenadierLabel'),
            ('SpecialCommitSuicideState', 'int', 'SpecialCommitSuicideState'),
        ],
        verify='a.configure("Grenadier_A", 1)\n    if not a.request_set():\n        f.append("Grenadier")',
    ),
    dict(
        cls="ShockActionUnHackSecuritySystem", uc="ActionUnHackSecuritySystem", pkg="shockai",
        header=dedent(
            """
            /** UnrealScript `ActionUnHackSecuritySystem`. Records un-hack request; no security mgr yet. */
            UCLASS(BlueprintType)
            class BIOSHOCKRUNTIME_API UShockActionUnHackSecuritySystem : public UShockAction
            {
            \tGENERATED_BODY()
            public:
            \tUShockActionUnHackSecuritySystem();
            \tUPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
            \tbool bUnHackRequested = false;
            \tUFUNCTION(BlueprintCallable, Category="BioShock|Action")
            \tbool RequestUnHack();
            };
            """
        ),
        cpp=dedent(
            """
            UShockActionUnHackSecuritySystem::UShockActionUnHackSecuritySystem()
            {
            \tActionClassName = TEXT("ActionUnHackSecuritySystem");
            }
            bool UShockActionUnHackSecuritySystem::RequestUnHack()
            {
            \tbUnHackRequested = true;
            \treturn true;
            }
            """
        ),
        schema=[],
        verify='if not a.request_un_hack():\n        f.append("UnHack")',
    ),
    # batch41
    dict(
        cls="ShockActionKeypadContainerUsed", uc="ActionKeypadContainerUsed", pkg="shockgame",
        header=dedent(
            """
            UCLASS(BlueprintType)
            class BIOSHOCKRUNTIME_API UShockActionKeypadContainerUsed : public UShockAction
            {
            \tGENERATED_BODY()
            public:
            \tUShockActionKeypadContainerUsed();
            \tUPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
            \tFName KeypadContainerLabel;
            \tUPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
            \tbool bSuccess = false;
            \tUFUNCTION(BlueprintCallable, Category="BioShock|Action")
            \tvoid Configure(FName InLabel, bool bInSuccess);
            \tUFUNCTION(BlueprintCallable, Category="BioShock|Action")
            \tbool RequestNotify();
            };
            """
        ),
        cpp=dedent(
            """
            UShockActionKeypadContainerUsed::UShockActionKeypadContainerUsed()
            {
            \tActionClassName = TEXT("ActionKeypadContainerUsed");
            }
            void UShockActionKeypadContainerUsed::Configure(FName InLabel, bool bInSuccess)
            {
            \tKeypadContainerLabel = InLabel;
            \tbSuccess = bInSuccess;
            }
            bool UShockActionKeypadContainerUsed::RequestNotify()
            {
            \tif (KeypadContainerLabel.IsNone()) return false;
            \treturn true;
            }
            """
        ),
        schema=[
            ('KeypadContainerLabel', 'name', 'KeypadContainerLabel'),
            ('Success', 'bool', 'bSuccess'),
        ],
        verify='a.configure("Keypad_A", True)\n    if not a.request_notify():\n        f.append("Keypad")',
    ),
    dict(
        cls="ShockActionHackSecuritySystem", uc="ActionHackSecuritySystem", pkg="shockai",
        header=dedent(
            """
            UCLASS(BlueprintType)
            class BIOSHOCKRUNTIME_API UShockActionHackSecuritySystem : public UShockAction
            {
            \tGENERATED_BODY()
            public:
            \tUShockActionHackSecuritySystem();
            \tUPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
            \tfloat ShutdownTime = 30.f;
            \tUFUNCTION(BlueprintCallable, Category="BioShock|Action")
            \tvoid Configure(float InSeconds);
            \tUFUNCTION(BlueprintCallable, Category="BioShock|Action")
            \tfloat GetShutdownTime() const { return ShutdownTime; }
            \tUFUNCTION(BlueprintCallable, Category="BioShock|Action")
            \tbool RequestHack();
            };
            """
        ),
        cpp=dedent(
            """
            UShockActionHackSecuritySystem::UShockActionHackSecuritySystem()
            {
            \tActionClassName = TEXT("ActionHackSecuritySystem");
            \tShutdownTime = 30.f;
            }
            void UShockActionHackSecuritySystem::Configure(float InSeconds)
            {
            \tShutdownTime = InSeconds;
            }
            bool UShockActionHackSecuritySystem::RequestHack()
            {
            \treturn ShutdownTime > 0.f;
            }
            """
        ),
        schema=[('ShutdownTime', 'float', 'ShutdownTime')],
        verify='apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(a, shockai, "ActionHackSecuritySystem"))\n    if not apply.get("ok") or abs(float(a.get_shutdown_time()) - 30.0) > 0.01:\n        f.append("HackSec defaults")\n    a.configure(45.f)\n    if not a.request_hack():\n        f.append("HackSec")',
    ),
    dict(
        cls="ShockActionAssignNextProtectorVent", uc="ActionAssignNextProtectorVent", pkg="shockai",
        header=dedent(
            """
            UCLASS(BlueprintType)
            class BIOSHOCKRUNTIME_API UShockActionAssignNextProtectorVent : public UShockAction
            {
            \tGENERATED_BODY()
            public:
            \tUShockActionAssignNextProtectorVent();
            \tUPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
            \tFName NextProtectorVentName;
            \tUPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
            \tFName ProtectorLabel;
            \tUFUNCTION(BlueprintCallable, Category="BioShock|Action")
            \tvoid Configure(FName InVent, FName InProtector);
            \tUFUNCTION(BlueprintCallable, Category="BioShock|Action")
            \tbool RequestAssign();
            };
            """
        ),
        cpp=dedent(
            """
            UShockActionAssignNextProtectorVent::UShockActionAssignNextProtectorVent()
            {
            \tActionClassName = TEXT("ActionAssignNextProtectorVent");
            }
            void UShockActionAssignNextProtectorVent::Configure(FName InVent, FName InProtector)
            {
            \tNextProtectorVentName = InVent;
            \tProtectorLabel = InProtector;
            }
            bool UShockActionAssignNextProtectorVent::RequestAssign()
            {
            \tif (NextProtectorVentName.IsNone() || ProtectorLabel.IsNone()) return false;
            \treturn true;
            }
            """
        ),
        schema=[
            ('NextProtectorVent', 'name', 'NextProtectorVentName'),
            ('ProtectorLabel', 'name', 'ProtectorLabel'),
        ],
        verify='a.configure("Vent_A", "Protector_A")\n    if not a.request_assign():\n        f.append("ProtVent")',
    ),
    dict(
        cls="ShockActionEnableOrDisableSoundPropagation", uc="ActionEnableOrDisableSoundPropagation", pkg="shockgame",
        header=dedent(
            """
            UCLASS(BlueprintType)
            class BIOSHOCKRUNTIME_API UShockActionEnableOrDisableSoundPropagation : public UShockAction
            {
            \tGENERATED_BODY()
            public:
            \tUShockActionEnableOrDisableSoundPropagation();
            \tUPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
            \tbool bEnable = true;
            \tUFUNCTION(BlueprintCallable, Category="BioShock|Action")
            \tvoid Configure(bool bInEnable);
            \tUFUNCTION(BlueprintCallable, Category="BioShock|Action")
            \tbool RequestSet();
            };
            """
        ),
        cpp=dedent(
            """
            UShockActionEnableOrDisableSoundPropagation::UShockActionEnableOrDisableSoundPropagation()
            {
            \tActionClassName = TEXT("ActionEnableOrDisableSoundPropagation");
            }
            void UShockActionEnableOrDisableSoundPropagation::Configure(bool bInEnable)
            {
            \tbEnable = bInEnable;
            }
            bool UShockActionEnableOrDisableSoundPropagation::RequestSet()
            {
            \treturn true;
            }
            """
        ),
        schema=[('Enable', 'bool', 'bEnable')],
        verify='a.configure(False)\n    if not a.request_set() or bool(a.get_editor_property("b_enable")):\n        f.append("SoundProp")',
    ),
    # batch42
    dict(
        cls="ShockActionAutoSave", uc="ActionAutoSave", pkg="shockgame",
        header=dedent(
            """
            UCLASS(BlueprintType)
            class BIOSHOCKRUNTIME_API UShockActionAutoSave : public UShockAction
            {
            \tGENERATED_BODY()
            public:
            \tUShockActionAutoSave();
            \tUPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
            \tFString Command = TEXT("savegame autosave");
            \tUFUNCTION(BlueprintCallable, Category="BioShock|Action")
            \tvoid Configure(const FString& InCommand);
            \tUFUNCTION(BlueprintCallable, Category="BioShock|Action")
            \tFString GetCommand() const { return Command; }
            \tUFUNCTION(BlueprintCallable, Category="BioShock|Action")
            \tbool RequestSave();
            };
            """
        ),
        cpp=dedent(
            """
            UShockActionAutoSave::UShockActionAutoSave()
            {
            \tActionClassName = TEXT("ActionAutoSave");
            \tCommand = TEXT("savegame autosave");
            }
            void UShockActionAutoSave::Configure(const FString& InCommand)
            {
            \tCommand = InCommand;
            }
            bool UShockActionAutoSave::RequestSave()
            {
            \treturn !Command.IsEmpty();
            }
            """
        ),
        schema=[('Command', 'string', 'Command')],
        verify='apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(a, shockgame, "ActionAutoSave"))\n    if not apply.get("ok") or "autosave" not in str(a.get_command()):\n        f.append("AutoSave defaults")\n    if not a.request_save():\n        f.append("AutoSave")',
    ),
    dict(
        cls="ShockActionSetCorpseFadeoutTime", uc="ActionSetCorpseFadeoutTime", pkg="shockai",
        header=dedent(
            """
            UCLASS(BlueprintType)
            class BIOSHOCKRUNTIME_API UShockActionSetCorpseFadeoutTime : public UShockAction
            {
            \tGENERATED_BODY()
            public:
            \tUShockActionSetCorpseFadeoutTime();
            \tUPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
            \tFName AILabel;
            \tUPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
            \tfloat FadeOutDuration = 3.f;
            \tUFUNCTION(BlueprintCallable, Category="BioShock|Action")
            \tvoid Configure(FName InLabel, float InDuration);
            \tUFUNCTION(BlueprintCallable, Category="BioShock|Action")
            \tfloat GetFadeOutDuration() const { return FadeOutDuration; }
            \tUFUNCTION(BlueprintCallable, Category="BioShock|Action")
            \tbool RequestFade();
            };
            """
        ),
        cpp=dedent(
            """
            UShockActionSetCorpseFadeoutTime::UShockActionSetCorpseFadeoutTime()
            {
            \tActionClassName = TEXT("ActionSetCorpseFadeoutTime");
            \tFadeOutDuration = 3.f;
            }
            void UShockActionSetCorpseFadeoutTime::Configure(FName InLabel, float InDuration)
            {
            \tAILabel = InLabel;
            \tFadeOutDuration = InDuration;
            }
            bool UShockActionSetCorpseFadeoutTime::RequestFade()
            {
            \tif (AILabel.IsNone()) return false;
            \treturn FadeOutDuration >= 0.f;
            }
            """
        ),
        schema=[
            ('AILabel', 'name', 'AILabel'),
            ('FadeOutDuration', 'float', 'FadeOutDuration'),
        ],
        verify='apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(a, shockai, "ActionSetCorpseFadeoutTime"))\n    if not apply.get("ok") or abs(float(a.get_fade_out_duration()) - 3.0) > 0.01:\n        f.append("CorpseFade defaults")\n    a.configure("Thug_A", 5.f)\n    if not a.request_fade():\n        f.append("CorpseFade")',
    ),
    dict(
        cls="ShockActionPrintClientMessage", uc="ActionPrintClientMessage", pkg="scripting",
        header=dedent(
            """
            UCLASS(BlueprintType)
            class BIOSHOCKRUNTIME_API UShockActionPrintClientMessage : public UShockAction
            {
            \tGENERATED_BODY()
            public:
            \tUShockActionPrintClientMessage();
            \tUPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
            \tFString MessageText;
            \tUPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
            \tFName MessageType;
            \tUFUNCTION(BlueprintCallable, Category="BioShock|Action")
            \tvoid Configure(const FString& InText, FName InType);
            \tUFUNCTION(BlueprintCallable, Category="BioShock|Action")
            \tbool RequestPrint();
            };
            """
        ),
        cpp=dedent(
            """
            UShockActionPrintClientMessage::UShockActionPrintClientMessage()
            {
            \tActionClassName = TEXT("ActionPrintClientMessage");
            }
            void UShockActionPrintClientMessage::Configure(const FString& InText, FName InType)
            {
            \tMessageText = InText;
            \tMessageType = InType;
            }
            bool UShockActionPrintClientMessage::RequestPrint()
            {
            \treturn !MessageText.IsEmpty();
            }
            """
        ),
        schema=[
            ('MessageText', 'string', 'MessageText'),
            ('MessageType', 'name', 'MessageType'),
        ],
        verify='a.configure("Hello", "Event")\n    if not a.request_print():\n        f.append("PrintMsg")',
    ),
    dict(
        cls="ShockActionToggleQuestVisibility", uc="ActionToggleQuestVisibility", pkg="shockgame",
        header=dedent(
            """
            UCLASS(BlueprintType)
            class BIOSHOCKRUNTIME_API UShockActionToggleQuestVisibility : public UShockAction
            {
            \tGENERATED_BODY()
            public:
            \tUShockActionToggleQuestVisibility();
            \tUPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
            \tFName QuestName;
            \tUPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
            \tFName LastQuestName;
            \tUFUNCTION(BlueprintCallable, Category="BioShock|Action")
            \tvoid Configure(FName InQuest);
            \tUFUNCTION(BlueprintCallable, Category="BioShock|Action")
            \tbool RequestToggle();
            };
            """
        ),
        cpp=dedent(
            """
            UShockActionToggleQuestVisibility::UShockActionToggleQuestVisibility()
            {
            \tActionClassName = TEXT("ActionToggleQuestVisibility");
            }
            void UShockActionToggleQuestVisibility::Configure(FName InQuest)
            {
            \tQuestName = InQuest;
            }
            bool UShockActionToggleQuestVisibility::RequestToggle()
            {
            \tif (QuestName.IsNone()) return false;
            \tLastQuestName = QuestName;
            \treturn true;
            }
            """
        ),
        schema=[('QuestName', 'name', 'QuestName')],
        verify='a.configure("Quest_A")\n    if not a.request_toggle():\n        f.append("ToggleQuest")',
    ),
    # batch43
    dict(
        cls="ShockActionDisableOrEnableMachine", uc="ActionDisableOrEnableMachine", pkg="shockgame",
        header=dedent(
            """
            UCLASS(BlueprintType)
            class BIOSHOCKRUNTIME_API UShockActionDisableOrEnableMachine : public UShockAction
            {
            \tGENERATED_BODY()
            public:
            \tUShockActionDisableOrEnableMachine();
            \tUPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
            \tFName MachineLabel;
            \tUPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
            \tFName MachineClassName;
            \tUPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
            \tbool bEnable = true;
            \tUFUNCTION(BlueprintCallable, Category="BioShock|Action")
            \tvoid Configure(FName InLabel, FName InClass, bool bInEnable);
            \tUFUNCTION(BlueprintCallable, Category="BioShock|Action")
            \tbool RequestSet();
            };
            """
        ),
        cpp=dedent(
            """
            UShockActionDisableOrEnableMachine::UShockActionDisableOrEnableMachine()
            {
            \tActionClassName = TEXT("ActionDisableOrEnableMachine");
            }
            void UShockActionDisableOrEnableMachine::Configure(FName InLabel, FName InClass, bool bInEnable)
            {
            \tMachineLabel = InLabel;
            \tMachineClassName = InClass;
            \tbEnable = bInEnable;
            }
            bool UShockActionDisableOrEnableMachine::RequestSet()
            {
            \treturn true;
            }
            """
        ),
        schema=[
            ('MachineLabel', 'name', 'MachineLabel'),
            ('MachineClass', 'name', 'MachineClassName'),
            ('Enable', 'bool', 'bEnable'),
        ],
        verify='a.configure("Machine_A", "ShockMachine", False)\n    if not a.request_set():\n        f.append("Machine")',
    ),
    dict(
        cls="ShockActionPlaceItemInContainerSlot", uc="ActionPlaceItemInContainerSlot", pkg="shockgame",
        base="ShockActionShockInventory",
        header=dedent(
            """
            UCLASS(BlueprintType)
            class BIOSHOCKRUNTIME_API UShockActionPlaceItemInContainerSlot : public UShockActionShockInventory
            {
            \tGENERATED_BODY()
            public:
            \tUShockActionPlaceItemInContainerSlot();
            \tUPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
            \tFName ContainerLabel;
            \tUPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
            \tint32 Slot = 0;
            \tUPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
            \tbool bOverwriteExistingItem = false;
            \tUFUNCTION(BlueprintCallable, Category="BioShock|Action")
            \tvoid ConfigureSlot(FName InContainer, int32 InSlot, bool bInOverwrite);
            \tUFUNCTION(BlueprintCallable, Category="BioShock|Action")
            \tbool RequestPlace();
            };
            """
        ),
        cpp=dedent(
            """
            UShockActionPlaceItemInContainerSlot::UShockActionPlaceItemInContainerSlot()
            {
            \tActionClassName = TEXT("ActionPlaceItemInContainerSlot");
            }
            void UShockActionPlaceItemInContainerSlot::ConfigureSlot(FName InContainer, int32 InSlot, bool bInOverwrite)
            {
            \tContainerLabel = InContainer;
            \tSlot = InSlot;
            \tbOverwriteExistingItem = bInOverwrite;
            }
            bool UShockActionPlaceItemInContainerSlot::RequestPlace()
            {
            \tif (ContainerLabel.IsNone() || ItemClass.IsNone() || StackSize <= 0) return false;
            \treturn Slot >= 0;
            }
            """
        ),
        schema=[
            ('ContainerLabel', 'name', 'ContainerLabel'),
            ('Slot', 'int', 'Slot'),
            ('OverwriteExistingItem', 'bool', 'bOverwriteExistingItem'),
            ('ItemClass', 'name', 'ItemClass'),
            ('StackSize', 'int', 'StackSize'),
        ],
        verify='a.configure_inventory("MedKit", 2)\n    a.configure_slot("Chest_A", 1, True)\n    if not a.request_place():\n        f.append("PlaceSlot")',
    ),
    dict(
        cls="ShockActionSetBouncerCanStepBack", uc="ActionSetBouncerCanStepBack", pkg="shockai",
        header=dedent(
            """
            UCLASS(BlueprintType)
            class BIOSHOCKRUNTIME_API UShockActionSetBouncerCanStepBack : public UShockAction
            {
            \tGENERATED_BODY()
            public:
            \tUShockActionSetBouncerCanStepBack();
            \tUPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
            \tFName BouncerLabel;
            \tUPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
            \tbool bCanStepBack = true;
            \tUFUNCTION(BlueprintCallable, Category="BioShock|Action")
            \tvoid Configure(FName InLabel, bool bInCanStepBack);
            \tUFUNCTION(BlueprintCallable, Category="BioShock|Action")
            \tbool RequestSet();
            };
            """
        ),
        cpp=dedent(
            """
            UShockActionSetBouncerCanStepBack::UShockActionSetBouncerCanStepBack()
            {
            \tActionClassName = TEXT("ActionSetBouncerCanStepBack");
            }
            void UShockActionSetBouncerCanStepBack::Configure(FName InLabel, bool bInCanStepBack)
            {
            \tBouncerLabel = InLabel;
            \tbCanStepBack = bInCanStepBack;
            }
            bool UShockActionSetBouncerCanStepBack::RequestSet()
            {
            \tif (BouncerLabel.IsNone()) return false;
            \treturn true;
            }
            """
        ),
        schema=[
            ('BouncerLabel', 'name', 'BouncerLabel'),
            ('bCanStepBack', 'bool', 'bCanStepBack'),
        ],
        verify='a.configure("Bouncer_A", False)\n    if not a.request_set():\n        f.append("Bouncer")',
    ),
    dict(
        cls="ShockActionEquipPlasmid", uc="ActionEquipPlasmid", pkg="shockgame",
        header=dedent(
            """
            UCLASS(BlueprintType)
            class BIOSHOCKRUNTIME_API UShockActionEquipPlasmid : public UShockAction
            {
            \tGENERATED_BODY()
            public:
            \tUShockActionEquipPlasmid();
            \tUPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
            \tFName Plasmid;
            \tUPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
            \tint32 SlotNumber = 0;
            \tUFUNCTION(BlueprintCallable, Category="BioShock|Action")
            \tvoid Configure(FName InPlasmid, int32 InSlot);
            \tUFUNCTION(BlueprintCallable, Category="BioShock|Action")
            \tbool RequestEquip();
            };
            """
        ),
        cpp=dedent(
            """
            UShockActionEquipPlasmid::UShockActionEquipPlasmid()
            {
            \tActionClassName = TEXT("ActionEquipPlasmid");
            }
            void UShockActionEquipPlasmid::Configure(FName InPlasmid, int32 InSlot)
            {
            \tPlasmid = InPlasmid;
            \tSlotNumber = InSlot;
            }
            bool UShockActionEquipPlasmid::RequestEquip()
            {
            \tif (Plasmid.IsNone()) return false;
            \treturn true;
            }
            """
        ),
        schema=[
            ('Plasmid', 'name', 'Plasmid'),
            ('slotNumber', 'int', 'SlotNumber'),
        ],
        verify='a.configure("Incinerate", 1)\n    if not a.request_equip():\n        f.append("EquipPlasmid")',
    ),
    # batch44
    dict(
        cls="ShockActionSetPlasmidSlotLockedState", uc="ActionSetPlasmidSlotLockedState", pkg="shockgame",
        header=dedent(
            """
            UCLASS(BlueprintType)
            class BIOSHOCKRUNTIME_API UShockActionSetPlasmidSlotLockedState : public UShockAction
            {
            \tGENERATED_BODY()
            public:
            \tUShockActionSetPlasmidSlotLockedState();
            \tUPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
            \tint32 Track = 0;
            \tUPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
            \tbool bLock = true;
            \tUFUNCTION(BlueprintCallable, Category="BioShock|Action")
            \tvoid Configure(int32 InTrack, bool bInLock);
            \tUFUNCTION(BlueprintCallable, Category="BioShock|Action")
            \tbool RequestSet();
            };
            """
        ),
        cpp=dedent(
            """
            UShockActionSetPlasmidSlotLockedState::UShockActionSetPlasmidSlotLockedState()
            {
            \tActionClassName = TEXT("ActionSetPlasmidSlotLockedState");
            }
            void UShockActionSetPlasmidSlotLockedState::Configure(int32 InTrack, bool bInLock)
            {
            \tTrack = InTrack;
            \tbLock = bInLock;
            }
            bool UShockActionSetPlasmidSlotLockedState::RequestSet()
            {
            \treturn true;
            }
            """
        ),
        schema=[
            ('Track', 'int', 'Track'),
            ('Lock', 'bool', 'bLock'),
        ],
        verify='a.configure(1, True)\n    if not a.request_set():\n        f.append("PlasmidLock")',
    ),
]

BATCHES = {
    40: ACTIONS[0:4],
    41: ACTIONS[4:8],
    42: ACTIONS[8:12],
    43: ACTIONS[12:16],
    44: ACTIONS[16:17],
}


def write_file(path: str, content: str) -> None:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write(content.rstrip() + "\n")


def gen_header(a: dict) -> str:
    base = a.get("base", "ShockAction")
    inc = f'#include "{base}.h"'
    return (
        "#pragma once\n\n"
        f"{inc}\n"
        f'#include "{a["cls"]}.generated.h"\n\n'
        + a["header"].strip()
        + "\n"
    )


def gen_cpp(a: dict) -> str:
    return f'#include "{a["cls"]}.h"\n\n' + a["cpp"].strip() + "\n"


def schema_block(a: dict) -> str:
    if not a["schema"]:
        return ""
    var = a["cls"].replace("ShockAction", "")
    if var.startswith("Training"):
        cast = "Training"
    else:
        cast = var
    lines = [f"\t\t\tif (U{a['cls']}* {cast} = Cast<U{a['cls']}>(Action))", "\t\t\t{", "\t\t\t\tFString Text;"]
    for field, kind, prop in a["schema"]:
        if kind == "float":
            lines.append(f'\t\t\t\tfloat Val = 0.f;\n\t\t\t\tif (Lookup(Classes, ClassName, TEXT("{field}"), Text) && ParseFloat(Text, Val))\n\t\t\t\t{{\n\t\t\t\t\t{cast}->{prop} = Val;\n\t\t\t\t\tApplied.Add(TEXT("{field}"));\n\t\t\t\t}}')
        elif kind == "int":
            lines.append(f'\t\t\t\tint32 Val = 0;\n\t\t\t\tif (Lookup(Classes, ClassName, TEXT("{field}"), Text) && !Text.StartsWith(TEXT("<")))\n\t\t\t\t{{\n\t\t\t\t\tLexFromString(Val, *Text);\n\t\t\t\t\t{cast}->{prop} = Val;\n\t\t\t\t\tApplied.Add(TEXT("{field}"));\n\t\t\t\t}}')
        elif kind == "bool":
            lines.append(f'\t\t\t\tif (Lookup(Classes, ClassName, TEXT("{field}"), Text) && !Text.StartsWith(TEXT("<")))\n\t\t\t\t{{\n\t\t\t\t\t{cast}->{prop} = Text.Equals(TEXT("true"), ESearchCase::IgnoreCase);\n\t\t\t\t\tApplied.Add(TEXT("{field}"));\n\t\t\t\t}}')
        elif kind == "string":
            lines.append(f'\t\t\t\tif (Lookup(Classes, ClassName, TEXT("{field}"), Text) && !Text.StartsWith(TEXT("<")))\n\t\t\t\t{{\n\t\t\t\t\t{cast}->{prop} = Unquote(Text);\n\t\t\t\t\tApplied.Add(TEXT("{field}"));\n\t\t\t\t}}')
        elif kind == "name":
            lines.append(f'\t\t\t\tif (Lookup(Classes, ClassName, TEXT("{field}"), Text) && !Text.StartsWith(TEXT("<")))\n\t\t\t\t{{\n\t\t\t\t\t{cast}->{prop} = FName(*Unquote(Text));\n\t\t\t\t\tApplied.Add(TEXT("{field}"));\n\t\t\t\t}}')
    lines.append("\t\t\t}")
    return "\n".join(lines)


def main() -> None:
    includes = []
    schema_blocks = []
    for a in ACTIONS:
        cls = a["cls"]
        includes.append(f'#include "{cls}.h"')
        write_file(os.path.join(ROOT, "Public", f"{cls}.h"), gen_header(a))
        write_file(os.path.join(ROOT, "Private", f"{cls}.cpp"), gen_cpp(a))
        block = schema_block(a)
        if block:
            schema_blocks.append(block)

    for batch, items in BATCHES.items():
        doc = ", ".join(x["uc"] for x in items)
        verify_path = os.path.join(TOOLS, f"verify_action_batch{batch}.py")
        run_path = os.path.join(TOOLS, f"run_action_batch{batch}.py")

        env_lines = []
        main_args = []
        for a in items:
            pkg = a["pkg"]
            if pkg == "shockgame" and "shockgame" not in env_lines:
                env_lines.append("shockgame")
            if pkg == "shockai" and "shockai" not in env_lines:
                env_lines.append("shockai")
            if pkg == "scripting" and "scripting" not in env_lines:
                env_lines.append("scripting")

        sig = ", ".join(["out"] + env_lines)
        body = [
            '"""Batch%d: %s."""' % (batch, doc),
            "",
            "import json",
            "import os",
            "",
            "import unreal",
            "",
            "",
            "def _log(m):",
            '    unreal.log("[bioshock-action-batch%d] %%s" %% m)' % batch,
            "",
            "",
            f"def main({sig}):",
            '    report = {"failures": []}',
            "    f = report[\"failures\"]",
            "",
        ]
        for a in items:
            uc = a["uc"]
            cls = a["cls"]
            schema_arg = {
                "shockgame": "shockgame",
                "shockai": "shockai",
                "scripting": "scripting",
            }[a["pkg"]]
            body += [
                f'    cls = unreal.load_class(None, "/Script/BioShockRuntime.{cls}")',
                "    a = unreal.new_object(cls)",
                f'    apply = json.loads(unreal.ShockSchemaLibrary.apply_action_defaults(a, {schema_arg}, "{uc}"))',
                '    if not apply.get("ok"):',
                f'        f.append("{uc} defaults")',
                "    " + a["verify"].replace("\n", "\n    "),
                f'    report["{a["uc"].lower()}"] = "ok"',
                "",
            ]
        body += [
            "    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)",
            '    with open(out, "w", encoding="utf-8") as handle:',
            "        json.dump(report, handle, indent=2)",
            "    if f:",
            f'        raise RuntimeError("batch{batch}:\\n- " + "\\n- ".join(f))',
            f'    _log("PASS batch{batch}")',
            "    return report",
            "",
            "",
            'if __name__ == "__main__":',
            "    main(",
        ]
        call = ['        os.environ["BIOSHOCK_ACTION_OUT"],']
        for e in env_lines:
            key = e.upper()
            default = {
                "shockgame": r"C:\Users\Jack\Documents\BioShockUE5\Exports\slice\ShockGame.schema.json",
                "shockai": r"C:\Users\Jack\Documents\BioShockUE5\Exports\slice\ShockAI.schema.json",
                "scripting": r"C:\Users\Jack\Documents\BioShockUE5\Exports\slice\Scripting.schema.json",
            }[e]
            call.append(f'        os.environ.get("BIOSHOCK_{key}_SCHEMA", r"{default}"),')
        body.append("\n".join(call))
        body.append("    )")
        write_file(verify_path, "\n".join(body))

        run_body = [
            "import json, os, sys, traceback",
            f'sys.path.append(r"{TOOLS}")',
            'OUT = os.environ.get("BIOSHOCK_ACTION_OUT", r"C:\\Users\\Jack\\Documents\\BioShockUE5\\Exports\\slice\\action_batch%d_report.json")' % batch,
            "try:",
            f"    import verify_action_batch{batch}",
            f"    verify_action_batch{batch}.main(",
        ]
        run_body.append('        os.environ.get("BIOSHOCK_ACTION_OUT", OUT),')
        for e in env_lines:
            key = e.upper()
            default = {
                "shockgame": r"C:\Users\Jack\Documents\BioShockUE5\Exports\slice\ShockGame.schema.json",
                "shockai": r"C:\Users\Jack\Documents\BioShockUE5\Exports\slice\ShockAI.schema.json",
                "scripting": r"C:\Users\Jack\Documents\BioShockUE5\Exports\slice\Scripting.schema.json",
            }[e]
            run_body.append(f'        os.environ.get("BIOSHOCK_{key}_SCHEMA", r"{default}"),')
        run_body += [
            "    )",
            "except Exception as e:",
            '    open(OUT, "w", encoding="utf-8").write(json.dumps({"error": str(e), "traceback": traceback.format_exc()}, indent=2))',
            "    raise",
        ]
        write_file(run_path, "\n".join(run_body))

    patch_path = os.path.join(ROOT, "Private", "_schema_tail_patch.txt")
    write_file(
        patch_path,
        "// INCLUDES\n" + "\n".join(includes) + "\n\n// BLOCKS\n" + "\n".join(schema_blocks),
    )
    print(f"Generated {len(ACTIONS)} actions, batches 40-44, patch at {patch_path}")


if __name__ == "__main__":
    main()
