$(document).ready(function() 
    { 
        $("#students").tablesorter( {sortList: [[2,0]]} ); 
        $("#missing-assignments").tablesorter( {sortList: [[3,1]]} ); 
        $("#completed-assignments").tablesorter( {sortList: [[2,1]]} ); 
    } 
); 
