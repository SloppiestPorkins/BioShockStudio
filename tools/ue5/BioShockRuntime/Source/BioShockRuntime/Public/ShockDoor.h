#pragma once

#include "GameFramework/Actor.h"
#include "ShockDoor.generated.h"

class UBoxComponent;
class UAnimSequence;
class USceneComponent;
class USkeletalMesh;
class USkeletalMeshComponent;
class UStaticMeshComponent;
class UStaticMesh;
class UWorld;

/**
 * Interactive door for the playable slice.
 *
 * Source data (docs/research/interaction.md, CONFIRMED_BYTES): doors carry bLocked,
 * bInitiallyOpen, OpenAnimationName / OpenAnimationRate, Attachments[], DoorPortal, etc.
 * Shipped MedicalDoors drive an animation-proxy skeleton with rigid static-mesh leaves
 * attached to its sockets. LoadRoomDoor is the other real source shape: a skinned,
 * rigid-weighted door mesh. This actor supports both and keeps collision on a separate
 * blocker because the source physics asset is not part of the visual FBX import.
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

	/** Used only when a source rig/clip is unavailable; LoadRoomDoor_OPEN moves ~199 uu in local Y. */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|Door")
	FVector SlideOffset = FVector(0.0f, 199.0f, 0.0f);

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|Door")
	float OpenDuration = 0.75f;

	/** APPROXIMATED — interact range; source DoorSwitch UseVerbText / Use path not wired. */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|Door")
	float ProximityRadius = 180.0f;

	/**
	 * When false, proximity overlap does not open the door — script OpenDoor / PlayAnimation only.
	 * Used to prove the scripted path in headless verifies; leave true for playable slice.
	 */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|Door")
	bool bEnableProximityOpen = true;

	UFUNCTION(BlueprintCallable, Category = "BioShock|Door")
	void SetDoorLabel(FName Label) { DoorLabel = Label; }

	UFUNCTION(BlueprintCallable, Category = "BioShock|Door")
	void SetEnableProximityOpen(bool bEnable) { bEnableProximityOpen = bEnable; }

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

	/** Use a visible skinned mesh (LoadRoomDoor) or an invisible socket proxy (MedicalDoors). */
	UFUNCTION(BlueprintCallable, Category = "BioShock|Door")
	void ConfigureSkeletalDoor(USkeletalMesh* Mesh, bool bVisibleMesh);

	/** Add one source Attachments[] static leaf to the proxy skeleton. */
	UFUNCTION(BlueprintCallable, Category = "BioShock|Door")
	bool AddDoorLeaf(
		UStaticMesh* Mesh,
		FName Socket,
		FVector RelativeLocation,
		FRotator RelativeRotation,
		bool bPhysical);

	UFUNCTION(BlueprintCallable, Category = "BioShock|Door")
	void ClearDoorLeaves();

	/** Starts the named source clip; falls back to the measured local-Y slide when unavailable. */
	UFUNCTION(BlueprintCallable, Category = "BioShock|Door")
	bool PlayDoorAnimation(FName AnimationName, float PlaybackRate = 1.0f, bool bLoop = false);

	UFUNCTION(BlueprintPure, Category = "BioShock|Door")
	bool IsDoorAnimationComplete(FName AnimationName) const;

	UFUNCTION(BlueprintPure, Category = "BioShock|Door")
	FName GetPlayingDoorAnimationForVerify() const;

	/** Headless: set label + locked + initially-open without playing an animation. */
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
	TObjectPtr<USceneComponent> DoorRoot;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "BioShock|Door")
	TObjectPtr<UStaticMeshComponent> DoorMesh;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "BioShock|Door")
	TObjectPtr<USkeletalMeshComponent> DoorSkeleton;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "BioShock|Door")
	TObjectPtr<UBoxComponent> DoorBlocker;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "BioShock|Door")
	TObjectPtr<UBoxComponent> ProximityTrigger;

private:
	void ApplyVisualAndCollision(float Alpha);
	void UpdateProximityAutoClose(float DeltaSeconds);
	UAnimSequence* LoadDoorAnimation(FName AnimationName) const;

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

	UPROPERTY()
	TArray<TObjectPtr<UStaticMeshComponent>> DoorLeaves;

	UPROPERTY(Transient)
	TObjectPtr<UAnimSequence> PlayingDoorAnimation;

	FVector ClosedRelativeLocation = FVector::ZeroVector;
	bool bOpen = false;
	bool bSkeletalVisual = false;
	float OpenAlpha = 0.0f;
	float AutoCloseRemaining = -1.0f;
	int32 OverlappingPlayers = 0;
};
