// 檔案位置：ui/js/inject-eject-btn.js

(function() {
    $(document).ready(function() {
        // 1. 動態注入退片按鈕
        // 確保不會重複注入，並與原生風格 (fa-solid fa-sharp) 保持一致
        if ($('#btn-cd-eject').length === 0) {
            var ejectBtnHtml = '<button aria-label="Eject CD" id="btn-cd-eject" class="btn btn-cmd" disabled style="opacity: 0.3;"><i class="fa-solid fa-sharp fa-play"></i></button>';
            $('#playbtns .btn-group').append(ejectBtnHtml);
        }

        // 2. 狀態監聽：判斷是否正在播放 CD
        // 每秒檢查一次 moOde 的全域狀態變數 GUI.state
        setInterval(function() {
            if (typeof GUI !== 'undefined' && GUI.state && GUI.state.file) {
                // 檢查檔名是否以 cdda:// 開頭 (代表正在播 CD)
                var isCDPlaying = GUI.state.file.startsWith('cdda://');
                
                if (isCDPlaying) {
                    // 啟用按鈕並恢復亮度
                    $('#btn-cd-eject').prop('disabled', false).css('opacity', '1');
                } else {
                    // 禁用按鈕並調暗
                    $('#btn-cd-eject').prop('disabled', true).css('opacity', '0.3');
                }
            }
        }, 1000);

        // 3. 綁定點擊事件
        $('#btn-cd-eject').on('click', function(e) {
            e.preventDefault();
            if ($(this).prop('disabled')) return; // 雙重防呆，非 CD 模式不動作
            
            // 加上輕微的點擊動畫反饋
            $(this).css('transform', 'scale(0.8)');
            setTimeout(() => $(this).css('transform', 'scale(1)'), 150);

            // 呼叫後端 PHP 執行退片指令
            $.post('/command/EjectCD.php', function(data) {
                console.log('Eject command executed:', data);
            });
        });
    });
})();