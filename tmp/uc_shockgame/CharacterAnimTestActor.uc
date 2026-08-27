class CharacterAnimTestActor extends NonPhysicalReactiveActor
	native
	config
	hidecategories(DrawScale3D,DisplayAdvanced,Events,Object,Sound,Force,Pressure,Collision,Havok);

function int GetDesiredAnimationCapabilities()
{
	return __NFUN_158__(__NFUN_158__(super(Actor).GetDesiredAnimationCapabilities(), 32), 128);
	return;
	@NULL
}

function TakeDamage(DamageStimuliSet DamageStimuli, float CritChance, Actor Damager, Vector HitLocation, Vector HitNormal, Vector HitImpulseDirection, name EffectEventName, float DamageAttenuation, name HitHighBone, name HitLowBone, bool WasMeleeAttack)
{
	super(ReactiveActor).TakeDamage(DamageStimuli, CritChance, Damager, HitLocation, HitNormal, HitImpulseDirection, EffectEventName, DamageAttenuation, HitHighBone, HitLowBone, WasMeleeAttack);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0xB1
	/*@Error*/
	GetQuickHitReaction().TakeHit(HitLocation, HitImpulseDirection, HitHighBone);
	return;
	@NULL
	Item
	Item
	@NULL
}
