var redraw, g, renderer;

function getRandomColor() {
    var letters = '0123456789ABCDEF'.split('');
    var color = '#';
    for (var i = 0; i < 6; i++ ) {
        color += letters[Math.floor(Math.random() * 16)];
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
        return shape;
    }
    $('edge').each( function( index ) {
        var strings = $(this).text().split(",");
        g.addNode( strings[1], { color : getRandomColor(), render : render } );
        g.addNode( strings[0], { color : getRandomColor(), render : render } );
        g.addEdge( strings[1], strings[0], { directed: true } );
    } );
    for(e in g.edges) {
        g.edges[e].style.stroke = g.edges[e].source.color;
        g.edges[e].style.fill = g.edges[e].source.color;
    }
    var layouter = new Graph.Layout.Spring(g);
    renderer = new Graph.Renderer.Raphael('canvas', g, $("#content").width(), $("#content").height() );
    redraw = function() {
        layouter.layout();
        renderer.width = $("#content").width()
        renderer.height = $("#content").height()
        renderer.draw();
    };
    $(window).resize( redraw );
} );
