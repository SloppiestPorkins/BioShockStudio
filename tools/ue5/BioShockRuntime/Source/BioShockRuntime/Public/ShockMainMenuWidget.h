#pragma once

#include "Blueprint/UserWidget.h"
#include "ShockMainMenuWidget.generated.h"

class UButton;
class UTextBlock;
class UVerticalBox;

/** Front-end start screen: title + Play / Options / Quit. UI built in C++ so headless setup needs no designer. */
UCLASS()
class BIOSHOCKRUNTIME_API UShockMainMenuWidget : public UUserWidget
{
	GENERATED_BODY()

public:
	UShockMainMenuWidget(const FObjectInitializer& ObjectInitializer);

	/** Package path of the playable slice map (default: /Game/BioShockSlice/1-Medical). */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|Menu")
	FString PlayLevelPath;

	/** Travel options for OpenLevel (no leading '?'). Hands control to ShockGameMode possess path. */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BioShock|Menu")
	FString PlayTravelOptions;

	UFUNCTION(BlueprintCallable, Category = "BioShock|Menu")
	void OnPlayClicked();

	UFUNCTION(BlueprintCallable, Category = "BioShock|Menu")
	void OnOptionsClicked();

	UFUNCTION(BlueprintCallable, Category = "BioShock|Menu")
	void OnQuitClicked();

	UFUNCTION(BlueprintPure, Category = "BioShock|Menu")
	FString GetResolvedPlayLevelPath() const;

protected:
	virtual TSharedRef<SWidget> RebuildWidget() override;
	virtual void NativeConstruct() override;

private:
	void EnsureWidgetTree();
	void BindButtons();

	UPROPERTY(Transient)
	TObjectPtr<UVerticalBox> RootBox = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UTextBlock> TitleText = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UButton> PlayButton = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UButton> OptionsButton = nullptr;

	UPROPERTY(Transient)
	TObjectPtr<UButton> QuitButton = nullptr;

	bool bButtonsBound = false;
};
