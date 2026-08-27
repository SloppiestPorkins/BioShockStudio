class AnimNotify_ShowGrenade extends AnimNotify_Scripted
	editinlinenew
	collapsecategories
	hidecategories(Object);

function Notify(Actor Owner, int AnimationHandle, float Time)
{
	local Grenadier Grenadier;

	Grenadier = Grenadier(Owner);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x70
	/*@Error*/
	Grenadier(Owner).ShowGrenade();
	return;
	@NULL
	CommanderAction
	stop;
	default.@NULL
}
