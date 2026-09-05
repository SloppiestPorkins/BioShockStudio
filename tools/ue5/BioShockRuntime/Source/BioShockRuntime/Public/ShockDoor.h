#pragma once

#include "GameFramework/Actor.h"
#include "ShockDoor.generated.h"

class UBoxComponent;
class UStaticMeshComponent;
class UWorld;

/**
 * Interactive door for the playable slice.
 *
 * Source data (docs/research/interaction.md, CONFIRMED_BYTES): doors carry bLocked,
 * bInitiallyOpen, OpenAnimationName / OpenAnimationRate, Attachments[], DoorPortal, etc.
 * Shipped MedicalDoors drive a skeletal animation proxy (Med_DoorAnim) with static-mesh
 * leaves on sockets — that anim path is not wired here yet.
 *
 * This actor approximates plain doors as: proximity (or script Open/Close) → yaw swing →
 * collision off when open. Locked / broken state is respected; keypad doors and dual-leaf
 * skeletal open are documented follow-ups.
 */
UCLASS()
class BIOSHOCKRUNTIME_API AShockDoor : public AActor
{
	GENERATED_BODY()

public:
	AShockDoor();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "BioShock|Door")
	FName DoorLabel;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|Door")
	bool bLocked = false;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|Door")
	bool bBroken = false;

	/** When true, proximity open leaves the door open until script/CloseDoor. */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|Door")
	bool bStayOpen = false;

	/** APPROXIMATED — source uses OpenAnimationName skeletal clips, not a yaw swing. */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|Door")
	float OpenYawDegrees = 90.0f;

	/** APPROXIMATED — OpenAnimationRate exists in source but is not mapped yet. */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|Door")
	float OpenDuration = 0.75f;

	/** APPROXIMATED — interact range; source DoorSwitch UseVerbText / Use path not wired. */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|Door")
	float ProximityRadius = 180.0f;

	UFUNCTION(BlueprintCallable, Category = "BioShock|Door")
	void SetDoorLabel(FName Label) { DoorLabel = Label; }

	UFUNCTION(BlueprintCallable, Category = "BioShock|Door")
	void SetLocked(bool bInLocked);

	UFUNCTION(BlueprintCallable, Category = "BioShock|Door")
	void SetBroken(bool bInBroken);

	UFUNCTION(BlueprintPure, Category = "BioShock|Door")
	bool IsLocked() const { return bLocked; }

	UFUNCTION(BlueprintPure, Category = "BioShock|Door")
	bool IsBroken() const { return bBroken; }

	UFUNCTION(BlueprintPure, Category = "BioShock|Door")
	bool IsOpen() const { return bOpen; }

	UFUNCTION(BlueprintPure, Category = "BioShock|Door")
	bool IsFullyOpen() const { return bOpen && OpenAlpha >= 1.0f; }

	UFUNCTION(BlueprintPure, Category = "BioShock|Door")
	bool IsFullyClosed() const { return !bOpen && OpenAlpha <= 0.0f; }

	/** Script / interact: begin opening. Fails when locked or broken. */
	UFUNCTION(BlueprintCallable, Category = "BioShock|Door")
	bool OpenDoor(bool bInStayOpen = false);

	/** Script / interact: begin closing. Force ignores StayOpen hold. */
	UFUNCTION(BlueprintCallable, Category = "BioShock|Door")
	bool CloseDoor(bool bForce = false);

	UFUNCTION(BlueprintCallable, Category = "BioShock|Door")
	bool ToggleDoor();

	/** Headless: set label + locked + initially-open without playing a swing. */
	UFUNCTION(BlueprintCallable, Category = "BioShock|Door")
	void ConfigureForVerify(FName Label, bool bInLocked = false, bool bInitiallyOpen = false);

	UFUNCTION(BlueprintCallable, Category = "BioShock|Door")
	bool OpenForVerify();

	UFUNCTION(BlueprintCallable, Category = "BioShock|Door")
	bool CloseForVerify();

	UFUNCTION(BlueprintCallable, Category = "BioShock|Door")
	void AdvanceDoorForVerify(float DeltaSeconds);

	UFUNCTION(BlueprintPure, Category = "BioShock|Door")
	bool IsBlockingCollisionEnabled() const;

	UFUNCTION(BlueprintPure, Category = "BioShock|Door")
	uint8 GetCollisionEnabledForVerify() const;

	static AShockDoor* FindByLabel(UWorld* World, FName Label);

protected:
	virtual void BeginPlay() override;
	virtual void Tick(float DeltaSeconds) override;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "BioShock|Door")
	TObjectPtr<UStaticMeshComponent> DoorMesh;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "BioShock|Door")
	TObjectPtr<UBoxComponent> ProximityTrigger;

private:
	void ApplyVisualAndCollision(float Alpha);
	void UpdateProximityAutoClose(float DeltaSeconds);

	UFUNCTION()
	void OnProximityBeginOverlap(
		UPrimitiveComponent* OverlappedComponent,
		AActor* OtherActor,
		UPrimitiveComponent* OtherComp,
		int32 OtherBodyIndex,
		bool bFromSweep,
		const FHitResult& SweepResult);

	UFUNCTION()
	void OnProximityEndOverlap(
		UPrimitiveComponent* OverlappedComponent,
		AActor* OtherActor,
		UPrimitiveComponent* OtherComp,
		int32 OtherBodyIndex);

	FRotator ClosedRelativeRotation;
	bool bOpen = false;
	float OpenAlpha = 0.0f;
	float AutoCloseRemaining = -1.0f;
	int32 OverlappingPlayers = 0;
};
