<?php
include_once('./common.php');
$VALUE = $_POST["value"];
putvar("difficulty", $VALUE);

$fpa = fopen('/var/www/html/difficulty.txt', 'w');
fwrite($fpa, "Difficulty set to: $VALUE");
fclose($fpa);

echo "Difficulty of share required before client submit set to $VALUE";
?>
