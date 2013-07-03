
$(document).ready(function() 
    { 
        $("#assignments").tablesorter( {sortList: [[2,1]]} ); 
        $("#completed-students").tablesorter( {sortList: [[2,0]]} ); 
        $("#missing-students").tablesorter( {sortList: [[0,0]]}  ); 
    } 
); 
