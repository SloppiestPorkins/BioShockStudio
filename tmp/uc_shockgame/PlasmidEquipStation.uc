class PlasmidEquipStation extends ShockMachine
	native
	config(Machines)
	notplaceable
	hidecategories(DrawScale3D,DisplayAdvanced);

state Interacting
{	stop;
}

defaultproperties
{
	HackInfoName="PlasmidStationDefault"
	bCanBeHacked=false
	FriendlyName="Gene Bank"
	AnimWaitingStarted="intoWaiting"
	AnimWaitingLoop="WaitingLoop"
	AnimWaitingEnded="outofWaiting"
	AnimDormancyStarted="intoDormant"
	AnimDormancyLoop="DormantLoop"
	AnimDormancyEnded="outofDormant"
	DrawType=8
}