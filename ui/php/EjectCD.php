<?php
header('Content-Type: application/json');

$output = shell_exec('sudo /usr/local/bin/cd-forceEject.sh 2>&1');

echo json_encode([
    'status' => 'success',
    'message' => 'Force eject executed',
    'output' => $output
]);
?>