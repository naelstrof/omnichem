import vibe.d;
import chemAPI;
import std.json;

shared static this()
{
    auto router = new URLRouter;
    router.registerWebInterface(new ChemAPI("recipes.json"));
    router.get( "*", serveStaticFiles("public/") );

    auto settings = new HTTPServerSettings;
    settings.port = 8080;

    listenHTTP( settings, router );
}
