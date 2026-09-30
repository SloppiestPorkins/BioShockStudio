#pragma once

#include "GameFramework/Actor.h"
#include "ShockDoorKeypadControl.generated.h"

class UStaticMeshComponent;
class USkeletalMeshComponent;
class UStaticMesh;
class USkeletalMesh;
class AShockPlayer;

/**
 * BioShock's `DoorKeypadControl`: a keypad the player uses (Press F) to unlock a specific labeled
 * door and fire whatever script chain is waiting on the keypad's own label. Never had a dedicated
 * actor class wired (`import_level.py`'s fallback), so Medical's one instance
 * ("TwilightFieldsKeypad", unlocking "MorgueClosetDoor") imported as an inert `TargetPoint` --
 * and the Script that gates on it (`TwilightFieldsKeypadScript`, `TriggeredBy=TwilightFieldsKeypad`,
 * `scriptMessageClass=MessageDoorKeypadUsed`) could never fire from the player's own action.
 *
 * Deliberately does NOT implement a real code-entry minigame: no numeric-keypad UI exists in this
 * project, and the original UE2 level data doesn't carry a decoded keycode anywhere available to
 * this pipeline. `ShockActionDoorKeypadUsed::ApplyInWorld` already documents this same limitation
 * for the *script's own* action ("no DoorKeypad / keypad-control actor class exists ... Success
 * cannot be delivered to a control. Record the request only.") -- this class doesn't change that,
 * it solves the concrete, load-bearing half of the problem instead: unlocking the actual door the
 * keypad controls, which does not depend on that action ever being fixed, and dispatching
 * `MessageDoorKeypadUsed` via the same `UShockScriptSubsystem::DispatchDoorKeypadUsed` path used
 * elsewhere so the associated Script's own action list (VO, quest state, ...) still runs exactly
 * as authored.
 */
UCLASS()
class BIOSHOCKRUNTIME_API AShockDoorKeypadControl : public AActor
{
	GENERATED_BODY()

public:
	AShockDoorKeypadControl();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	TObjectPtr<UStaticMeshComponent> Mesh;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	TObjectPtr<USkeletalMeshComponent> SkeletalMeshComp;

	/** The message-source label the Script's TriggeredBy matches against (e.g.
	 * "TwilightFieldsKeypad"), passed to DispatchDoorKeypadUsed as the keypad label. */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category="BioShock|DoorKeypadControl")
	FName KeypadLabel;

	/** AShockDoor::DoorLabel this keypad unlocks (the manifest's own interaction.doorLabel). */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category="BioShock|DoorKeypadControl")
	FName DoorLabel;

	/** Informational only -- no hacking minigame exists in this project; interact always
	 * succeeds regardless of this flag. */
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category="BioShock|DoorKeypadControl")
	bool bHackable = false;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="BioShock|DoorKeypadControl")
	bool bOneShot = true;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock|DoorKeypadControl")
	bool bHasFired = false;

	UFUNCTION(BlueprintCallable, Category="BioShock|DoorKeypadControl")
	void Configure(FName InKeypadLabel, FName InDoorLabel, bool bInHackable);

	UFUNCTION(BlueprintPure, Category="BioShock|DoorKeypadControl")
	FString GetInteractionPrompt() const { return TEXT("Press F to use"); }

	UFUNCTION(BlueprintPure, Category="BioShock|DoorKeypadControl")
	bool CanInteract() const { return !bOneShot || !bHasFired; }

	/** Unlocks DoorLabel's AShockDoor (if found) and dispatches MessageDoorKeypadUsed via
	 * DispatchDoorKeypadUsed(KeypadLabel, ""). Returns false (no-op, not a failure) when bOneShot
	 * and already fired. */
	UFUNCTION(BlueprintCallable, Category="BioShock|DoorKeypadControl")
	bool TryInteract(AShockPlayer* Player);

	UFUNCTION(BlueprintCallable, Category="BioShock|DoorKeypadControl")
	void SetKeypadStaticMesh(UStaticMesh* InMesh);

	UFUNCTION(BlueprintCallable, Category="BioShock|DoorKeypadControl")
	void SetKeypadSkeletalMesh(USkeletalMesh* InMesh);
};
