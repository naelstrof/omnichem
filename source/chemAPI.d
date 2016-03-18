import vibe.d;
import std.stdio;
import std.json;
import std.file;
import std.conv;
import std.array;
import std.algorithm;

struct Reagent {
    string name;
    string id;
}

interface IChemAPI {
    void index();
    void getReagent( string id );
}

class ChemAPI : IChemAPI {
    public JSONValue reagents;
    public Reagent[] sorted_reagents;
    private string generateEdges( string id ) {
        string html;
        if ( !reagents.object.keys.canFind(id) ) {
            return "";
        }
        JSONValue j = reagents[id];
        if ( !j.object.keys.canFind( "required_reagents" ) ) {
            return "";
        }
        foreach( str ; j["required_reagents"].object.keys ) {
            html ~= `<edge result="` ~ j["result_amount"].toString() ~ `" weight="` ~ j["required_reagents"][str].toString() ~ `" hidden>"`~ j["name"].str ~ `","` ~ reagents[str]["name"].str ~ `"</edge>`;
            html ~= generateEdges( str );
        }
        return html;
    }
    void getReagent( string id ) {
        string html = generateEdges( id );
        render!("get.dt", html );
    }
    void index() {
        render!("index.dt", sorted_reagents);
    }
    this( string file ) {
        string contents = readText( file );
        reagents = parseJSON( contents );
        foreach( r ; reagents.object ) {
            string name, id;
            if ( !r.object.keys.canFind( "id" ) ) {
                continue;
            }
            id = r["id"].str;
            if ( r.object.keys.canFind( "name" ) ) {
                name = r["name"].str;
            } else {
                name = id;
            }
            sorted_reagents ~= Reagent( name, id );
        }
        sort!("toUpper(a.name) < toUpper(b.name)", SwapStrategy.stable)( sorted_reagents );
    }
}
