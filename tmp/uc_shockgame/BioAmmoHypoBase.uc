class BioAmmoHypoBase extends Hypo
	native
	config(Inventory);

var config localized string AtFullEveMessage;

function FinishedUsing(ShockPlayer User)
{
	//native.User;	
	@NULL
}

defaultproperties
{
	AtFullEveMessage="Eve Already Full"
}