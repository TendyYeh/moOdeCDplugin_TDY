(function() {
    $(document).ready(function() {
        // 1. 注入專屬的 CSS (解決寬度擠壓與動畫失效問題)
        if ($('#eject-btn-style').length === 0) {
            var css = '<style id="eject-btn-style">' +
                /* 【解決寬度溢出】稍微縮小所有播放按鈕的左右留白，讓 5 個按鈕能平分原本 4 個的空間 */
                '#playbtns .btn-group .btn { padding-left: 11px !important; padding-right: 11px !important; } ' +

                /* 確保退片按鈕有滑順的動畫過場 (!important 突破系統限制) */
                '#btn-cd-eject { transition: transform 0.1s ease-in-out, opacity 0.3s ease-in-out !important; } ' +

                /* 【解決動畫失效】強制觸發點擊縮小特效，同時支援 :active 偽類與 .active Class */
                '#btn-cd-eject:active:not([disabled]), #btn-cd-eject.active:not([disabled]) { transform: scale(0.85) !important; }' +
                '</style>';
            $('head').append(css);
        }

        // 2. 動態注入退片按鈕 (保持乾淨的 Class 繼承)
        var targetGroup = $('#playbtns .btn-group');
        if (targetGroup.length > 0 && $('#btn-cd-eject').length === 0) {
            var ejectBtnHtml = '<button aria-label="Eject CD" id="btn-cd-eject" class="btn btn-cmd" disabled style="opacity: 0.3;"><i class="fa-solid fa-sharp fa-eject"></i></button>';
            targetGroup.append(ejectBtnHtml);
        }

        // 3. 【彌補系統 JS 綁定】使用事件委派 (Event Delegation) 模擬原生的點擊與觸控回饋
        $(document)
            .on('mousedown touchstart', '#btn-cd-eject:not([disabled])', function() {
                // 滑鼠按下或手指碰到時，加上 active Class 觸發縮小動畫
                $(this).addClass('active');
            })
            .on('mouseup mouseleave touchend', '#btn-cd-eject', function() {
                // 滑鼠放開或手指離開時，移除 active Class 恢復原狀
                $(this).removeClass('active');
            });

        // 4. 狀態監聽：判斷是否正在播放 CD
        var wasPlayingCD = false;
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
                    wasPlayingCD = false;
                }
            }
        }, 1000);

        // 5. 綁定實質的退片呼叫
        $(document).on('click', '#btn-cd-eject', function(e) {
            e.preventDefault();
            if ($(this).prop('disabled')) return; // 雙重防呆，非 CD 模式不動作

            $.post('/command/EjectCD.php', function(data) {
                console.log('[CD-Eject] Eject command executed:', data);
            });
        });
    });
})();