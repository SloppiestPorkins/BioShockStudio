class EmitterAmmo extends Ammunition implements IProvideEmitterDamageData
	config(Weapons);

var config Class<DamageEmitter> EmitterClass;
var config Class<DamageEmitter> HighPressureEmitterClass;

function Class<DamageEmitter> GetEmitterClass()
{
	return EmitterClass;
	return;
	@NULL
}

function Class<DamageEmitter> GetHighPressureEmitterClass()
{
	return HighPressureEmitterClass;
	return;
	@NULL
}

defaultproperties
{
	EmitterClass=Class'ShockGame.FXClass.FlameThrowerTestB'
	HighPressureEmitterClass=Class'ShockGame.FXClass.FlameThrowerTestB'
	DamageModel=Class'ShockGame.EmitterDamageFactory'
}