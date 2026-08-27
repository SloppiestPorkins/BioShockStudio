class ReactionDealDamage extends Object implements IReaction;

function React(ReactiveActor inReactiveActor, ReactionData inData)
{
	local int InnerRadius, OuterRadius;
	local float CritChance, DamageAmount;
	local DamageStimuliSet.DamageStimulusType DamageType;
	local bool AlsoDamageSelf;

	// End:0xC8
	if(__NFUN_130__(inData.Bool_2, __NFUN_129__(inReactiveActor.IsBurning())))
	{
		log('Damage', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(string(inReactiveActor.Name), " NOT executing reaction "), string(Name)), " because this ReactiveActor is not currently Burning."));
		return;
		InnerRadius = inData.Int_1;
		OuterRadius = inData.Int_2;
	}
	DamageAmount = inData.Float_1;
	CritChance = inData.Float_2;
	DamageType = inData.DamageType;
	AlsoDamageSelf = inData.Bool_1;
	log('Damage', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(string(inReactiveActor.Name), " executing reaction "), string(Name)), ".React(): applying "), string(DamageAmount)), " of damage type "), string(GetEnum(Enum'Engine.DamageStimuliSet.DamageStimulusType', int(DamageType)))), " with InnerRadius "), string(InnerRadius)), " OuterRadius "), string(OuterRadius)), " and CriticalChance "), string(CritChance)), " at location "), string(inReactiveActor.Location)));
	Class'ShockGame.DamageFactory'.static.DealRadiusDamage_ActorVectorFloatFloatByteFloatFloat(inReactiveActor, inReactiveActor.Location, float(InnerRadius), float(OuterRadius), DamageType, DamageAmount, CritChance);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x385
	/*@Error*/
	inReactiveActor.TakeScriptedDamage(DamageType, DamageAmount, 1.0000000, inReactiveActor);
	return;
	@NULL
	Item
	Item
	@NULL
}

function string GetReactionEditorDescription()
{
	return __NFUN_112__(__NFUN_112__(__NFUN_112__("Cause damage to nearby actors", " ("), string(default.Class.Name)), ")");
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
		// End:0x70
		if(__NFUN_254__('Float_1', OriginalName))
		{
		}
		return "DamageAmount";
		// End:0x9D
		if(__NFUN_254__('Float_2', OriginalName))
		{
		}
		return "ChanceOfCriticalHit";
		// End:0xC1
		if(__NFUN_254__('DamageType', OriginalName))
		{
		}
		return "DamageType";
		// End:0xE9
		if(__NFUN_254__('Bool_1', OriginalName))
		{
			return "AlsoDamageSelf";
		}
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x11A
		/*@Error*/
		return "OnlyDealDamageIfBurning";
	}
	return "";
	return;
	@NULL
	Item
	Item
	@NULL
}
