$(document).ready(function() {
    // Front-end state lock
    let pendingCDSignature = "";

    // Step 1: Load external HTML and Append to Body
    $.get('/templates/cd-import-modal.html', function(html) {
        $('body').append(html);
        bindEvents(); // Bind events after HTML is loaded
    });

    function showCustomModal() {
        $('#cd-import-backdrop').fadeIn(200);
        $('#cd-import-modal').fadeIn(200);
    }

    function hideCustomModal() {
        $('#cd-import-backdrop').fadeOut(200);
        $('#cd-import-modal').fadeOut(200);
    }

    // Step 2: 安全的遞迴輪詢機制 (Safe Recursive Polling)
    function checkCDState() {
        // 如果彈出視窗已經在畫面上，代表使用者正在操作，這時候不需要頻繁檢查。
        // 我們讓它休息 10 秒鐘後再來檢查，節省系統資源。
        if ($('#cd-import-modal').is(':visible')) {
            setTimeout(checkCDState, 10000);
            return;
        }

        // 使用 $.ajax 取代 $.get，這讓我們可以設定 timeout 與 cache 控制
        $.ajax({
            url: '/command/CheckCDState.php',
            type: 'GET',
            cache: false, // 強制瀏覽器不要使用快取，確保拿到最新狀態
            timeout: 2000, // 設定 2 秒超時，如果 PHP 卡住，2 秒後會自動放棄，不會死等
            success: function(data) {
                try {
                    let info = JSON.parse(data);
                    if (info.status === "pending") {
                        let currentSignature = info.artist + "-" + info.album;

                        // 確保這張 CD 尚未被處理過
                        if (currentSignature !== pendingCDSignature) {
                            $('#cd-modal-cover').attr('src', info.cover + '?t=' + new Date().getTime());
                            $('#cd-modal-artist').val(info.artist);
                            $('#cd-modal-album').val(info.album);

                            showCustomModal();
                        }
                    }
                } catch (e) {}
            },
            complete: function() {
                // 核心防呆機制：
                // 無論 success (成功) 或是 fail (失敗/超時)，都會進入 complete。
                // 我們規定：在「這一次的請求確定結束」之後，才開始倒數 3 秒發出下一次請求。
                // 這樣絕對不會發生請求重疊塞車的問題。
                setTimeout(checkCDState, 3000);
            }
        });
    }

    // 呼叫函數，啟動輪詢引擎
    checkCDState();

    function bindEvents() {
        // Search toggle
        $('#btn-manual-toggle').on('click', function() {
            $('#manual-search-box').slideToggle();
        });

        // Confirm & Import
        $('#btn-confirm-import').on('click', function() {
            let finalData = {
                confirm: true,
                artist: $('#cd-modal-artist').val(),
                album: $('#cd-modal-album').val()
            };
            pendingCDSignature = finalData.artist + "-" + finalData.album;
            $(this).text('Importing...').prop('disabled', true);

            $.ajax({
                url: '/command/ConfirmCDImport.php',
                type: 'POST',
                data: JSON.stringify(finalData),
                contentType: 'application/json',
                success: function() {
                    hideCustomModal();
                    $('#btn-confirm-import').html('<i class="fa fa-play"></i> Import').prop('disabled', false);
                    if (typeof GUI !== 'undefined') setTimeout(() => GUI.updateUI(), 1000);
                }
            });
        });

        // Eject & Cancel
        $('#btn-eject-cancel').on('click', function() {
            pendingCDSignature = $('#cd-modal-artist').val() + "-" + $('#cd-modal-album').val();
            $.post('/command/EjectCD.php');
            $.ajax({
                url: '/command/ConfirmCDImport.php',
                type: 'POST',
                data: JSON.stringify({ confirm: false }),
                contentType: 'application/json',
                success: function() { hideCustomModal(); }
            });
        });
    }
});