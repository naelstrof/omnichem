var redraw, g, renderer;

function getRandomColor() {
    var letters = '3456789ABC'.split('');
    var color = '#';
    for (var i = 0; i < 6; i++ ) {
        color += letters[Math.floor(Math.random() * 9)];
    }
    return color;
}

$(document).ready(function() {
    g = new Graph();
    var render = function(r, node) {
        /* the default node drawing */
        var color = node.color;
        var ellipse = r.ellipse(0, 0, 30, 20).attr({fill: color, stroke: color, "stroke-width": 2});
        /* set DOM node ID */
        ellipse.node.id = node.label || node.id;
        shape = r.set().
            push(ellipse).
            push(r.text(0, 30, node.label || node.id));
        shape.translate( $("#content").width()/2, 300 );
        return shape;
    }
    $('.beaker-image').css( "background-color", $('color').text() );
    $('edge').each( function( index ) {
        var strings = $(this).text().split(",");
        if ( $(this).attr("color_d") == "#333" ) {
            g.addNode( strings[1], { color : getRandomColor(), render : render } );
        } else {
            g.addNode( strings[1], { color : $(this).attr("color_d"), render : render } );
        }
        if ( strings[0] != strings[1] ) {
            if ( $(this).attr("color_s") == "#333" ) {
                g.addNode( strings[0], { color : getRandomColor(), render : render } );
            } else {
                g.addNode( strings[0], { color : $(this).attr("color_s"), render : render } );
            }
            if ( $(this).attr("weight") != "1" ) {
                g.addEdge( strings[1], strings[0], { directed: true, label: $(this).attr("weight") } );
            } else {
                g.addEdge( strings[1], strings[0], { directed: true } );
            }
        }
    } );
    for(e in g.edges) {
        g.edges[e].style.stroke = g.edges[e].source.color;
        g.edges[e].style.fill = g.edges[e].source.color;
    }
    var layouter = new Graph.Layout.Spring(g);
    renderer = new Graph.Renderer.Raphael('canvas', g, $("#content").width(), 600 );
    redraw = function() {
        layouter.layout();
        renderer.width = $("#content").width()
        renderer.height = 600
        renderer.draw();
    };
    $(window).resize( redraw );
} );
