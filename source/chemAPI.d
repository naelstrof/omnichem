import vibe.d;
import std.stdio;
import std.json;
import std.file;
import std.conv;
import std.array;
import std.algorithm;

class Reagent {
    string id;
    string name;
    int[string] required_reagents;
    int required_temperature;
    int result_amount;
}

interface IChemAPI {
    void index();
    void getReagent( string id );
}

class ChemAPI : IChemAPI {
    // For fast access
    public Reagent[string] reagents;
    // For sorted
    public Reagent[] sorted_reagents;
    void getReagent( string id ) {
        render!("get.dt", id, reagents);
    }
    void index() {
        render!("index.dt", sorted_reagents);
    }
    this( string file ) {
        string contents = readText( file );
        JSONValue stuff = parseJSON( contents );
        foreach( size_t i, JSONValue j ; stuff["reagents"] ) {
            Reagent r = new Reagent();
            r.name = j["name"].str;
            r.id = j["id"].str;
            JSONValue[string] array = j["required_reagents"].object;
            foreach( str ; array.byKey ) {
                r.required_reagents[str] = array[str].integer.to!int;
            }
            if ( auto test = "required_temperature" in j ) {
                if ( test == null ) {
                    r.required_temperature = 0;
                } else {
                    r.required_temperature = test.integer.to!int;
                }
            }
            if ( auto test = "result_amount" in j ) {
                if ( test == null ) {
                    r.result_amount = 1;
                } else {
                    r.result_amount = test.integer.to!int;
                }
            }
            reagents[r.id] = r;
        }
        // Sort the reagents
        Reagent[] sorted = reagents.values;
        sort!("toUpper(a.name) < toUpper(b.name)", SwapStrategy.stable)( sorted );
        foreach( r ; sorted ) {
            sorted_reagents ~= r;
        }
    }
}
