class ResearchStation extends ShockMachine
	native
	config(Machines)
	notplaceable
	hidecategories(DrawScale3D,DisplayAdvanced);

var private config localized string UsedFeedbackTextNoPhotos;

state Waiting
{	stop;
}

state Interacting
{
	protected latent function BeginInteracting()
	{
		return;
	}
	stop;
}

defaultproperties
{
	HackInfoName="ResearchStationDefault"
	FriendlyName="Research Station"
}