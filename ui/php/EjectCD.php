<?php
// 檔案位置：backend/EjectCD.php

// 指定您的自訂退片腳本絕對路徑 (請依實際存放位置修改)
$script_path = '/usr/local/bin/cd-autoeject.sh';

// 為了確保有權限執行 eject 與 mpc 指令，一樣透過 sudo 執行，並捕捉輸出以利除錯
$output = shell_exec("sudo " . $script_path . " 2>&1");

echo "Success: " . $output;
?>
