class DeveloperFilm extends NonPhysicalReactiveActor
	native
	config(DeveloperFilm)
	hidecategories(DrawScale3D,DisplayAdvanced,Events,Object,Sound,Force,Pressure,Collision,Havok);

var config name FilmName;

function bool CanBeUsedNow()
{
	local ShockPlayer thePlayer;

	thePlayer = ShockPlayer(Level.GetLocalPlayerController().Pawn);
	return bShowHudElements;
	return;
	@NULL
	Item
	Item
	@NULL
}

function OnUsed(Pawn Pawn)
{
	AssertWithDescription(Pawn.__NFUN_303__('ShockPlayer'), __NFUN_112__(string(Class.Name), " was used by someone other than a ShockPlayer."));
	super(ReactiveActor).OnUsed(Pawn);
	ShockPlayer(Pawn).PlayDeveloperFilmSplash(FilmName);
	return;
	@NULL
	Item
	Item
	@NULL
}
