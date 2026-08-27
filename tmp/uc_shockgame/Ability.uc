class Ability extends Object
	native
	config(Abilities);

var config name ModGroupName;
var config float BioAmmoCost;
var config localized string FriendlyName;
var config bool InterruptsSanctuary;
var config name FastEquipAnimationName;
var config name FastUnEquipAnimationName;
var config name SlowEquipAnimationName;
var config name SlowUnEquipAnimationName;
var config name IdleAnimationName;
var config name FireAnimationName;
var config name FireLoopAnimationName;
var config name FireReleaseAnimationName;
var config name FinishFireWithEveAnimationName;
var config name FinishFireWithoutEveAnimationName;
var config travel array<name> IdlingAnimationName;
var config travel array<float> IdlingAnimationWeight;
var config Class<Actor> TargetIndicatorClass;
var config Vector TargetIndicatorOffset;
var config bool CanPendingFire;
var const config float PendingFireDelayTime;
var bool AbilityEffectsTriggered;

function name GetIdlingAnim()
{
	local int i;
	local float TotalWeight, SelectedWeight;

	AssertWithDescription(__NFUN_154__(IdlingAnimationName.Length, IdlingAnimationWeight.Length), __NFUN_112__(__NFUN_112__("The number of IdlingAnimationName and IdlingAnimationWeight for ability '", string(self.Name)), "' must be the same in Abilities.ini"));
	i = 0;
	// End:0xF3
	if(__NFUN_150__(i, IdlingAnimationWeight.Length))
	{
		__NFUN_184__(TotalWeight, IdlingAnimationWeight[i]);
		__NFUN_163__(i);
		// [Loop Continue]
		goto J0xAF;
		SelectedWeight = __NFUN_171__(__NFUN_195__(), TotalWeight);
		i = 0;
		// End:0x180
		if(__NFUN_150__(i, IdlingAnimationName.Length))
		{
			__NFUN_185__(SelectedWeight, IdlingAnimationWeight[i]);
		}
		// End:0x172
		if(__NFUN_178__(SelectedWeight, 0.0000000))
		{
			return IdlingAnimationName[i];
			__NFUN_163__(i);
			// [Loop Continue]
			goto J0x115;
			AssertWithDescription(false, __NFUN_112__(__NFUN_112__(__NFUN_112__("SelectedWeight = ", string(SelectedWeight)), ", TotalWeight = "), string(TotalWeight)));
			return IdlingAnimationName[__NFUN_167__(IdlingAnimationName.Length)];
		}
		return;
		@NULL
		Item
		Item
	}
	@NULL
}

function UseAbility(ShockPlayer Instigator)
{
	// End:0x24
	if(InterruptsSanctuary)
	{
		Instigator.LeaveSanctuary();
		Instigator.RemoveBioAmmo(GetBioAmmoCost(Instigator));
	}
	Instigator.TriggerEffectEvent('UsedAbility',,,,,,,, Class.Name);
	Instigator.dispatchMessage(Class'ShockGame.MessagePlayerUsedAbility'.static.Allocate(self)., construct_Class(Class));
	return;
	@NULL
	Item
	Item
	@NULL
}

function bool CanUseAbility(ShockPlayer Instigator)
{
	return __NFUN_132__(__NFUN_177__(Instigator.GetBioAmmo(), float(0)), __NFUN_180__(GetBioAmmoCost(Instigator), float(0)));
	return;
	@NULL
	Item
}

function bool CanUseAbilityOnRelease(ShockPlayer Instigator)
{
	return false;
	return;
}

function float GetBioAmmoCost(ShockPlayer Instigator)
{
	return BioAmmoCost;
	return;
	@NULL
}

function bool ShouldUseAbilityOnRelease()
{
	return false;
	return;
}

function bool HasBeenInterrupted(ShockPlayer Instigator)
{
	return false;
	return;
}

function StartedUsingAbility(ShockPlayer Instigator)
{
	return;
}

function UseAbilityRelease(ShockPlayer Instigator)
{
	return;
}

function OnReleased(ShockPlayer Instigator)
{
	return;
}

function name GetCurrentUseName()
{
	return Class.Name;
	return;
	@NULL
	Item
}

function name GetFinishFireWithEveAnimationName()
{
	return FinishFireWithEveAnimationName;
	return;
	@NULL
}

function name GetFinishFireWithoutEveAnimationName()
{
	return FinishFireWithoutEveAnimationName;
	return;
	@NULL
}

defaultproperties
{
	BioAmmoCost=1.0000000
	FriendlyName="The 'FriendlyName' field needs to be configured in Abilities.ini for this Ability"
	FastEquipAnimationName="Generic_HandEquip"
	FastUnEquipAnimationName="HandsDown"
	SlowEquipAnimationName="Generic_HandEquip"
	SlowUnEquipAnimationName="HandsDown"
	FireAnimationName="Generic_Fire"
	FireLoopAnimationName="Generic_FireLoop"
	FinishFireWithEveAnimationName="Generic_FireEve"
	FinishFireWithoutEveAnimationName="Generic_FireNoEve"
	IdlingAnimationName[0]="Generic_Fidget"
	IdlingAnimationWeight[0]=100.0000000
	CanPendingFire=true
	PendingFireDelayTime=0.5000000
}