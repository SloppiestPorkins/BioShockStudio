#include "ShockActionPlayMovie.h"

UShockActionPlayMovie::UShockActionPlayMovie()
{
	ActionClassName = TEXT("ActionPlayMovie");
}

void UShockActionPlayMovie::Configure(FName InMovie)
{
	MovieName = InMovie;
}

bool UShockActionPlayMovie::RequestPlay()
{
	if (MovieName.IsNone())
	{
		return false;
	}
	LastMovieName = MovieName;
	return true;
}
