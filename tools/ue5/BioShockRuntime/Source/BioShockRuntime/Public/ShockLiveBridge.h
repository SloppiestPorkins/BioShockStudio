#pragma once

#include "CoreMinimal.h"
#include "Subsystems/WorldSubsystem.h"
#include "ShockLiveBridge.generated.h"

class FSocket;
class ACameraActor;
class ASceneCapture2D;
class UTextureRenderTarget2D;
class UTextureCube;
class UMaterialInstanceDynamic;
class AShockPlayer;
class UShockHudWidget;
struct FPostProcessSettings;

/**
 * Live bridge from the running original game (ROADMAP "original engine plays, UE5 renders").
 *
 * tools/livegame/live_bridge.py reads BioshockHD.exe's memory and sends UDP text lines to
 * 127.0.0.1:<port>; this subsystem follows them:
 *   F <frame> <gameSeconds>
 *   C x y z pitch yaw roll hfovDeg             camera (world units, degrees)
 *   B <BioShockKey> x y z pitch yaw roll       the actor's pose in the level file (= its import pose)
 *   A <BioShockKey> x y z pitch yaw roll hid   the actor's live pose and bHidden
 *   S key static|skel meshName                 spawn a stand-in for an actor the level file lacks
 *                                              (runtime-spawned: enemies, door leaves, pickups...)
 *   D key x y z pitch yaw roll sx sy sz hid    absolute pose of a spawned stand-in
 *   X key                                      the game destroyed it
 *   P key n (tx ty tz qx qy qz qw) x n         a skeletal stand-in's bones, component space, in
 *                                              the game's (= the imported rig's) bone order
 *   H health maxHealth eve maxEve adam         the player's stats, shown on the runtime HUD widget
 *                                              (the game's own HUD is underneath the overlay)
 *   Z r g b intensity                          the player's zone ambient (BioShock ZoneInfo
 *                                              CurrentAmbientColorHigh x multiplier), applied as a
 *                                              post-process ambient cubemap on the view
 *   L value                                    BakedExposure on the baked-world actor's materials:
 *                                              brightness of the original's baked BSP lighting
 *                                              (import_baked_world.py)
 * Actors move by the game's change from B, applied to their imported transform, so import-time
 * pivot and axis conventions carry through untouched.
 *
 * Active only with -bioshocklive[=port] (default 7781), in a game world. Run it under a plain
 * GameModeBase so this project's own gameplay code does not fight the original's.
 *   -bioshocklivecapture=<dir>   write a frame from the live camera every -bioshocklivecapevery=<s>
 *   -bioshockliveseconds=<s>     exit after that long
 */
UCLASS()
class BIOSHOCKRUNTIME_API UShockLiveBridge : public UTickableWorldSubsystem
{
	GENERATED_BODY()

public:
	virtual bool ShouldCreateSubsystem(UObject* Outer) const override;
	virtual void Initialize(FSubsystemCollectionBase& Collection) override;
	virtual void OnWorldBeginPlay(UWorld& InWorld) override;
	virtual void Deinitialize() override;
	virtual void Tick(float DeltaTime) override;
	virtual TStatId GetStatId() const override;

private:
	struct FTracked
	{
		TWeakObjectPtr<AActor> Actor;
		FVector UeLoc0 = FVector::ZeroVector;
		FQuat UeRot0 = FQuat::Identity;
		FVector GameLoc0 = FVector::ZeroVector;
		FQuat GameRot0 = FQuat::Identity;
		bool bHaveBase = false;
		bool bMadeMovable = false;
		bool bHidden = false;
	};

	void ApplyLine(const TArray<FString>& Tok);
	void CaptureFrame();
	void ApplyAmbient(FPostProcessSettings& PP) const;
	void SetBakedExposure(float Value);
	void BuildMeshIndex();
	void SpawnStandIn(const FName& Key, bool bSkeletal, const FString& MeshName);

	bool bActive = false;
	FSocket* Socket = nullptr;
	int32 Port = 7781;

	UPROPERTY()
	TObjectPtr<ACameraActor> Camera;
	UPROPERTY()
	TObjectPtr<ASceneCapture2D> Capture;
	UPROPERTY()
	TObjectPtr<UTextureRenderTarget2D> Target;
	UPROPERTY()
	TObjectPtr<UTextureCube> AmbientCube;
	UPROPERTY()
	TArray<TObjectPtr<UMaterialInstanceDynamic>> BakedMids;
	float BakedExposure = -1.f;

	FLinearColor AmbientTint = FLinearColor::Black;
	float AmbientIntensity = -1.f;  // < 0: not driven yet

	UPROPERTY()
	TObjectPtr<AShockPlayer> HudPlayer;
	UPROPERTY()
	TObjectPtr<UShockHudWidget> Hud;
	void UpdateHud(const TArray<FString>& Tok);

	TMap<FName, FTracked> Tracked;
	UPROPERTY()
	TMap<FName, TObjectPtr<AActor>> Spawned;
	TMap<FString, FSoftObjectPath> StaticMeshByName;
	TMap<FString, FSoftObjectPath> SkeletalMeshByName;
	TSet<FString> MissingMeshes;
	TSet<FName> UnknownKeys;
	int64 LastFrame = -1;
	float LastGameSeconds = 0.f;
	float Hfov = 90.f;
	bool bHaveCamera = false;

	FString CaptureDir;
	float CaptureEvery = 1.f;
	float CaptureClock = 0.f;
	float ExitAfter = 0.f;
	float RunClock = 0.f;
	float LogClock = 0.f;
	int64 Lines = 0;
	int64 Moves = 0;
};
