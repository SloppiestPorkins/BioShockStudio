class ReactionDealDamageAndImpulse extends Object implements IReaction;

function React(ReactiveActor inReactiveActor, ReactionData inData)
{
	local int InnerRadius, OuterRadius;
	local float CritChance;
	local name DamageStimuliSetName;
	local DamageStimuliSet DamageStimuliSet;
	local bool AlsoDamageSelf;

	// End:0xC8
	if(__NFUN_130__(inData.Bool_2, __NFUN_129__(inReactiveActor.IsBurning())))
	{
		log('Damage', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(string(inReactiveActor.Name), " NOT executing reaction "), string(Name)), " because this ReactiveActor is not currently Burning."));
		return;
		InnerRadius = inData.Int_1;
		OuterRadius = inData.Int_2;
	}
	CritChance = inData.Float_2;
	AlsoDamageSelf = inData.Bool_1;
	DamageStimuliSetName = inData.Name_1;
	log('Damage', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(inReactiveActor.Name), " executing reaction "), string(Name)), ".React(): "), " using DamageStimuliSet "), string(DamageStimuliSetName)), " with InnerRadius "), string(InnerRadius)), " OuterRadius "), string(OuterRadius)), " and CriticalChance "), string(CritChance)), " at location "), string(inReactiveActor.Location)));
	Class'ShockGame.DamageFactory'.static.DealRadiusDamage_ActorVectorFloatFloatNameFloat(inReactiveActor, inReactiveActor.Location, float(InnerRadius), float(OuterRadius), DamageStimuliSetName, CritChance);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x39A
	/*@Error*/
	DamageStimuliSet = Class'Engine.DamageStimuliSet'.static.GetDamageStimuliSet(DamageStimuliSetName);
	inReactiveActor.TakeDamage(DamageStimuliSet, 0.0000000, inReactiveActor, vect(0.0000000, 0.0000000, 0.0000000), vect(0.0000000, 0.0000000, 0.0000000), vect(0.0000000, 0.0000000, 0.0000000), 'None', 1.0000000);
	DamageStimuliSet.__NFUN_200__();
	return;
	@NULL
	Item
	Item
	@NULL
}

function string GetReactionEditorDescription()
{
	return __NFUN_112__(__NFUN_112__(__NFUN_112__("Causes damage and imparts impulses to nearby actors", " ("), string(default.Class.Name)), ")");
	return;
	@NULL
	Item
}

function string GetReactionDataEditorDisplayName(name OriginalName)
{
	// End:0x25
	if(__NFUN_254__('Int_1', OriginalName))
	{
		return "InnerRadius";
		// End:0x4A
		if(__NFUN_254__('Int_2', OriginalName))
		{
		}
		return "OuterRadius";
		// End:0x77
		if(__NFUN_254__('Float_2', OriginalName))
		{
		}
		return "ChanceOfCriticalHit";
		// End:0x9F
		if(__NFUN_254__('Bool_1', OriginalName))
		{
		}
		return "AlsoDamageSelf";
		// End:0xD0
		if(__NFUN_254__('Bool_2', OriginalName))
		{
		}
		return "OnlyDealDamageIfBurning";
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0xFE
		/*@Error*/
		return "DamageStimuliSetName";
	}
	return "";
	return;
	@NULL
	Item
	Item
	@NULL
}
