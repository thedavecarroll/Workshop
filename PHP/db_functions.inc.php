<?php
//  ----------------------------------------------------------------------------
$db_insert_rows = 0;
$db_update_rows = 0;
$db_select_all  = "SELECT * FROM $mysql_table";

function db_connect() {
    global $db_host, $db_user, $db_pass, $db_database;

    $db_link = mysql_connect($db_host, $db_user, $db_pass)
        or die(mysql_errno($db_link) . ": " . mysql_error($db_link). "\n");

    $db_set = mysql_select_db($db_database, $db_link)
        or die(mysql_errno($db_link) . ": " . mysql_error($db_link). "\n");

    return($db_link);
}

function db_do_query($db_query) {
    global $db_num_rows, $item, $key;
    $db_link = db_connect();
    $db_num_rows = 0;

    $result = mysql_query($db_query)
        or die(mysql_errno($db_link) . ": " . mysql_error($db_link). "\n");

    $db_num_rows = mysql_affected_rows();
    return($result);
    mysql_free_result($result);
    mysql_close($db_link);
}

function db_return_all($db_query) {
    $result = db_do_query($db_query);
    $recordset = array();
    $r = 0;
    while($row = mysql_fetch_assoc($result)){
        $arr_row = array();
        $c = 0;
        while ($c < mysql_num_fields($result)) {
            $col = mysql_fetch_field($result, $c);
            $arr_row[$col -> name] = $row[$col -> name];
            $c++;
            }
        $recordset[$r] = $arr_row;
        $r++;
        }

    return($recordset);
    mysql_free_result($result);
    mysql_close($db_link);
}

function db_search($item, $key, $results) {
    global $db_table, $db_insert_rows, $db_update_rows;
    $db_link = db_connect();

    if (array_key_exists($key, $results)) {
        $db_update_query = db_update();
        $result = db_do_query($db_update_query);
        $db_update_rows += $db_num_rows;
    }else{
        $db_insert_query = db_insert();
        $result = db_do_query($db_insert_query);
        $db_insert_rows += $db_num_rows;
    }
} // end function

// initialize mysql database
function db_initialize($item, $key) {
    $db_link = db_connect();

    $db_insert_query = db_insert()
    $result = mysql_query($db_insert_query);
    if (!$result) {
        die(mysql_errno($db_link) . ": " . mysql_error($db_link). "\n");
    }
    $db_insert_rows += mysql_affected_rows();

} //end function

//  determine if a table is empty, return record count or 0
function db_rcount($result) {
    if (is_array($result)) {
        $rcount = count($result);
    }else{
        $rcount = 0 ;
    }
    return($rcount);
}

?>
