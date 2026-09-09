#pragma once

#include "GameFramework/Actor.h"
#include "ShockConsumablePickup.generated.h"

class USphereComponent;
class AShockPlayer;

class UStaticMeshComponent;
class UShockPlasmid;

UENUM(BlueprintType)
enum class EShockPickupKind : uint8
{
	FirstAidKit UMETA(DisplayName="First Aid Kit"),
	EveHypo UMETA(DisplayName="EVE Hypo"),
	Money UMETA(DisplayName="Money"),
	Ammo UMETA(DisplayName="Ammo"),
	Adam UMETA(DisplayName="ADAM"),
	Item UMETA(DisplayName="Inventory Item"),
	Weapon UMETA(DisplayName="Weapon"),
	Plasmid UMETA(DisplayName="Plasmid"),
	Diary UMETA(DisplayName="Audio Diary"),
};

/** World pickup for first-aid kits, EVE hypos, money, and ammo reserve grants. */
UCLASS()
class BIOSHOCKRUNTIME_API AShockConsumablePickup : public AActor
{
	GENERATED_BODY()

public:
	AShockConsumablePickup();

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	TObjectPtr<USphereComponent> Collision;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="BioShock")
	TObjectPtr<UStaticMeshComponent> Mesh;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="BioShock|Pickup")
	EShockPickupKind PickupKind = EShockPickupKind::FirstAidKit;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="BioShock|Pickup")
	int32 Amount = 1;

	/** When PickupKind is Ammo/Weapon, the weapon def name to grant or top up. */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="BioShock|Pickup")
	FName WeaponDefName;

	/** PickupKind Item: inventory item class (AutoHackDevice, PowerBar, food/drink names). */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="BioShock|Pickup")
	FName ItemClass;

	/** PickupKind Plasmid: the plasmid name resolved through UShockPlasmid::ResolvePlasmidClass. */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="BioShock|Pickup")
	FName PlasmidName;

	/** PickupKind Diary: the audio-diary id recorded as collected. */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="BioShock|Pickup")
	FName DiaryId;

	/** BioShock auto-collects ammo/health/money; weapons, plasmids, diaries and keys are a
	 *  keypress. When true this pickup ignores overlap and waits for Interact. */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="BioShock|Pickup")
	bool bRequiresInteract = false;

	/** Interact / overlap entry point — grants the effect and removes the pickup. */
	UFUNCTION(BlueprintCallable, Category="BioShock|Pickup")
	bool TryCollect(AShockPlayer* Player);

	UFUNCTION(BlueprintPure, Category="BioShock|Pickup")
	bool RequiresInteract() const { return bRequiresInteract; }

	/** "pick up the shotgun", "take the plasmid", "read the audio diary" — for the HUD prompt. */
	UFUNCTION(BlueprintPure, Category="BioShock|Pickup")
	FString GetInteractPrompt() const;

	/** Headless verify: apply pickup effect without overlap geometry. */
	UFUNCTION(BlueprintCallable, Category="BioShock|Pickup")
	bool PickupForVerify(AShockPlayer* Player);

	UFUNCTION(BlueprintCallable, Category="BioShock|Pickup")
	void ConfigureForVerify(uint8 Kind, int32 InAmount, FName InWeaponDefName = NAME_None);

	UFUNCTION(BlueprintCallable, Category="BioShock|Pickup")
	void ConfigurePickup(
		uint8 Kind,
		int32 InAmount,
		FName InWeaponDefName,
		FName InItemClass,
		FName InPlasmidName,
		FName InDiaryId,
		bool bInRequiresInteract);

	UFUNCTION(BlueprintCallable, Category="BioShock|Pickup")
	void SetPickupMesh(UStaticMesh* InMesh);

private:
	bool ApplyPickup(AShockPlayer* Player);
	void DestroyAfterPickup();

	/** True while showing the small stand-in marker (no real mesh imported yet). */
	bool bUsingMarkerMesh = false;

	UFUNCTION()
	void OnOverlap(
		UPrimitiveComponent* OverlappedComponent,
		AActor* OtherActor,
		UPrimitiveComponent* OtherComp,
		int32 OtherBodyIndex,
		bool bFromSweep,
		const FHitResult& SweepResult);
};
