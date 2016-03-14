$('#search').keyup( function() {
    var valThis = $(this).val();
    $('tbody>tr').each(function(){
        var text = $(this).text().toLowerCase();
        (text.indexOf(valThis) != -1) ? $(this).show() : $(this).hide();         
    });
});
