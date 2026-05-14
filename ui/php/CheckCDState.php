<?php
$file = '/tmp/cd_pending.json';
if (file_exists($file)) {
    echo file_get_contents($file);
} else {
    echo json_encode(["status" => "none"]);
}
?>
