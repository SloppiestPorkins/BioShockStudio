class EmitterAttackAbility extends AttackAbility implements IProvideEmitterDamageData
	abstract
	config(Abilities);

var config Class<DamageEmitter> EmitterClass;

function bool CanUseAbilityOnRelease(ShockPlayer Instigator)
{
	return true;
	return;
}

function bool ShouldUseAbilityOnRelease()
{
	return true;
	return;
}

function Class<DamageEmitter> GetEmitterClass()
{
	return EmitterClass;
	return;
	@NULL
}

function Class<DamageEmitter> GetHighPressureEmitterClass()
{
	return none;
	return;
}

defaultproperties
{
	EmitterClass=Class'ShockGame.FXClass.FlameThrowerTestB'
	DamageModel=Class'ShockGame.EmitterDamageFactory'
}