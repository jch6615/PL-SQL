/*
  c_079001.get_folderはプロシージャではなくFUNCTIONである
*/
  PROCEDURE get_lost_folder_id (
      io_anken_kanren_folder_ids         IN OUT g_folder_ids
    , io_shinsei_kanren_folder_ids       IN OUT g_folder_ids
    , io_tuika_todokede_folder_ids       IN OUT g_folder_ids
  ) IS

    l_evacuate_anken_folder_ids g_folder_ids := g_folder_ids();

    l_evacuate_shinsei_folder_ids g_folder_ids := g_folder_ids();

    l_evacuate_tuika_folder_ids g_folder_ids := g_folder_ids();

    l_anken_id NUMBER;

    l_shinsei_id NUMBER;

    l_tuika_id NUMBER;

    l_first_access_token VARCHAR2(1000) := NULL;

    l_status_code VARCHAR2(10);
    
    BEGIN
    
    /*
      1-1 案件関連フォルダ
    */
    l_anken_id := io_anken_kanren_folder_ids.FIRST;

    FOR l_anken_id IN io_anken_kanren_folder_ids.FIRST .. io_anken_kanren_folder_ids.LAST
    LOOP
      DECLARE
      BEGIN
        IF l_anken_id = io_anken_kanren_folder_ids.FIRST THEN

          c_079001.get_folder(in_folder_id => io_anken_kanren_folder_ids(l_anken_id), io_access_token => l_first_access_token);

        ELSE

          c_079001.get_folder(in_folder_id => io_anken_kanren_folder_ids(l_anken_id), io_access_token => l_first_access_token);

        END IF;

        EXCEPTION
        WHEN OTHERS THEN
        -- 1-1-2 HTTPレスポンスステータスコードが400（不正）の場合、存在を確認出来なかった「OCMフォルダID」の値を退避する
        --ステータスコードの取得
          l_status_code := apex_web_service.g_status_code;

          IF l_status_code LIKE '4__' THEN
            
            l_evacuate_anken_folder_ids.EXTEND;

            l_evacuate_anken_folder_ids(l_evacuate_anken_folder_ids.LAST) := io_anken_kanren_folder_ids(l_anken_id);

          END IF;
      END;

    END LOOP;

    /*
      1-2 申請関連フォルダ
    */
    l_shinsei_id := io_shinsei_kanren_folder_ids.FIRST;

    FOR l_shinsei_id IN io_shinsei_kanren_folder_ids.FIRST .. io_shinsei_kanren_folder_ids.LAST
    LOOP
      DECLARE
      BEGIN

        c_079001.get_folder(in_folder_id => io_shinsei_kanren_folder_ids(l_shinsei_id), io_access_token => l_first_access_token);
      
        EXCEPTION
        WHEN OTHERS THEN
        -- 1-2-2 HTTPレスポンスステータスコードが400（不正）の場合、存在を確認出来なかった「OCMフォルダID」の値を退避する
        --ステータスコードの取得
        l_status_code := apex_web_service.g_status_code;

        IF l_status_code LIKE '4__' THEN
      
          l_evacuate_shinsei_folder_ids.EXTEND;

          l_evacuate_shinsei_folder_ids(l_evacuate_shinsei_folder_ids.LAST) := io_shinsei_kanren_folder_ids(l_shinsei_id);

        END IF;

      END;
    END LOOP;

    /*
      1-3 追加届出関連フォルダ
    */
    l_tuika_id := io_tuika_todokede_folder_ids.FIRST;

    FOR l_tuika_id IN io_tuika_todokede_folder_ids.FIRST .. io_tuika_todokede_folder_ids.LAST
    LOOP
      DECLARE
      BEGIN

        c_079001.get_folder(in_folder_id => io_tuika_todokede_folder_ids(l_tuika_id), io_access_token => l_first_access_token);

        EXCEPTION
        WHEN OTHERS THEN
        -- 1-3-2 HTTPレスポンスステータスコードが400（不正）の場合、存在を確認出来なかった「OCMフォルダID」の値を退避する
        --ステータスコードの取得
        l_status_code := apex_web_service.g_status_code;

        IF l_status_code LIKE '4__' THEN
      
          l_evacuate_tuika_folder_ids.EXTEND;

          l_evacuate_tuika_folder_ids(l_evacuate_tuika_folder_ids.LAST) := io_tuika_todokede_folder_ids(l_tuika_id);

        END IF;

      END;
    END LOOP;

    /*
      2-1 ~ 2-3 退避した「OCMフォルダID」をパラメータに設定する
    */ 
    io_anken_kanren_folder_ids := l_evacuate_anken_folder_ids;

    io_shinsei_kanren_folder_ids := l_evacuate_shinsei_folder_ids;

    io_tuika_todokede_folder_ids := l_evacuate_tuika_folder_ids;

    /*
      3-1 例外処理 - エラーログを出力
    */
    -- TODO 「119001_ログ出力」のアプリケーションログ出力を呼び出す

  END get_lost_folder_id;