class ActionDealDamageInRadius extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel name SourceActorLabel;
var travel float DamageAmount;
var travel DamageStimuliSet.DamageStimulusType DamageType;
var travel int InnerRadius;
var travel int OuterRadius;

function Variable execute()
{
	local Actor A;

	super.execute();
	// End:0x9E
	foreach parentScript.dynamicActorLabel(Class'Engine.Actor', A, SourceActorLabel)
	{
		Class'ShockGame.DamageFactory'.static.DealRadiusDamage_ActorVectorFloatFloatByteFloatFloat(A, A.Location, float(InnerRadius), float(OuterRadius), DamageType, DamageAmount);				
		return none;
		return;
		@NULL
		Item
		Item
		@NULL
	}
}

function editorDisplayString(out string S)
{
	S = __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("Deal ", propertyDisplayString('DamageAmount')), " points of "), string(GetEnum(Enum'Engine.DamageStimuliSet.DamageStimulusType', int(DamageType)))), " damage in a radius of ");
	// End:0xAC
	if(__NFUN_154__(InnerRadius, OuterRadius))
	{
		S = __NFUN_112__(S, string(OuterRadius));
		goto J0xF5;
		S = __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(S, " (Inner="), string(InnerRadius)), ",Outer="), string(OuterRadius)), ")");
	}
	S = __NFUN_112__(__NFUN_112__(S, "around "), propertyDisplayString('SourceActorLabel'));
	return;
	@NULL
	Item
	Item
	@NULL
}

defaultproperties
{
	DamageAmount=100.0000000
	DamageType=8
	InnerRadius=256
	OuterRadius=256
	actionDisplayName="Deal Damage in a radius"
	actionHelp="Deals damage in a radius around one or more actors"
	Category="Actor"
}