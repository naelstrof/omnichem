import vibe.d;
import chemAPI;
import std.stdio;

shared static this()
{
    auto router = new URLRouter;
    router.registerWebInterface(new ChemAPI("recipes.json"));
    router.get( "*", serveStaticFiles("public/") );

    auto settings = new HTTPServerSettings;
    settings.port = 8080;

	writeln( "OMNICHEM is now running, open http://localhost:8080 in a browser!" );
    listenHTTP( settings, router );
}
