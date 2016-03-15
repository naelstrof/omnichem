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
    /*private int getDepth( Reagent[string] reagents, Reagent cur, int curDepth = 0 ) {
        int depth = curDepth;
        int deepestDepth = depth;
        foreach( r ; cur.required_reagents.keys ) {
            int temp = getDepth( reagents, reagents[r], depth+1 );
            if ( temp > deepestDepth ) {
                deepestDepth = temp;
            }
        }
        return deepestDepth;
    }
    private int getWidth( Reagent[string] reagents, Reagent cur ) {
        int depth = getDepth( reagents, cur );
        int greatestWidth = 0;
        for( int i = 0 ; i < depth; i++ ) {
            greatestWidth = max( cast(int)getLevel( reagents, cur, depth ).length, greatestWidth );
        }
        return greatestWidth;
    }
    private string[] getLevel( Reagent[string] reagents, Reagent top, int level ) {
        string[] cur = [ top.id ];
        int curLevel = 0;
        while( curLevel != level ) {
            string[] temp;
            foreach( str ; cur ) {
                temp ~= reagents[str].required_reagents.keys;
            }
            cur = temp;
            curLevel++;
        }
        return cur;
    }
    string generateColumns( Reagent[string] reagents, Reagent cur, int fillWidth ) {
        string html = "";
        if ( cur.required_reagents.length <= 0 ) {
            return html;
        }
        int split = cast(int)fillWidth / cast(int)cur.required_reagents.length;
        foreach( r ; cur.required_reagents.keys ) {
            html ~= `<td colspan="` ~ split.to!string ~ `">` ~ reagents[r].name ~ `</td>`;
        }
        int splitrem = cast(int)fillWidth % cast(int)cur.required_reagents.length;
        if ( splitrem > 0 ) {
            html ~= `<td colspan="` ~ splitrem.to!string ~ `"></td>`;
        }
        return html;
    }
    string generateRow( Reagent[string] reagents, string[] list, int width ) {
        string html = `<tr>`;
        foreach( str ; list ) {
            html ~= generateColumns( reagents, reagents[str], cast(int)width/cast(int)list.length );
        }
        int splitrem = cast(int)width % cast(int)list.length;
        if ( splitrem > 0 ) {
            html ~= `<td colspan="` ~ splitrem.to!string ~ `"></td>`;
        }
        html ~= `</tr>`;
        return html;
    }
    string generateDependencyGraph( Reagent[string] reagents, Reagent top ) {
		int depth = getDepth( reagents, top );
		int width = getWidth( reagents, top );
		string html = `<table class="table table-striped table-bordered"><tbody>`;
		html ~= `<tr><td colspan="`~width.to!string~`">` ~ top.name ~ `</td></tr>`;
        for( int i = 0 ; i < depth; i++ ) {
            html ~= generateRow( reagents, getLevel( reagents, top, i ), width );
        }
        return html;
    } */
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
    private string generateEdges( Reagent top ) {
        string html;
        foreach( str ; top.required_reagents.keys ) {
            if( !reagents.keys.canFind(str) ) {
                html ~= `<edge hidden>"`~ top.name ~ `","` ~ str ~ `"</edge>`;
            } else {
                html ~= `<edge hidden>"`~ top.name ~ `","` ~ reagents[str].name ~ `"</edge>`;
				html ~= generateEdges( reagents[str] );
            }
        }
        return html;
    }
    void getReagent( string id ) {
        string html = generateEdges( reagents[id] );
        render!("get.dt", html );
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
            if ( auto test = "required_reagents" in j ) {
                if ( test != null ) {
                    const JSONValue[string] array = test.object;
                    foreach( str ; array.byKey ) {
                        r.required_reagents[str] = array[str].integer.to!int;
                    }
                }
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
