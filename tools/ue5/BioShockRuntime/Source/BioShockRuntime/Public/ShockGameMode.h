#pragma once

#include "GameFramework/GameModeBase.h"
#include "TimerManager.h"
#include "ShockStationTypes.h"
#include "ShockGameMode.generated.h"

class ABaseShockAI;
class AShockPlayer;
class AShockWeapon;
class UShockDeathRespawnHandler;
class UShockHudWidget;
class UShockPauseMenu;
class UShockRadialMenu;
class UShockStationMenu;
class UShockStatusMenu;
class UShockWeaponSelectScreen;
class UShockVendingMenu;
class UShockGeneBankMenu;
class UShockUInventMenu;
class UShockGathererGardenMenu;
class UShockComboLockMenu;
class UShockHackingMinigame;
class AShockSecurityDevice;

UCLASS()
class BIOSHOCKRUNTIME_API AShockGameMode : public AGameModeBase
{
	GENERATED_BODY()

public:
	AShockGameMode();

	virtual void PostLogin(APlayerController* NewPlayer) override;

	virtual APawn* SpawnDefaultPawnAtTransform_Implementation(
		AController* NewPlayer,
		const FTransform& SpawnTransform) override;

	virtual AActor* ChoosePlayerStart_Implementation(AController* Player) override;

	/** Vita-Chamber-style in-place reset after death (default). */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="BioShock|Death")
	float RespawnDelaySeconds = 3.0f;

	/** When true, reload the current map instead of in-place reset. */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="BioShock|Death")
	bool bReloadLevelOnDeath = false;

	/** Off by default so possess / encounter verifies stay unchanged. */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="BioShock|Slice")
	bool bEnableSliceTurret = false;

	/** Off by default — optional security camera + alarm-response bot near the encounter. */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="BioShock|Slice")
	bool bEnableSliceSecurity = false;

	/** Off by default — optional FirstAidKit world pickup near the encounter. */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="BioShock|Slice")
	bool bEnableSlicePickup = false;

	/** Off by default — spawn one of each U5 station (vend/gene/invent/garden/combo) near start. */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="BioShock|Slice")
	bool bEnableSliceStations = false;

	UFUNCTION(BlueprintCallable, Category="BioShock|Death")
	void BindPlayerDeathHandling(AShockPlayer* Player, AActor* RespawnStart);

	UFUNCTION(BlueprintPure, Category="BioShock|Death")
	bool IsRespawnPending() const;

	/** Headless verify: advance the respawn timer without waiting for real time. */
	UFUNCTION(BlueprintCallable, Category="BioShock|Death")
	void AdvanceRespawnForVerify(float DeltaSeconds);

	/** Headless verify: kick UNavigationSystemV1::Build on the editor world. */
	UFUNCTION(BlueprintCallable, Category="BioShock|Nav", meta=(WorldContext="WorldContextObject"))
	static bool BuildNavigationForVerify(UObject* WorldContextObject);

	/** Headless verify: true when ProjectPointToNavigation succeeds for Point. */
	UFUNCTION(BlueprintCallable, Category="BioShock|Nav", meta=(WorldContext="WorldContextObject"))
	static bool CanProjectPointToNavigation(UObject* WorldContextObject, FVector Point);

	/** Capture local player state and OpenLevel to Map (carry via UShockGameInstance). */
	UFUNCTION(BlueprintCallable, Category="BioShock|Travel")
	void TravelToLevel(const FString& Map, FName StartLabel);

	/**
	 * PostLogin branch: restore pending carry when present, else EquipStarterWeapon.
	 * Headless verify calls this to exercise both paths without a full OpenLevel.
	 */
	UFUNCTION(BlueprintCallable, Category="BioShock|Travel")
	bool ApplyArrivalLoadout(AShockPlayer* Player);

	/** Headless verify: explicit starter path (same as PostLogin when no pending carry). */
	UFUNCTION(BlueprintCallable, Category="BioShock|Slice")
	void EquipStarterWeaponForVerify(AShockPlayer* Player);

	/** Create radial + select + status + pause widgets (once). HUD stays at Z=0. */
	void EnsureSelectionUiForPlayer(APlayerController* PC);

	void OpenWeaponRadial(AShockPlayer* Player);
	void OpenPlasmidRadial(AShockPlayer* Player);
	void CloseRadial(bool bEquipHovered);
	void StepRadialHover(int32 Delta);
	void ToggleWeaponSelect(AShockPlayer* Player);
	void ToggleStatusMenu(AShockPlayer* Player);
	void TogglePauseMenu(AShockPlayer* Player);
	void ForceOpenRadialForCapture(AShockPlayer* Player);
	void ForceOpenStatusForCapture(AShockPlayer* Player);
	void ForceOpenPauseForCapture(AShockPlayer* Player);
	void ForceOpenStationForCapture(AShockPlayer* Player, EShockStationKind Kind);
	void ForceOpenHackingForCapture(AShockPlayer* Player);

	UShockRadialMenu* GetPlayerRadial() const { return PlayerRadial; }
	UShockWeaponSelectScreen* GetPlayerSelectScreen() const { return PlayerSelect; }
	UShockStatusMenu* GetPlayerStatusMenu() const { return PlayerStatus; }
	UShockPauseMenu* GetPlayerPauseMenu() const { return PlayerPause; }
	UShockStationMenu* GetCaptureStationMenu() const { return CaptureStationMenu; }
	UShockHackingMinigame* GetCaptureHackingMenu() const { return CaptureHackingMenu; }

private:
	void SnapPawnToStart(APawn* Pawn, AActor* Start);
	void EquipStarterWeapon(AShockPlayer* Player);
	void SpawnSliceEncounter(AShockPlayer* Player, AActor* StartSpot);
	ABaseShockAI* SpawnOneSliceEnemy(
		AShockPlayer* Player,
		int32 Index,
		FName ArchetypeKey,
		const FVector& SpawnLoc,
		const FRotator& SpawnRot,
		bool bForceRangedWeapon);
	void SpawnSliceEnemyStaggered(
		AShockPlayer* Player,
		AActor* StartSpot,
		int32 Index,
		FVector SpawnLoc,
		FRotator SpawnRot,
		FName ArchetypeKey,
		bool bForceRangedWeapon);
	void VerifySliceEncounter(AShockPlayer* Player);
	void EnsureSliceNavigation(AShockPlayer* Player, AActor* StartSpot);
	void SpawnSliceAmmoPickup(AShockPlayer* Player, AActor* StartSpot, ABaseShockAI* Enemy);
	void SpawnSliceConsumablePickup(AShockPlayer* Player, AActor* StartSpot, ABaseShockAI* Enemy);
	void SpawnSliceTurret(AShockPlayer* Player, AActor* StartSpot);
	void SpawnSliceSecurityCamera(AShockPlayer* Player, AActor* StartSpot);
	void SpawnSliceStations(AShockPlayer* Player, AActor* StartSpot);
	void VerifySliceFire(AShockPlayer* Player, ABaseShockAI* Enemy);
	/** -bioshockverifymovement: drive MoveForward for real seconds, log displacement, exit. */
	void BeginVerifyMovement(AShockPlayer* Player);
	void TickVerifyMovementDrive();
	void FinishVerifyMovement();
	/** -bioshockverifyweapontrack: reload Pistol, sample weapon world transform, exit. */
	void BeginVerifyWeaponTrack(AShockPlayer* Player);
	void TickVerifyWeaponTrackSample();
	void FinishVerifyWeaponTrack();
	void EnsureHudForPlayer(APlayerController* PC);
	UShockDeathRespawnHandler* EnsureDeathHandler();

	/**
	 * Drives -bioshockscreenshot: wait for the scene to actually resolve, take one shot, exit.
	 *
	 * This exists because every visual defect in this project so far was found by a person opening
	 * the editor, never by a check. The headless verifies run under -run=pythonscript with a Null
	 * RHI and cannot render a single pixel, so a level whose every wall painted one flat colour
	 * passed all of them. The -game harness already runs on D3D12, so it can photograph itself.
	 */
	void TickScreenshotCapture();

	/** Deproject a grid of screen positions and log the actor/mesh/material each one hits. */
	void ProbeScreenGrid(APlayerController* PC, int32 ShotW, int32 ShotH);

	/** Where the first-person hands sit relative to the eye, and where that lands on screen. */
	void ProbeViewmodel(APlayerController* PC, int32 ShotW, int32 ShotH);

	FTimerHandle SliceEncounterSpawnTimer0;
	FTimerHandle SliceEncounterSpawnTimer1;
	FTimerHandle SliceEncounterSpawnTimer2;
	FTimerHandle SliceEncounterVerifyTimer;
	FTimerHandle ScreenshotTimer;
	FTimerHandle MovementVerifyDriveTimer;
	FTimerHandle MovementVerifyFinishTimer;
	FTimerHandle WeaponTrackSampleTimer;
	FTimerHandle WeaponTrackFinishTimer;
	int32 ScreenshotTicks = 0;
	bool bScreenshotRequested = false;

	TWeakObjectPtr<AShockPlayer> MovementVerifyPlayer;
	FVector MovementVerifyStartLoc = FVector::ZeroVector;
	FVector MovementVerifyTargetLoc = FVector::ZeroVector;
	uint8 MovementVerifyModeStart = 0;
	bool bMovementVerifySawDisabled = false;
	bool bMovementVerifySawFalling = false;
	bool bMovementVerifyHasTarget = false;
	float MovementVerifyMinZIncrease = 0.0f;
	float MovementVerifyDuration = 2.5f;
	FString MovementVerifyRoute;
	TArray<FVector> MovementVerifyWaypoints;
	int32 MovementVerifyWaypointIndex = 0;

	TWeakObjectPtr<AShockPlayer> WeaponTrackPlayer;
	TWeakObjectPtr<AShockWeapon> WeaponTrackWeapon;
	FVector WeaponTrackFirstLoc = FVector::ZeroVector;
	FVector WeaponTrackLastLoc = FVector::ZeroVector;
	FVector WeaponTrackMinLoc = FVector::ZeroVector;
	FVector WeaponTrackMaxLoc = FVector::ZeroVector;
	FRotator WeaponTrackFirstRot = FRotator::ZeroRotator;
	FRotator WeaponTrackLastRot = FRotator::ZeroRotator;
	int32 WeaponTrackSampleCount = 0;
	float WeaponTrackAnimLength = 0.0f;
	FName WeaponTrackAnimName = NAME_None;

	/** -bioshockshotyaw/pitch offset applied to the capture, so the probe can aim the same way. */
	FRotator ScreenshotAimDelta = FRotator::ZeroRotator;

	UPROPERTY()
	TObjectPtr<UShockDeathRespawnHandler> DeathHandler;

	UPROPERTY()
	TObjectPtr<UShockHudWidget> PlayerHud;

	UPROPERTY()
	TObjectPtr<UShockRadialMenu> PlayerRadial;

	UPROPERTY()
	TObjectPtr<UShockWeaponSelectScreen> PlayerSelect;

	UPROPERTY()
	TObjectPtr<UShockStatusMenu> PlayerStatus;

	UPROPERTY()
	TObjectPtr<UShockPauseMenu> PlayerPause;

	/** Transient station widget used by -bioshockshotvend / genebank / invent / garden / combo. */
	UPROPERTY()
	TObjectPtr<UShockStationMenu> CaptureStationMenu;

	/** Transient hacking minigame used by -bioshockshothack. */
	UPROPERTY()
	TObjectPtr<UShockHackingMinigame> CaptureHackingMenu;
};
