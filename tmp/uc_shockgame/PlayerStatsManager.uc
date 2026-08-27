class PlayerStatsManager extends Object
	native;

var private transient ShockGameDriver GameDriver;
var private float GameplayTime;
var private float LastDeltaTime;
var private transient TrainingMessageManager TrainingMessageManager;
var private transient DifficultyStatsManager DifficultyStatsManager;

function Construct(ShockGameDriver GameDriver)
{
	self.GameDriver = GameDriver;
	TrainingMessageManager = GameDriver.GetTrainingMessageManager();
	DifficultyStatsManager = GameDriver.GetDifficultyManager().DifficultyStatsManager;
	return;
	@NULL
	Item
	Vector
	@NULL
}

function PreLevelLoad()
{
	return;
}

function PostLevelLoad()
{
	return;
}

function float GetGameplayTime()
{
	return GameplayTime;
	return;
	@NULL
}

function SetGameplayTime(float NewGameplayTime)
{
	GameplayTime = float(__NFUN_250__(int(NewGameplayTime), int(GameplayTime)));
	return;
	@NULL
	Item
	Item
}

function PlayerMovement(float X, float Y)
{
	TrainingMessageManager.PlayerMovement(X, Y);
	return;
	@NULL
	Item
	Item
}

function PlayerView(float X, float Y)
{
	TrainingMessageManager.PlayerView(X, Y);
	return;
	@NULL
	Item
	Item
}

function PlayerInspectedBySecurityCamera()
{
	TrainingMessageManager.PlayerInspectedBySecurityCamera();
	return;
	@NULL
}

function PlayerEvadeSecurityCamera()
{
	TrainingMessageManager.PlayerEvadeSecurityCamera();
	return;
	@NULL
}

function PlayerTriggeredAlarm(ShockPlayer Player)
{
	log('FocusTesting',, "AlarmSetOff");
	TrainingMessageManager.PlayerTriggeredAlarm();
	Player.AwardAchievementsManager.PlayerTriggeredAlarm();
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function PlayerTriggeredAlarmTimedOut()
{
	log('FocusTesting',, "AlarmExpired");
	TrainingMessageManager.PlayerTriggeredAlarmTimedOut();
	return;
	@NULL
}

function PlayerTriggeredAlarmCancelled()
{
	log('FocusTesting',, "AlarmCancelled");
	TrainingMessageManager.PlayerTriggeredAlarmCancelled();
	return;
	@NULL
}

function PlayerDamaged(ShockPlayer Player, float Damage, Actor Damager)
{
	TrainingMessageManager.PlayerDamaged(Player, Damage, Damager);
	return;
	@NULL
	Item
	Item
	@NULL
}

function PlayerDealtDamage(float Damage, Actor Damagee)
{
	TrainingMessageManager.PlayerDealtDamage(Damage, Damagee);
	return;
	@NULL
	Item
	Item
}

function PlayerDirectHit(Actor Damagee)
{
	TrainingMessageManager.PlayerDirectHit(Damagee);
	return;
	@NULL
	Item
}

function PlayerDealtState(name StateName, Actor Damagee)
{
	TrainingMessageManager.PlayerDealtState(StateName, Damagee);
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function FrozenShattered()
{
	TrainingMessageManager.FrozenShattered();
	return;
	@NULL
}

function FrozenTimedOut()
{
	TrainingMessageManager.FrozenTimedOut();
	return;
	@NULL
}

function PlayerHitTarget(ShockPlayer Player, Actor Target, IProvideDamageData DamageData)
{
	TrainingMessageManager.PlayerHitTarget(Player, Target, DamageData);
	Player.AwardAchievementsManager.PlayerHitTarget(Target, DamageData);
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function KilledByPlayer(ShockPlayer Player, Actor Killed)
{
	TrainingMessageManager.KilledByPlayer(Killed);
	Player.AwardAchievementsManager.KilledByPlayer(Killed);
	return;
	@NULL
	Item
	Item
	@NULL
}

function PlayerDied(Actor Killer)
{
	TrainingMessageManager.PlayerDied(Killer);
	DifficultyStatsManager.PlayerDied(Killer);
	return;
	@NULL
	Item
	Item
	@NULL
}

function PlayerWeaponEquipped(ShockPlayer Player, Weapon Weapon)
{
	TrainingMessageManager.PlayerWeaponEquipped(Player, Weapon);
	return;
	@NULL
	Item
	Item
}

function PlayerWeaponReloaded(ShockPlayer Player, Weapon Weapon)
{
	TrainingMessageManager.PlayerWeaponReloaded(Player, Weapon);
	return;
	@NULL
	Item
	Item
}

function PlayerWeaponFired(ShockPlayer Player, Weapon Weapon)
{
	TrainingMessageManager.PlayerWeaponFired(Player, Weapon);
	return;
	@NULL
	Item
	Item
}

function PlayerAbilityFired(ShockPlayer Player, Ability Ability)
{
	TrainingMessageManager.PlayerAbilityFired(Player, Ability);
	return;
	@NULL
	Item
	Item
}

function SelectedAbility(ShockPlayer Player, Ability Ability)
{
	TrainingMessageManager.SelectedAbility(Player, Ability);
	return;
	@NULL
	Item
	Item
}

function PlayerPlasmidEquipped(ShockPlayer Player, Plasmid Plasmid)
{
	TrainingMessageManager.PlayerPlasmidEquipped(Player, Plasmid);
	Player.AwardAchievementsManager.PlayerPlasmidEquipped(Plasmid);
	return;
	@NULL
	Item
	Item
	@NULL
}

function PlayerPlasmidUnEquipped(ShockPlayer Player, Plasmid Plasmid)
{
	TrainingMessageManager.PlayerPlasmidUnEquipped(Player, Plasmid);
	return;
	@NULL
	Item
	Item
}

function PlayerPickedUpInventory(ShockPlayer Player, Class<Item> ItemClass, int Amount)
{
	TrainingMessageManager.PlayerPickedUpInventory(Player, ItemClass, Amount);
	Player.AwardAchievementsManager.PlayerPickedUpInventory(ItemClass, Amount);
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function PlayerUse(ICanBeUsed used)
{
	TrainingMessageManager.PlayerUse(used);
	return;
	@NULL
	Item
}

function PlayerMaxHealthUpdated(ShockPlayer Player)
{
	TrainingMessageManager.PlayerMaxHealthUpdated(Player);
	return;
	@NULL
	Item
}

function PlayerAddHealth(ShockPlayer Player, float Amount)
{
	TrainingMessageManager.PlayerAddHealth(Player);
	return;
	@NULL
	Item
}

function PlayerRemoveHealth(ShockPlayer Player, float Amount)
{
	TrainingMessageManager.PlayerRemoveHealth(Player);
	return;
	@NULL
	Item
}

function PlayerMaxBioAmmoUpdated(ShockPlayer Player)
{
	TrainingMessageManager.PlayerMaxBioAmmoUpdated(Player);
	return;
	@NULL
	Item
}

function PlayerAddBioAmmo(ShockPlayer Player, float Amount)
{
	TrainingMessageManager.PlayerAddBioAmmo(Player);
	return;
	@NULL
	Item
}

function PlayerRemoveBioAmmo(ShockPlayer Player, float Amount)
{
	TrainingMessageManager.PlayerRemoveBioAmmo(Player);
	return;
	@NULL
	Item
}

function PlayerCrouched(ShockPlayer Player)
{
	TrainingMessageManager.PlayerCrouched(Player);
	return;
	@NULL
	Item
}

function PlayerUnCrouched(ShockPlayer Player)
{
	TrainingMessageManager.PlayerUnCrouched(Player);
	return;
	@NULL
	Item
}

function PlayerHasSpentEPPs(ShockPlayer Player, int Amount)
{
	TrainingMessageManager.PlayerHasSpentEPPs(Player, Amount);
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function LookedAtMap()
{
	TrainingMessageManager.LookedAtMap();
	log('FocusTesting',, "LookedAtMapUI");
	return;
	@NULL
}

function LookedAtHelp()
{
	TrainingMessageManager.LookedAtHelp();
	log('FocusTesting',, "LookedAtHelpUI");
	return;
	@NULL
}

function LookedAtLogs()
{
	TrainingMessageManager.LookedAtLogs();
	log('FocusTesting',, "LookedAtLogsUI");
	return;
	@NULL
}

function LookedAtRadios()
{
	TrainingMessageManager.LookedAtRadios();
	log('FocusTesting',, "LookedAtRadiosUI");
	return;
	@NULL
}

function LookedAtQuests()
{
	TrainingMessageManager.LookedAtQuests();
	log('FocusTesting',, "LookedAtQuestsUI");
	return;
	@NULL
}

function SavedGame()
{
	log('FocusTesting',, "SavedGame");
	TrainingMessageManager.SavedGame();
	return;
	@NULL
}

function PickedUpUnplayedLog()
{
	TrainingMessageManager.PickedUpUnplayedLog();
	return;
	@NULL
}

function PlayedAllLogs()
{
	TrainingMessageManager.PlayedAllLogs();
	return;
	@NULL
}

function HandsModeChanged(name NewMode)
{
	TrainingMessageManager.HandsModeChanged(NewMode);
	return;
	@NULL
	Item
}

function FinishedHacking(ShockPlayer Player, ICanBeHacked HackedObject, string HackResult)
{
	TrainingMessageManager.FinishedHacking(HackedObject, HackResult);
	Player.AwardAchievementsManager.FinishedHacking(HackedObject, HackResult);
	return;
	@NULL
	Item
	Item
	@NULL
}

function ResearchedTrack(ShockPlayer Player, name ResearchTrack, bool AllowAwardingAchievements)
{
	// End:0x3A
	if(AllowAwardingAchievements)
	{
		Player.AwardAchievementsManager.ResearchedTrack(ResearchTrack);
		TrainingMessageManager.ResearchedTrack(Player, ResearchTrack);
	}
	return;
	@NULL
	Item
	Item
	@NULL
}

function PacifiedGatherer(ShockPlayer Player)
{
	Player.AwardAchievementsManager.PacifiedGatherer();
	return;
	@NULL
	Item
}

function SavedGatherer(ShockPlayer Player)
{
	Player.AwardAchievementsManager.SavedGatherer();
	TrainingMessageManager.SavedGatherer();
	return;
	@NULL
	Item
	Item
}

function WeaponUpgraded(ShockPlayer Player, name WeaponName)
{
	Player.AwardAchievementsManager.WeaponUpgraded(WeaponName);
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function CraftedItem(ShockPlayer Player, Class<Item> ItemClass)
{
	Player.AwardAchievementsManager.CraftedItem(ItemClass);
	TrainingMessageManager.CraftedItem(Player);
	DifficultyStatsManager.CraftedItem(Player, ItemClass);
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function GradePhoto(ShockPlayer Player, ShockPlayer.EPhotoGrade Grade, bool isSplicerPhoto)
{
	Player.AwardAchievementsManager.GradePhoto(Grade, isSplicerPhoto);
	return;
	@NULL
	Item
	Item
	@NULL
}

function PurchasedItem(Class<Item> ItemClass, ShockPlayer Player)
{
	Player.AwardAchievementsManager.PurchasedItem(ItemClass);
	DifficultyStatsManager.PurchasedItem(ItemClass, Player);
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function PlasmidTrackSlotUnlocked(ShockPlayer Player, Plasmid.ePlasmidTrack Track, int NumSlots)
{
	TrainingMessageManager.PlasmidTrackSlotUnlocked(Track);
	Player.AwardAchievementsManager.PlasmidTrackSlotUnlocked(Track, NumSlots);
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function PlasmidTrackSlotLocked(ShockPlayer Player, Plasmid.ePlasmidTrack Track, int NumSlots)
{
	TrainingMessageManager.PlasmidTrackSlotLocked(Player, Track, NumSlots);
	Player.AwardAchievementsManager.PlasmidTrackSlotLocked(Track, NumSlots);
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function OpenedSecurityCrate(ShockPlayer Player)
{
	Player.AwardAchievementsManager.OpenedSecurityCrate();
	return;
	@NULL
	Item
}

function AggressorKilledGoingToHealthStation()
{
	TrainingMessageManager.AggressorKilledGoingToHealthStation();
	return;
	@NULL
}

function AggressorGoingToHealthStation(ShockPawn AI)
{
	TrainingMessageManager.AggressorGoingToHealthStation(AI);
	return;
	@NULL
	Item
}

function AggressorHealedAtHealthStation()
{
	TrainingMessageManager.AggressorHealedAtHealthStation();
	return;
	@NULL
}

function AggressorPoisonedAtHealthStation()
{
	TrainingMessageManager.AggressorPoisonedAtHealthStation();
	return;
	@NULL
}

function ZoomModeChanged(bool Zoom)
{
	TrainingMessageManager.ZoomModeChanged(Zoom);
	return;
	@NULL
	Item
}

function CanUseVitaChamber(bool CanUse)
{
	TrainingMessageManager.CanUseVitaChamber(CanUse);
	return;
	@NULL
	Item
}

function PlayerUsedTelekineses(float HeldTime)
{
	TrainingMessageManager.PlayerUsedTelekineses(HeldTime);
	return;
	@NULL
	Item
}

function PlayerChangedAmmo()
{
	TrainingMessageManager.PlayerChangedAmmo();
	return;
	@NULL
}

function OpenWeaponMenu()
{
	TrainingMessageManager.OpenWeaponMenu();
	return;
	@NULL
}

function CloseWeaponMenu()
{
	TrainingMessageManager.CloseWeaponMenu();
	return;
	@NULL
}

function OpenAbilityMenu(ShockPlayer Player)
{
	TrainingMessageManager.OpenAbilityMenu(Player);
	return;
	@NULL
	Item
}

function CloseAbilityMenu()
{
	TrainingMessageManager.CloseAbilityMenu();
	return;
	@NULL
}

function OpenPCWeaponSelectionMenu()
{
	TrainingMessageManager.OpenPCWeaponSelectionMenu();
	return;
	@NULL
}

function ClosePCWeaponSelectionMenu()
{
	TrainingMessageManager.ClosePCWeaponSelectionMenu();
	return;
	@NULL
}

function ChangedDifficulty(ShockPlayer Player)
{
	Player.AwardAchievementsManager.ChangedDifficulty();
	TrainingMessageManager.ChangedDifficulty(Player);
	return;
	@NULL
	Item
	stop;
	default.@NULL
}

function PlayerUsedVita(ShockPlayer Player)
{
	log(,, "**** player used vita chamber ****");
	Player.AwardAchievementsManager.PlayerUsedVita();
	return;
	@NULL
	Item
}

function GameFinished(ShockPlayer Player, bool GoodEnding)
{
	Player.AwardAchievementsManager.GameFinished(GoodEnding);
	return;
	@NULL
	Item
	Item
}

function GPSUsed()
{
	TrainingMessageManager.GPSUsed();
	return;
	@NULL
}

function GPSCleared()
{
	TrainingMessageManager.GPSCleared();
	return;
	@NULL
}

function WeakButRich(string Category)
{
	TrainingMessageManager.WeakButRich(Category);
	return;
	@NULL
	Item
}

function NotWeakButRich(string Category)
{
	TrainingMessageManager.NotWeakButRich(Category);
	return;
	@NULL
	Item
}

function ChangedMapUIRegion(name MapUIRegion)
{
	TrainingMessageManager.ChangedMapUIRegion(MapUIRegion);
	return;
	@NULL
	Item
}

function DryFire()
{
	TrainingMessageManager.DryFire();
	return;
	@NULL
}

function PlayerLookingAt(ICanBeFocused Focus)
{
	TrainingMessageManager.PlayerLookingAt(Focus);
	return;
	@NULL
	Item
}

function PlayerLeaned()
{
	TrainingMessageManager.PlayerLeaned();
	return;
	@NULL
}

function PictureTaken(TrainingMessageManager.EPhotoRejectReason RejectReason)
{
	TrainingMessageManager.PictureTaken(RejectReason);
	return;
	@NULL
	Item
}

function BefriendUsed(string Result)
{
	TrainingMessageManager.BefriendUsed(Result);
	return;
	@NULL
	Item
}

function SecurityBeaconUsed(float BeaconTimeLeft)
{
	TrainingMessageManager.SecurityBeaconUsed(BeaconTimeLeft);
	return;
	@NULL
	Item
}

function PlayerInDoor(ShockDoor Door)
{
	TrainingMessageManager.PlayerInDoor(Door);
	return;
	@NULL
	Item
}

function EnrageFailure(BaseShockAI AI)
{
	TrainingMessageManager.EnrageFailure(AI);
	return;
	@NULL
	Item
}

function EnrageSuccess(BaseShockAI AI)
{
	TrainingMessageManager.EnrageSuccess(AI);
	return;
	@NULL
	Item
}

function ShockedAIinWater(ShockPlayer Player)
{
	Player.AwardAchievementsManager.ShockedAIinWater();
	return;
	@NULL
	Item
}

function IneffectiveElectricBolt()
{
	TrainingMessageManager.IneffectiveElectricBolt();
	return;
	@NULL
}

function IneffectiveIcicleAssault()
{
	TrainingMessageManager.IneffectiveIcicleAssault();
	return;
	@NULL
}
