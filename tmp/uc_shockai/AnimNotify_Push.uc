class AnimNotify_Push extends AnimNotify_Scripted
	editinlinenew
	collapsecategories
	hidecategories(Object);

var name EffectEventName;
var bool bAIShouldTriggerEventOnPlayer;

function PopulateEffectEventNames(LevelInfo Level, out array<name> ResultArray)
{
	ResultArray[0] = default.EffectEventName;
	return;
	@NULL
	CommanderAction
}

function Notify(Actor Owner, int AnimationHandle, float Time)
{
	local ShockAI AI;
	local Actor Pushee;

	AI = ShockAI(Owner);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x1BC
	/*@Error*/
	Pushee = ShockAI(Owner).GetPusheeFromPush();
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x1BC
	/*@Error*/
	Owner.TriggerEffectEvent('PushedTargetMelee', Pushee);
	Pushee.TriggerEffectEvent('PushedByMelee', Owner);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x1BC
	/*@Error*/
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x18A
	/*@Error*/
	ShockAI(Owner).OnSpecialPushPlayer(ShockPlayer(Pushee));
	goto J0x1BC;
	ShockPlayer(Pushee).OnPushed(EffectEventName, Owner);
	return;
	@NULL
	CommanderAction
	stop;
	default.@NULL
}

defaultproperties
{
	EffectEventName="PushedBack"
}