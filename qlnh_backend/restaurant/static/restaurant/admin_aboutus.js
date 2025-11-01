;(function(){
    function toggleImageUpload(){
        var ctRaw = document.getElementById('id_content_type_raw');
        var ctSelect = document.getElementById('id_content_type');
        var ctVal = '';
        if(ctRaw && ctRaw.value){
            ctVal = ctRaw.value.trim().toLowerCase();
        } else if(ctSelect && ctSelect.value){
            ctVal = ctSelect.value.trim().toLowerCase();
        }

        var uploadRow = document.querySelector('.form-row.field-image_upload');
        if(!uploadRow){
            var upload = document.getElementById('id_image_upload');
            if(upload){
                uploadRow = upload.closest('.form-row');
            }
        }
        if(!uploadRow) return;

        if(ctVal === 'image'){
            uploadRow.style.display = '';
        } else {
            uploadRow.style.display = 'none';
        }
    }

    document.addEventListener('DOMContentLoaded', function(){
        toggleImageUpload();
        var ctSelect = document.getElementById('id_content_type');
        if(ctSelect) ctSelect.addEventListener('change', toggleImageUpload);
        var ctRaw = document.getElementById('id_content_type_raw');
        if(ctRaw) ctRaw.addEventListener('change', toggleImageUpload);
    });
    
    // JSON editor helpers (for content_type == 'json')
    function setupJsonEditor(){
        var ctRaw = document.getElementById('id_content_type_raw');
        var ctSelect = document.getElementById('id_content_type');
        var ctVal = '';
        if(ctRaw && ctRaw.value){
            ctVal = ctRaw.value.trim().toLowerCase();
        } else if(ctSelect && ctSelect.value){
            ctVal = ctSelect.value.trim().toLowerCase();
        }

        var textarea = document.getElementById('id_noi_dung');
        if(!textarea) return;

        // find existing control area or create one
        var controlId = 'aboutus-json-controls';
        var existing = document.getElementById(controlId);
        if(!existing){
            existing = document.createElement('div');
            existing.id = controlId;
            existing.style.marginBottom = '8px';
            textarea.parentNode.insertBefore(existing, textarea);
        }

        // Clear previous controls
        existing.innerHTML = '';

        if(ctVal === 'json'){
            // style textarea for json editing (no Format/Validate/Clear buttons)
            textarea.style.fontFamily = 'monospace';
            textarea.style.whiteSpace = 'pre';
            textarea.rows = 20;
        }else{
            // revert textarea appearance if necessary
            textarea.style.fontFamily = '';
            textarea.style.whiteSpace = '';
            textarea.rows = 6;
        }
    }

    // Run JSON editor setup on load and when content_type changes
    document.addEventListener('DOMContentLoaded', function(){
        setupJsonEditor();
        var ctSelect = document.getElementById('id_content_type');
        if(ctSelect) ctSelect.addEventListener('change', setupJsonEditor);
        var ctRaw = document.getElementById('id_content_type_raw');
        if(ctRaw) ctRaw.addEventListener('change', setupJsonEditor);
    });

    // KEY/VALUE editor for non-technical admins: show top-level keys (readonly) and editable values
    function setupJsonKVEditor(){
        var ctRaw = document.getElementById('id_content_type_raw');
        var ctSelect = document.getElementById('id_content_type');
        var ctVal = '';
        if(ctRaw && ctRaw.value){
            ctVal = ctRaw.value.trim().toLowerCase();
        } else if(ctSelect && ctSelect.value){
            ctVal = ctSelect.value.trim().toLowerCase();
        }

        var textarea = document.getElementById('id_noi_dung');
        if(!textarea) return;

        var containerId = 'aboutus-json-kv-editor';
        var container = document.getElementById(containerId);
        if(!container){
            container = document.createElement('div');
            container.id = containerId;
            container.style.marginBottom = '8px';
            textarea.parentNode.insertBefore(container, textarea);
        }

        // If not json, remove container and show textarea
        if(ctVal !== 'json'){
            container.innerHTML = '';
            container.style.display = 'none';
            textarea.style.display = '';
            return;
        }

        container.style.display = '';

        // Try parse existing JSON
        var parsed = {};
        try{
            parsed = JSON.parse(textarea.value || '{}');
        }catch(err){
            // leave as empty object if invalid
            parsed = {};
        }

        // Only support top-level object for KV editor
        if(Object.prototype.toString.call(parsed) !== '[object Object]'){
            // fallback to textarea editor
            container.innerHTML = '<div style="color:#b00">JSON is not an object at top-level — edit raw JSON below.</div>';
            textarea.style.display = '';
            return;
        }

        // Build table of keys (readonly) and values (editable)
        container.innerHTML = '';
        var table = document.createElement('table');
        table.style.width = '100%';
        table.style.borderCollapse = 'collapse';

        Object.keys(parsed).forEach(function(key){
            var value = parsed[key];
            var tr = document.createElement('tr');
            tr.style.borderBottom = '1px solid #eee';

            var tdKey = document.createElement('td');
            tdKey.style.width = '30%';
            tdKey.style.padding = '6px';
            var inputKey = document.createElement('input');
            inputKey.type = 'text';
            inputKey.value = key;
            inputKey.readOnly = true;
            inputKey.style.width = '100%';
            // Make key visible in dark admin themes: dark background, light text
            inputKey.style.backgroundColor = '#2b2b2b';
            inputKey.style.color = '#ffffff';
            inputKey.style.border = '1px solid #444';
            inputKey.style.padding = '6px';
            inputKey.style.fontWeight = '600';
            tdKey.appendChild(inputKey);

            var tdValue = document.createElement('td');
            tdValue.style.padding = '6px';
            var inputVal = document.createElement('textarea');
            inputVal.className = 'aboutus-json-value';
            // if primitive, show raw; if object/array, show JSON string
            if(value !== null && (typeof value === 'object')){
                inputVal.value = JSON.stringify(value);
            } else {
                inputVal.value = value === null ? '' : String(value);
            }
            inputVal.style.width = '100%';
            inputVal.rows = 3;
            tdValue.appendChild(inputVal);

            tr.appendChild(tdKey);
            tr.appendChild(tdValue);
            table.appendChild(tr);
        });

        container.appendChild(table);

        // hide raw textarea (we'll populate it on submit)
        textarea.style.display = 'none';

        // serialize KV back to textarea
        function serializeKV(){
            var obj = {};
            var rows = container.querySelectorAll('tr');
            rows.forEach(function(row){
                var kEl = row.querySelector('input[type="text"]');
                if(!kEl) return;
                var k = kEl.value;
                var vEl = row.querySelector('.aboutus-json-value');
                var vText = vEl ? vEl.value.trim() : '';
                // Always save values as strings (or null if empty) to keep behavior simple for non-technical admins
                obj[k] = vText === '' ? null : vText;
            });
            var serialized = JSON.stringify(obj, null, 2);
            textarea.value = serialized;
            // Also ensure there's a real hidden input with name 'noi_dung' so Django receives it
            var hidden = document.querySelector('input[type="hidden"][name="noi_dung"]');
            if(!hidden){
                hidden = document.createElement('input');
                hidden.type = 'hidden';
                hidden.name = 'noi_dung';
                hidden.id = 'id_noi_dung_hidden';
                var form = textarea.closest('form') || document.querySelector('form');
                if(form) form.appendChild(hidden);
            }
            hidden.value = serialized;
            // ensure textarea is enabled so value is posted and writable
            try{
                textarea.disabled = false;
                textarea.removeAttribute && textarea.removeAttribute('disabled');
                textarea.readOnly = false;
                textarea.removeAttribute && textarea.removeAttribute('readonly');
            }catch(e){ /* ignore */ }
            // debugging: log serialized value
            try{ console.log('[aboutus] serialized noi_dung:', textarea.value); }catch(e){}
        }

        // Ensure on submit we serialize KV back to textarea; attach handlers once
        var adminForm = document.querySelector('form');
        if(adminForm && !adminForm._aboutus_kv_hook){
            adminForm._aboutus_kv_hook = true;
            adminForm.addEventListener('submit', function(e){
                serializeKV();
            });

            // Also attach to save buttons to serialize before any other admin JS
            var submitButtons = adminForm.querySelectorAll('input[type="submit"], button[type="submit"]');
            submitButtons.forEach(function(btn){
                btn.addEventListener('click', function(){
                    serializeKV();
                });
                // mousedown to catch some admin behaviors
                btn.addEventListener('mousedown', function(){
                    serializeKV();
                });
            });
        }
    }

    // wire up KV editor
    document.addEventListener('DOMContentLoaded', function(){
        setupJsonKVEditor();
        var ctSelect = document.getElementById('id_content_type');
        if(ctSelect) ctSelect.addEventListener('change', function(){ setupJsonKVEditor(); setupJsonEditor(); });
        var ctRaw = document.getElementById('id_content_type_raw');
        if(ctRaw) ctRaw.addEventListener('change', function(){ setupJsonKVEditor(); setupJsonEditor(); });
    });
})();
