<?php
header('Content-Type: application/json');

// 呼叫我們剛剛建立的「一次性退片腳本」
$output = shell_exec('sudo /usr/local/bin/cd-forceEject.sh 2>&1');

echo json_encode([
    'status' => 'success',
    'message' => 'Force eject executed',
    'output' => $output
]);
?>