class ActionDealShockingDamageInRadius extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var name SourceActorLabel;
var float DamageAmount;
var int InnerRadius;
var int OuterRadius;
var int MaxNumBolts;
var DamageStimuliSet.DamageStimulusType DamageType;
var Class<Emitter> EffectClass;
var float EffectTime;
var Range NewBeamDelay;

function Variable execute()
{
	local Actor A;
	local TeslaRadius DamageSource;

	super.execute();
	// End:0x1A1
	foreach parentScript.dynamicActorLabel(Class'Engine.Actor', A, SourceActorLabel)
	{
		DamageSource = parentScript.__NFUN_278__(Class'ShockAI.TeslaRadius',,, A.Location);
		/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
			
		*/

		// End:0x142
		/*@Error*/
		DamageSource.SetRadius(float(OuterRadius));
		DamageSource.SetEffectClass(EffectClass);
		DamageSource.SetMaxNumBolts(MaxNumBolts);
		DamageSource.SetNewBeamDelay(NewBeamDelay);
		DamageSource.SetEffectTime(EffectTime);
		DamageSource.ZAP();
		Class'ShockGame.DamageFactory'.static.DealRadiusDamage_ActorVectorFloatFloatByteFloatFloat(A, A.Location, float(InnerRadius), float(OuterRadius), DamageType, DamageAmount);				
		return none;
		return;
		@NULL
		CommanderAction
		CommanderAction
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
	S = __NFUN_112__(__NFUN_112__(__NFUN_112__(S, "around "), propertyDisplayString('SourceActorLabel')), "with arcing beams of electricy");
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}

defaultproperties
{
	DamageAmount=100.0000000
	InnerRadius=1024
	OuterRadius=1024
	MaxNumBolts=5
	DamageType=24
	EffectTime=3.0000000
	actionDisplayName="Deal Electrical Damage in a radius"
	actionHelp="Deals electrical damage in a radius around one or more actors"
	Category="Actor"
}