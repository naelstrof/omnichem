// dm_parser.d, doesn't actually parse dm files but does its best to parse specific chemistry files
// USAGE: ./dm_parser [Chemistry-Recipes.dm Reagents-Base.dm ...] > database.json

import std.stdio;
import std.file;
import std.json;
import std.regex;
import std.string;
import std.conv;
import std.algorithm;

JSONValue parse( string file, JSONValue j ) {
    if (!file.exists || !file.isFile ) {
        throw new Exception( "Failed to read file " ~ file );
    }
    string contents;
    try {
        contents = purgeComments( cast(string)readText( file ) );
    } catch( Exception e ) {
        throw new Exception( "Failed to read file " ~ file ~ ", probably due to it not being encoded in utf-8 or not being a text file. Re-encode it in utf-8 please." );
    }
    string[] lines = contents.splitLines();
    string curClass = "";
    JSONValue curObj;
    foreach( line ; lines ) {
        // Get how far we're tabbed out, then remove the tab characters.
        ulong level = line.countchars( "\t" );
        line = line.removechars( "\t" );
        // We use the tabbing level to determine what's being defined, kinda primative but effective.
        // Two tabs is a class name.
        if ( level == 2 ) {
            // Skip base class delcarations
            auto c = matchFirst( line, `^.+?[/].+? = .*?$` );
            if ( c.length() >= 1 ) {
                continue;
            }
            // Skip functions
            c = matchFirst( line, `^.*?\(` );
            if ( c.length() >= 1 ) {
                continue;
            }
            // classes that inherit have unique names, but need the inherited class name stripped.
            c = matchFirst( line, `[/](?P<classname>[^/]+?)$` );
            if ( c.length() >= 1 ) {
                curClass = c["classname"];
            } else {
                curClass = line;
            }
            curClass = curClass.strip();
            if (const(JSONValue)* test = curClass in j) {
            } else {
                j.object[curClass] = JSONValue(["class": curClass]);
            }
        // Three tabs are variables that belong to that class.
        } else if ( level == 3 && curClass != "" ) {
            // Now we start parsing;
            auto c = matchFirst( line, `^(?P<var>.+?) = (?P<value>.+?)$` );
            if ( c.length() <= 0 ) {
                continue;
            }
            string var = c["var"];
            var = chompPrefix( var, "\"" );
            var = chomp( var, "\"" );
            var = chompPrefix( var, "'" );
            var = chomp( var, "'" );
            var = strip( var );
            // Check if we're a list
            auto d = matchFirst( line, `^.+? = list\(` );
            if ( d.length >= 1 ) {
                // Check if we're associative
                auto e = matchFirst( line, `"(?P<var>.+?)"[ ]*?=[ ]*(?P<value>.+?)[, )]` );
                if ( e.length() >= 1 ) {
                    if (const(JSONValue)* test = var in j[curClass]) {
                        string str = var;
                        if ( var == "required_reagents" ) {
                            int num = 1;
                            while ( j[curClass].object.keys.canFind( str ) ) {
                                str = "required_reagents"~num.to!string;
                                num++;
                            }
                        } else {
                            stderr.writeln("Warning: duplicate variable " ~ var ~ " in class " ~ curClass);
                        }
                        j[curClass][str] = JSONValue( parseAssociativeList( line ) );
                    } else {
                        j[curClass].object[var] = JSONValue( parseAssociativeList( line ) );
                    }
                    continue;
                } else {
                    if (const(JSONValue)* test = var in j[curClass]) {
                        stderr.writeln("Warning: duplicate variable " ~ var ~ " in class " ~ curClass);
                        j[curClass][var] = JSONValue( parseList( line ) );
                    } else {
                        j[curClass].object[var] = JSONValue( parseList( line ) );
                    }
                    continue;
                }
            }
            string value = c["value"];
            value = chompPrefix( value, "\"" );
            value = chomp( value, "\"" );
            value = chompPrefix( value, "'" );
            value = chomp( value, "'" );
            value = strip( value );
            // Once we actually have an id, we stop using the classname.
            if ( var == "id" ) {
                if ( curClass != var ) {
                    JSONValue jj = j[curClass];
                    j.object.remove( curClass );
                    curClass = value;
                    if (const(JSONValue)* test = curClass in j) {
                        j.object[curClass] = mergeValues( j[curClass], jj );
                    } else {
                        j.object[curClass] = jj;
                    }
                }
            }
            if (const(JSONValue)* test = var in j[curClass]) {
                if ( var != "id" && var != "name" ) {
                    stderr.writeln("Warning: duplicate variable " ~ var ~ " in class " ~ curClass);
                }
                if ( value.isNumeric() ) {
                    j[curClass][var] = JSONValue( value.to!double );
                } else {
                    j[curClass][var] = JSONValue( value );
                }
            } else {
                if ( value.isNumeric() ) {
                    j[curClass][var] = JSONValue( value.to!double );
                } else {
                    j[curClass][var] = JSONValue( value );
                }
            }
        }
    }
    return j;
}

JSONValue mergeValues( JSONValue a, JSONValue b ) {
    JSONValue c = JSONValue(["":""]);
    c.object.remove("");
    foreach( key ; a.object.keys ) {
        c.object[key] = a.object[key];
    }
    foreach( key ; b.object.keys ) {
        // Don't override required_reagents
        if ( key == "required_reagents" ) {
            string str = key;
            int num = 1;
            while ( c.object.keys.canFind( str ) ) {
                str = "required_reagents"~num.to!string;
                num++;
            }
            c.object[str] = b.object[key];
        }
        c.object[key] = b.object[key];
    }
    return c;
}

double[string] parseAssociativeList( string line ) {
    double[string] array;
    foreach( c ; matchAll( line, `"(?P<var>.+?)"[ ]*?=[ ]*(?P<value>.+?)[, )]` ) ) {
        array[c["var"]] = c["value"].to!double;
    }
    return array;
}

string[] parseList( string line ) {
    string[] array;
    foreach( c ; matchAll( line, `"(?P<value>.+?)"` ) ) {
        array ~= c["value"];
    }
    return array;
}

// It's hard to parse shit that's covered in comments, so we purge them.
string purgeComments( string contents ) {
    bool removingLine = false;
    bool removingBlock = false;
    bool concatLines = false;
    dchar lastchar;
    string realcontents;
    foreach( c ; contents ) {
        if (concatLines && (c == ' ' || c == '\t') ) {
            lastchar = c;
            continue;
        }
        if ( c == '#' ) {
            removingLine = true;
        }
        if ( c == '\\' ) {
            lastchar = '\\';
            continue;
        }
        if ( c == '\n' ) {
            removingLine = false;
            if ( lastchar == '\\' ) {
                concatLines = true;
                lastchar = 'x';
                continue;
            } else {
                concatLines = false;
            }
            lastchar = c;
        }
        if ( c == '/' && lastchar == '*' ) {
            removingBlock = false;
            lastchar = 'x';
            continue;
        }
        if ( c == '*' && lastchar == '/' ) {
            removingBlock = true;
            lastchar = c;
            continue;
        }
        if ( c == '/' && lastchar == '/' ) {
            removingLine = true;
            lastchar = c;
            continue;
        }
        if ( removingLine || removingBlock ) {
            lastchar = c;
            continue;
        }
        if ( c == '/' ) {
            lastchar = '/';
            continue;
        }
        if ( lastchar == '\\' ) {
            realcontents ~= '\\';
        }
        if ( lastchar == '/' ) {
            // re-insert a slash if it wasn't actually a comment.
            realcontents ~= '/';
        }
        realcontents ~= c;
        lastchar = c;
    }
    return realcontents;
}

void main( string[] args ) {
    JSONValue j = JSONValue(["nothing":"nothing"]);
    j.object.remove("nothing");
    foreach( file ; args[ 1..$ ] ) {
        stderr.writeln("Parsing " ~ file ~ "...");
        j = parse( file, j );
    }
    j.object.remove("");
    j.object.remove("*");
    j = generateParents( j );
    writeln( j.toPrettyString() );
}

JSONValue generateParents( JSONValue j ) {
    foreach( str ; j.object.keys ) {
        if ( j[str].object.keys.canFind( "required_reagents" ) ) {
            foreach( rea ; j[str]["required_reagents"].object.keys ) {
                if ( j.object.keys.canFind( rea ) ) {
                    if ( j[rea].object.keys.canFind( "parents" ) ) {
                        j[rea]["parents"].array ~= JSONValue( str );
                    } else {
                        j[rea].object["parents"] = JSONValue( [str] );
                    }
                }
            }
        }
    }
    return j;
}
