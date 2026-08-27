class AnimNotify_SetAmmoVisible extends AnimNotify_Scripted
	native
	editinlinenew
	collapsecategories
	hidecategories(Object);

var bool Show;

function Notify(Actor Owner, int AnimationHandle, float Time)
{
	log('Weapons', 4, __NFUN_112__(__NFUN_112__(__NFUN_112__(string(self), "::Notify( "), string(Owner)), " )"));
	assert(Owner.__NFUN_303__('Weapon'));
	// End:0x80
	if(Show)
	{
		Weapon(Owner).ShowAmmoModel();
		goto J0xA0;
		Weapon(Owner).HideAmmoModel();
	}
	return;
	@NULL
	Item
	stop;
	default.@NULL
}
