#pragma once

#include "GameFramework/Actor.h"
#include "ShockStationTypes.h"
#include "ShockStationActor.generated.h"

class AShockDoor;
class AShockPlayer;
class UBoxComponent;
class UShockStationMenu;
class UStaticMeshComponent;

/**
 * Interactable station: opens the matching UShockStationMenu on TryInteract.
 * Slice spawn (bEnableSliceStations) places one of each kind near the player.
 */
UCLASS()
class BIOSHOCKRUNTIME_API AShockStationBase : public AActor
{
	GENERATED_BODY()

public:
	AShockStationBase();

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|Station")
	EShockStationKind StationKind = EShockStationKind::Vending;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|Station")
	FName StationLabel;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|Station")
	float InteractRadius = 200.0f;

	/** Vending stock (Circus / El Ammo). Ignored for other kinds. */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|Station|Vend")
	TArray<FShockVendItem> VendItems;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|Station|Vend")
	bool bHacked = false;

	/** Combo lock expected 3-digit code (0–999). */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|Station|Combo")
	int32 Code = 123;

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|Station|Combo")
	FName LinkedDoorLabel;

	UFUNCTION(BlueprintCallable, Category = "BioShock|Station")
	void ConfigureVendingDefaults(bool bAmmoBandito = false);

	UFUNCTION(BlueprintCallable, Category = "BioShock|Station")
	void SetHacked(bool bInHacked);

	UFUNCTION(BlueprintCallable, Category = "BioShock|Station")
	bool TryInteract(AShockPlayer* Player);

	UFUNCTION(BlueprintCallable, Category = "BioShock|Station")
	void CloseMenu();

	/** Soft clear when the menu closes itself (Esc) — does not re-enter CloseStationMenu. */
	void NotifyMenuClosed(UShockStationMenu* Menu);

	UFUNCTION(BlueprintPure, Category = "BioShock|Station")
	UShockStationMenu* GetOpenMenu() const { return OpenMenu; }

	UFUNCTION(BlueprintCallable, Category = "BioShock|Station")
	AShockDoor* ResolveLinkedDoor() const;

	UFUNCTION(BlueprintCallable, Category = "BioShock|Station")
	TArray<FShockVendItem>& GetVendItemsMutable() { return VendItems; }

	const TArray<FShockVendItem>& GetVendItems() const { return VendItems; }

protected:
	virtual void BeginPlay() override;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "BioShock|Station")
	TObjectPtr<UStaticMeshComponent> Mesh;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "BioShock|Station")
	TObjectPtr<UBoxComponent> InteractTrigger;

	UPROPERTY(Transient)
	TObjectPtr<UShockStationMenu> OpenMenu;

	UShockStationMenu* CreateMenuForKind(APlayerController* PC) const;
};
