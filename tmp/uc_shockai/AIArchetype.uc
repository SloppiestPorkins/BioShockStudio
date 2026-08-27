class AIArchetype extends Object
	native
	config(Spawning)
	perobjectconfig;

struct native atomic AttachmentChancePair
{
	var config Class<AIAttachment> AIAttachmentClass;
	var config float Chance;

	structdefaultproperties
	{
		CheckpointTypePadding=7602293
	}
};

struct native atomic MaterialChancePair
{
	var config Material AIMaterial;
	var config float Chance;

	structdefaultproperties
	{
		CheckpointTypePadding=7602293
	}
};

struct native atomic ReplacementWeaponChancePair
{
	var config Class<AIWeapon> CurrentAIWeaponClass;
	var config Class<AIWeapon> ReplacementAIWeaponClass;
	var config float Chance;

	structdefaultproperties
	{
		CheckpointTypePadding=7602293
	}
};

var config Class<ShockAI> AIType;
var config SkeletalMesh Mesh;
var config name DefaultPteLinkedBonesSetupName;
var config float Health;
var config name DamageResistanceSetName;
var config bool bShouldGoRagdollOnDeath;
var config float FrozenHealth;
var config float FrozenHealthDecayPerSecond;
var config float BurningTimeout;
var config float ShatteredDamageAmount;
var config bool bCannotBeShattered;
var config bool bDoNotDoBurningBehavior;
var config bool bDoNotDoBurningAnimations;
var config bool bDoNotDoInsectSwarmAnimations;
var config bool bDoNotDoInsectSwarmBehavior;
var config bool bCanRunAway;
var config array<name> RequiredAnimationGroups;
var config array<name> VoiceTypes;
var config array<MaterialChancePair> MaterialSlot;
var config array<AttachmentChancePair> AttachmentSlot_1;
var config array<AttachmentChancePair> AttachmentSlot_2;
var config array<AttachmentChancePair> AttachmentSlot_3;
var config array<AttachmentChancePair> AttachmentSlot_4;
var config array<ReplacementWeaponChancePair> WeaponSlot_1;
var config array<ReplacementWeaponChancePair> WeaponSlot_2;
var config array<ReplacementWeaponChancePair> WeaponSlot_3;
var config array<ReplacementWeaponChancePair> WeaponSlot_4;
var config float CollisionHeight;
var config float CollisionRadius;
var config localized string FriendlyName;
var config name DeadPhotoLabel;
var config name ResearchTrack;
var config bool bNoResearchTrack;
var config localized string CorpseString;
var config Material TeleportOutTransitionShader;
var config Material TeleportInTelegraphShader;
var config Material TeleportInTransitionShader;
var config Material TeleportInTelegraphShaderFire;
var config Material TeleportInTransitionShaderFire;
var config Material TeleportOutTransitionShaderFire;
var config Material TeleportInTelegraphShaderIce;
var config Material TeleportInTransitionShaderIce;
var config Material TeleportOutTransitionShaderIce;
var config Material TeleportInTelegraphShaderLightning;
var config Material TeleportInTransitionShaderLightning;
var config Material TeleportOutTransitionShaderLightning;
var config Material AtlasSkinFire;
var config Material AtlasSkinIce;
var config Material AtlasSkinLightning;
var config Material IncinerateMaterial;
var config bool bShouldBeHarvested;
var config float MaxBurningEfficacy;
var config float MaxFrozenEfficacy;
var config float MaxShockedEfficacy;

defaultproperties
{
	bShouldGoRagdollOnDeath=true
	bCanRunAway=true
}