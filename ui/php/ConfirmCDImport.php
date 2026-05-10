<?php
// /var/www/command/ConfirmCDImport.php
$postData = json_decode(file_get_contents('php://input'), true);

if ($postData) {
    $pendingFile = '/tmp/cd_pending.json';

    if (isset($postData['confirm']) && $postData['confirm'] == true) {
        if (file_exists($pendingFile)) {
            $pendingData = json_decode(file_get_contents($pendingFile), true);
            
            // 使用者手動修改的資訊
            $pendingData['artist'] = $postData['artist'];
            $pendingData['album'] = $postData['album'];
            
            file_put_contents('/tmp/cd_confirmed.json', json_encode($pendingData, JSON_UNESCAPED_UNICODE));
            
            // 呼叫 Python 執行 MPD 注入
            shell_exec('sudo /usr/local/bin/cd_mpd_inject.py > /dev/null 2>&1 &');
            
            // 刪除待處理檔案
            unlink($pendingFile);
            echo json_encode(["success" => true]);
        }
    } else {
        // 如果是取消/退片，單純刪除檔案
        if (file_exists($pendingFile)) {
            unlink($pendingFile);
        }
        echo json_encode(["success" => true, "action" => "cancelled"]);
    }
}
?>