class ActionDealDamage extends Action
	editinlinenew
	collapsecategories
	hidecategories(Object);

var travel Class<IDamagee> DamageeClass;
var travel name Target;
var travel float DamageAmount;
var travel float DamageChance;
var travel DamageStimuliSet.DamageStimulusType DamageType;

function Variable execute()
{
	local Actor A;
	local Class<Actor> theActorClass;

	theActorClass = Class'Engine.Actor';
	// End:0x41
	if(__NFUN_258__(DamageeClass, Class'VengeanceShared.ReactiveActor'))
	{
		theActorClass = Class'VengeanceShared.ReactiveActor';
		goto J0x6C;
		// End:0x6C
		if(__NFUN_258__(DamageeClass, Class'ShockGame.ShockPawn'))
		{
			theActorClass = Class'ShockGame.ShockPawn';
		}
		super.execute();
		// End:0x124
		if(__NFUN_254__(Target, 'None'))
		{
			// End:0x120
			foreach parentScript.__NFUN_304__(theActorClass, A)
			{
			}/* !MISMATCHING REMOVE, tried If got Type:ForEach Position:0x05D! */
			// End:0x11F
			if(A.__NFUN_303__(DamageeClass.Name))
			{
				IDamagee(A).TakeScriptedDamage(DamageType, DamageAmount, DamageChance, parentScript);								
				goto J0x1C8;
				// End:0x1C7
				foreach parentScript.allActorLabel(theActorClass, A, Target)
				{
					/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
						
					*/

					// End:0x1C6
					/*@Error*/
					IDamagee(A).TakeScriptedDamage(DamageType, DamageAmount, DamageChance, parentScript);
				}/* !MISMATCHING REMOVE, tried If got Type:ForEach Position:0x0C4! */
			}/* !MISMATCHING REMOVE, tried ForEach got Type:If Position:0x076! */
		}				
		return none;
		return;
		@NULL
		Item
		Item
		@NULL
	}/* !MISMATCHING REMOVE, tried ForEach got Type:If Position:0x00B! */
}

function editorDisplayString(out string S)
{
	S = __NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__(__NFUN_112__("Deal ", propertyDisplayString('DamageAmount')), " points of "), string(GetEnum(Enum'Engine.DamageStimuliSet.DamageStimulusType', int(DamageType)))), " damage to "), propertyDisplayString('Target'));
	return;
	@NULL
	Item
	Item
	@NULL
}

defaultproperties
{
	DamageeClass=Class'ShockGame.ShockPawn'
	DamageAmount=100.0000000
	DamageChance=1.0000000
	DamageType=8
	actionDisplayName="Deal Damage"
	actionHelp="Deals damage to target actors"
	Category="Actor"
}