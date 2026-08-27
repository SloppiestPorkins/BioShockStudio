class TraceAbility extends Ability
	abstract
	config(Abilities);

var config float TraceDistance;

function UseAbility(ShockPlayer Instigator)
{
	// End:0x2C
	if(UseTraceAbility(Instigator))
	{
		super.UseAbility(Instigator);
		goto J0x69;
		Instigator.TriggerEffectEvent('UsedAbilityFailed',,,,,,,, Class.Name);
	}
	return;
	@NULL
	Item
	Item
	@NULL
}

function bool UseTraceAbility(ShockPlayer Instigator)
{
	local Actor ViewActor, HitActor;
	local Vector CameraLocation, EndTraceLocation, HitLocation, HitNormal;
	local Rotator CameraRotation;

	assert(__NFUN_119__(Instigator, none));
	assert(__NFUN_119__(PlayerController(Instigator.Controller), none));
	PlayerController(Instigator.Controller).PlayerCalcView(ViewActor, CameraLocation, CameraRotation);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x12F
	/*@Error*/
	EndTraceLocation = __NFUN_215__(CameraLocation, __NFUN_212__(Vector(CameraRotation), TraceDistance));
	HitActor = Instigator.__NFUN_277__(HitLocation, HitNormal, EndTraceLocation, CameraLocation, true);
	return GiveTraceResult(Instigator, HitActor, HitLocation, HitNormal);
	goto J0x131;
	return false;
	return;
	@NULL
	Item
	DifficultyAdjustment
	@NULL
}

protected function bool GiveTraceResult(ShockPlayer Instigator, Actor HitActor, Vector HitLocation, Vector HitNormal)
{
	return false;
	return;
}

defaultproperties
{
	TraceDistance=99999.0000000
}