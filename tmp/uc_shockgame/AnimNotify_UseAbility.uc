class AnimNotify_UseAbility extends AnimNotify_Scripted
	editinlinenew
	collapsecategories
	hidecategories(Object);

function Notify(Actor Owner, int AnimationHandle, float Time)
{
	log('Weapons', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(string(self), "::Notify( "), string(Owner)), " )"));
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x70
	/*@Error*/
	Hands(Owner).UseCurrentAbility();
	return;
	@NULL
	Item
	stop;
	default.@NULL
}
