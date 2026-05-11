(function() {
    $(document).ready(function() {
        // 1. 注入專屬的 CSS
        if ($('#eject-btn-style').length === 0) {
            var css = '<style id="eject-btn-style">' +
                '#playbtns .btn-group .btn { padding-left: 11px !important; padding-right: 11px !important; } ' +
                '#btn-cd-eject { transition: transform 0.1s ease-in-out, opacity 0.3s ease-in-out !important; } ' +
                '#btn-cd-eject:active:not([disabled]), #btn-cd-eject.active:not([disabled]) { transform: scale(0.85) !important; }' +
                '</style>';
            $('head').append(css);
        }

        // 2. 動態注入退片按鈕 (直接移除 disabled 與 opacity 限制，讓它預設就是亮的)
        var targetGroup = $('#playbtns .btn-group');
        if (targetGroup.length > 0 && $('#btn-cd-eject').length === 0) {
            var ejectBtnHtml = '<button aria-label="Eject CD" id="btn-cd-eject" class="btn btn-custom-eject"><i class="fa-solid fa-sharp fa-eject"></i></button>';
            targetGroup.append(ejectBtnHtml);
        }

        // 3. 綁定按鈕動畫與實質的退片呼叫
        $('#playbtns')
            .on('mousedown touchstart', '#btn-cd-eject:not([disabled])', function() {
                $(this).addClass('active');
            })
            .on('mouseup mouseleave touchend', '#btn-cd-eject', function() {
                $(this).removeClass('active');
            })
            .on('click', '#btn-cd-eject', function(e) {
                e.preventDefault();
                var $btn = $(this);
                
                // 防呆機制：如果已經在退片中 (被 disabled)，就不理會
                if ($btn.prop('disabled')) return;

                console.log('[CD-Eject] Eject command sent to server...');
                
                // 點擊後立刻將按鈕變暗並鎖定，防止使用者焦慮狂點
                $btn.prop('disabled', true).css('opacity', '0.3');

                $.ajax({
                    url: '/command/EjectCD.php',
                    type: 'POST',
                    timeout: 10000, // 給後端 10 秒的退片時間
                    success: function(data) {
                        console.log('[CD-Eject] Success:', data);
                    },
                    error: function(xhr, status, error) {
                        console.error('[CD-Eject] Failed:', status, error);
                    },
                    complete: function() {
                        // 確保 3 秒後，按鈕一定會恢復正常亮起，可以再次點擊
                        setTimeout(function() {
                            $btn.prop('disabled', false).css('opacity', '1');
                        }, 3000);
                    }
                });
            });
    });
})();