class SecurityCrate extends AnimatedContainer implements ICanBeHacked, IDamagee
	native
	config(ShockGame)
	hidecategories(DrawScale3D,DisplayAdvanced,Events,Object,Sound,Force,Pressure,Movement,Havok);

var(Hacking) private name HackInfoName;
var transient HackInfo HackingGameSetupInfo;
var private config localized string HackingSuccessFeedbackText;
var private bool bIsUnlocked;
var private bool bIsHacked;

function bool CanBeUsedNow()
{
	return __NFUN_130__(super.CanBeUsedNow(), bIsUnlocked);
	return;
	@NULL
	Item
}

function bool IsHacked()
{
	return bIsHacked;
	return;
	@NULL
}

function PreBeginPlay()
{
	super.PreBeginPlay();
	return;
	@NULL
}

function string GetHackVerbText()
{
	return "HACK";
	return;
}

function bool CanBeHackedNow(ShockPlayer Player)
{
	return __NFUN_130__(__NFUN_129__(bIsUnlocked), __NFUN_129__(bIsHacked));
	return;
	@NULL
	Item
}

function OnHackAttempted(ShockPlayer Player)
{
	Player.OnStartHacking(GetHackInfo(), self);
	Level.GetFlashGUIController().GetPlayingMovie('Hacking').CallMethodString("SetHackDescription", HackingSuccessFeedbackText);
	return;
	@NULL
	Item
	Item
	@NULL
}

function HackInfo GetHackInfo()
{
	// End:0x4C
	if(__NFUN_114__(HackingGameSetupInfo, none))
	{
		HackingGameSetupInfo = Class'ShockGame.HackInfo'.static.Allocate(self,, string(HackInfoName)).;
		Construct_Void();
		return HackingGameSetupInfo;
		return;
		@NULL
		Item
	}
	Item
	@NULL
}

function HackInfo OnHackSucceeded(ShockPlayer Player, string HackResult)
{
	log('SecurityCrate', 3, __NFUN_112__(string(self), ": Hack attempt SUCCEEDED"));
	TriggerEffectEvent('HackSucceeded');
	bIsHacked = true;
	Open();
	Level.GetLocalPlayerController().ClientMessage(HackingSuccessFeedbackText, 'HackingSuccess');
	return GetHackInfo();
	return;
	@NULL
	Item
	Item
	@NULL
}

function HackInfo OnHackFailed(ShockPlayer Player, string HackResult)
{
	log('SecurityCrate', 3, __NFUN_112__(string(self), ": Hack attempt FAILED"));
	TriggerEffectEvent('HackFailed');
	return GetHackInfo();
	return;
}

function IPotentialAimOrActionTarget.TargetType GetTargetType()
{
	// End:0x13
	if(bCanSoftLock)
	{
		return 2;
		goto J0x48;
		// End:0x45
		if(__NFUN_130__(bCanStickyTarget, __NFUN_132__(CanBeUsedNow(), CanBeHackedNow(none))))
		{
		}
		return 1;
		goto J0x48;
		return 0;
		return;
		@NULL
	}
	Item
}

function TakeDamage(DamageStimuliSet DamageStimuli, float CritChance, Actor Damager, Vector HitLocation, Vector HitNormal, Vector HitImpulseDirection, name EffectEventName, float DamageAttenuation, name HitHighBone, name HitLowBone, optional bool WasMeleeAttack)
{

	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/
	// End:0x26
	/*@Error*/
	Open();
	return;
	@NULL
}

function TakeScriptedDamage(DamageStimuliSet.DamageStimulusType DamageType, float DamageAmount, float DamageChance, optional Actor Damager)
{
	local DamageStimuliSet DamageStimuli;
	local DamageStimulus theDamageStimulus;

	DamageStimuli = Class'Engine.DamageStimuliSet'.static.Allocate(self,,, 134217728).;
	Construct_Void();
	theDamageStimulus.Type = DamageType;
	theDamageStimulus.Amount = DamageAmount;
	theDamageStimulus.Chance = DamageChance;
	DamageStimuli.Stimulus[0] = theDamageStimulus;
	TakeDamage(DamageStimuli, 0.0000000, Damager, vect(0.0000000, 0.0000000, 0.0000000), vect(0.0000000, 0.0000000, 0.0000000), vect(0.0000000, 0.0000000, 0.0000000), 'None', 1.0000000, 'None', 'None');
	DamageStimuli.__NFUN_200__();
	return;
	@NULL
	Item
	Item
	@NULL
}

function AllHackInfoNames(LevelInfo Level, out array<name> S)
{
	local int i;
	local HackInfoList HackInfoList;

	HackInfoList = Class'ShockGame.HackInfoList'.static.Allocate(self).;
	Construct_Void();
	i = 0;
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xA3
	/*@Error*/
	S[i] = HackInfoList.HackInfoName[i];
	__NFUN_165__(i);
	// [Loop Continue]
	goto J0x3C;
	HackInfoList.__NFUN_200__();
	return;
	@NULL
	Item
	Item
	@NULL
}

state Opened
{	stop;
}

defaultproperties
{
	HackInfoName="SecurityCrateDefault"
	HackingSuccessFeedbackText="RESULT OF SUCCESSFUL HACK: Safe becomes unlocked."
	FriendlyName="Security Crate"
	DrawType=8
}