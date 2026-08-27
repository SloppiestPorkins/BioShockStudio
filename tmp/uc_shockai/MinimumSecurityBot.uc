class MinimumSecurityBot extends SecurityBot
	abstract
	config(AI)
	hidecategories(DrawScale3D,DisplayAdvanced);

function DisableMovement()
{
	local BotShockGun BotShockWeapon;

	BotShockWeapon = BotShockGun(theWeapon);
	// End:0x43
	if(__NFUN_119__(BotShockWeapon, none))
	{
		BotShockWeapon.SetIsDisabled(true);
		super.DisableMovement();
		return;
		@NULL
		CommanderAction
		CommanderAction
	}
	@NULL
}

function EnableMovement()
{
	local BotShockGun BotShockWeapon;

	super.EnableMovement();
	BotShockWeapon = BotShockGun(theWeapon);
	/* Statement decompilation error: Index was out of range. Must be non-negative and less than the size of the collection. (Parameter 'index')
		
	*/

	// End:0x4D
	/*@Error*/
	BotShockWeapon.SetIsDisabled(false);
	return;
	@NULL
	CommanderAction
	CommanderAction
	@NULL
}
