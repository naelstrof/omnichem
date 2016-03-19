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
            string color_s = "#333";
            if ( j.object.keys.canFind( "fluid_r" ) ) {
                color_s = format("#%02x%02x%02x", min(j["fluid_r"].integer,255), min(j["fluid_g"].integer,255), min(j["fluid_b"].integer,255) );
            }
            string color_d = "#333";
            if ( reagents[str].object.keys.canFind( "fluid_r" ) ) {
                color_d = format("#%02x%02x%02x", min(reagents[str]["fluid_r"].integer,255), min(reagents[str]["fluid_g"].integer,255), min(reagents[str]["fluid_b"].integer,255) );
            }
            string rname;
            if ( reagents[str].object.keys.canFind("name") ) {
                rname = reagents[str]["name"].str;
            } else {
                rname = reagents[str]["id"].str;
            }

            string bname;
            if ( j.object.keys.canFind("name") ) {
                bname = j["name"].str;
            } else {
                bname = j["id"].str;
            }
            string resulta;
            if ( j.object.keys.canFind( "result_amount" ) ) {
                resulta = j["result_amount"].toString();
            } else {
                resulta = "1";
            }
            html ~= `<edge color_s="` ~ color_s ~ `" color_d="` ~ color_d ~ `" result="` ~ resulta ~ `" weight="` ~ j["required_reagents"][str].toString() ~ `" hidden>"`~ bname ~ `","` ~ rname ~ `"</edge>`;
            html ~= generateEdges( str );
        }
        return html;
    }
    void getReagent( string id ) {
        string html = generateEdges( id );
        string name, description;
        string[] parents;
        string[] children;
        string color;
        if ( reagents.object.keys.canFind( id ) ) {
            if ( reagents[id].object.keys.canFind( "name" ) ) {
                name = reagents[id]["name"].str ~ " (" ~ id ~ ")";
            } else {
                name = id;
            }
            if ( reagents[id].object.keys.canFind( "description" ) ) {
                description = reagents[id]["description"].str;
            }
            if ( reagents[id].object.keys.canFind( "parents" ) ) {
                foreach( j ; reagents[id]["parents"].array ) {
                    string rname;
                    if ( reagents[j.str].object.keys.canFind("name") ) {
                        rname = reagents[j.str]["name"].str;
                    } else {
                        rname = reagents[j.str]["id"].str;
                    }
                    parents ~= `<a href="/reagent?id=` ~ reagents[j.str]["id"].str ~ `">` ~ rname ~ `</a>`;
                }
            }
            if ( parents.length <= 0 ) {
                parents ~= "None!";
            }
            if ( reagents[id].object.keys.canFind( "required_reagents" ) ) {
                foreach( j ; reagents[id]["required_reagents"].object.keys ) {
                    string rname;
                    if ( reagents[j].object.keys.canFind("name") ) {
                        rname = reagents[j]["name"].str;
                    } else {
                        rname = reagents[j]["id"].str;
                    }
                    children ~= `<a href="/reagent?id=` ~ reagents[j]["id"].str ~ `">` ~ rname ~ `</a>`;
                }
            }
            if ( children.length <= 0 ) {
                children ~= "None!";
            }
            if ( reagents[id].object.keys.canFind( "fluid_r" ) ) {
                color = format("#%02x%02x%02x", min(reagents[id]["fluid_r"].integer,255), min(reagents[id]["fluid_g"].integer,255), min(reagents[id]["fluid_b"].integer,255) );
            }
            if ( html == "" ) {
                string rname;
                if ( reagents[id].object.keys.canFind("name") ) {
                    rname = reagents[id]["name"].str;
                } else {
                    rname = reagents[id]["id"].str;
                }
                html = `<edge color_s="` ~ color ~ `" color_d="` ~ color ~ `" result="1" weight="1" hidden>"`~ rname ~ `","` ~ rname ~ `"</edge>`;
            }
        } else {
            name = "Unknown";
            description = "Unknown";
            parents = ["Unknown"];
            children = ["Unknown"];
            color = "#FFF";
        }
        render!("get.dt", html, name, description, parents, children, color );
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
