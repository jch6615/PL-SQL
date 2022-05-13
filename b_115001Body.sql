create or replace PACKAGE BODY b_115001 AS

  /*
    変数(フォルダのID)
  */
  -- 申請プログラムファイルフォルダのフォルダID
  co_request_program_folder_id       CONSTANT VARCHAR2(100) := 'F45FA03FEA057B1738F55CFF250012DBD47E59472E21';
  -- 申請図書ファイルフォルダのフォルダID
  co_request_books_folder_id         CONSTANT VARCHAR2(100) := 'F456538CFC8E59BCF5728217BF8D1F63B15955BDE827';
  -- 構造計算書ファイルフォルダのフォルダID
  co_kozo_keisan_sho_folder_id       CONSTANT VARCHAR2(100) := 'F59A4585788F0D2DCEAD03B366EA7FAB2070AA2F7CB6';
  -- DMフォルダのフォルダID
  co_dm_temporary_folder_id          CONSTANT VARCHAR2(100) := 'F8ADF88BE4BFDF215CE3E3C887FBF0C4B345E3992329';
  -- INFOフォルダのフォルダID
  co_info_temporary_folder_id        CONSTANT VARCHAR2(100) := 'FF2671E20D7D4FDE71CD3E11ACD917D25C54BE9098E1';
  

  PROCEDURE file_maintenance_main IS
    
    -- 変数
    l_get_temporary_folder g_folderid_modifiedtime;

    l_get_delete_folder_id g_folder_ids;

    l_anken_folder_ids g_folder_ids := g_folder_ids();
    
    l_shinsei_folder_ids g_folder_ids := g_folder_ids();
    
    l_tuika_folder_ids g_folder_ids := g_folder_ids();

    l_delete_folder_count NUMBER := 0;

    l_count_delete_folder_id NUMBER;

    l_process_begin TIMESTAMP;

    l_process_end TIMESTAMP;

  BEGIN
    
    /*
     1 ログ出力用に処理開始時刻を取得し、保持する
    */
    l_process_begin := systimestamp;

    /*
      2 テンポラリフォルダの一覧を取得する
    */
    l_get_temporary_folder := get_temporary_folder;

    /*
      3 OCMから取得したテンポラリフォルダの一覧から前日日時以前であるフォルダのフォルダIDを抽出する
    */
    l_get_delete_folder_id := get_delete_folder_id(in_folder_items => l_get_temporary_folder);

    -- ログ出力用に削除対象のフォルダIDをカウントし、保持する
    l_count_delete_folder_id := l_get_delete_folder_id.COUNT;

    /*
      4 不要なテンポラリフォルダおよびファイルを削除する
    */
    delete_temporary_folder(
      in_folder_ids => l_get_delete_folder_id
    , out_delete_folder_count => l_delete_folder_count);

    /*
      5 存在確認の対象となるフォルダのフォルダIDを取得する
    */
    get_sonzai_check_folder_id(
      out_anken_kanren_folder_ids => l_anken_folder_ids
    , out_shinsei_kanren_folder_ids => l_shinsei_folder_ids
    , out_tuika_todokede_folder_ids => l_tuika_folder_ids);

    /*
      6 REST APIでOCMにフォルダ取得をリクエストして存在確認を行い、存在しなかったフォルダのフォルダIDを取得する
    */
    get_lost_folder_id(
      io_anken_kanren_folder_ids => l_anken_folder_ids
    , io_shinsei_kanren_folder_ids => l_shinsei_folder_ids
    , io_tuika_todokede_folder_ids => l_tuika_folder_ids);

    /*
      7 REST APIでOCMにフォルダ取得をリクエストして存在確認を行う
    */
    send_mail(
      in_anken_kanren_folder_ids => l_anken_folder_ids
    , in_shinsei_kanren_folder_ids => l_shinsei_folder_ids
    , in_tuika_todokede_folder_ids => l_tuika_folder_ids);

    /*
      8 ログ出力用に処理終了時刻を取得し、保持する
    */
    l_process_end := systimestamp;

    /*
      9 実行ログを出力する
    */
    -- TODO 「119001_ログ出力」のアプリケーションログ出力を呼び出す
    --  出力メッセージ: l_process_begin, l_process_end, l_count_delete_folder_id, l_delete_folder_count

    /*
      10 例外処理
    */
    -- TODO エラーログを出力する - 「119001_ログ出力」のアプリケーションログ出力を呼び出す

  END file_maintenance_main;
  

  FUNCTION get_temporary_folder RETURN g_folderid_modifiedtime IS
  
    -- 戻り値
    l_folder_info g_folderid_modifiedtime;

    -- アクセストークン
    l_first_access_token VARCHAR2(1000) := NULL;

    -- c_079001.get_folder_contentsから得た子アイテムの情報
    l_request_program_folder_id clob;
    l_request_books_folder_id clob;
    l_kozo_keisan_sho_folder_id clob;
    l_dm_temporary_folder_id clob;
    l_info_temporary_folder_id clob;

  BEGIN
    /*
      1-1 申請プログラムファイルフォルダの一覧取得
    */
    l_request_program_folder_id := c_079001.get_folder_contents(in_folder_id => co_request_program_folder_id, io_access_token => l_first_access_token);

    apex_json.parse(l_request_program_folder_id);
    
    IF apex_json.get_count('items') != 0 THEN
      FOR i IN 1..apex_json.get_count('items')
      LOOP
  
        l_folder_info(apex_json.get_varchar2('items[%d].id',i)) := apex_json.get_date('items[%d].modifiedTime', i);
  
      END LOOP;
    END IF;

    /*
      1-2 申請図書ファイルフォルダの一覧取得
    */
    l_request_books_folder_id := c_079001.get_folder_contents(in_folder_id => co_request_books_folder_id, io_access_token => l_first_access_token);

    apex_json.parse(l_request_books_folder_id);
    
    IF apex_json.get_count('items') != 0 THEN
      FOR i IN 1..apex_json.get_count('items')
      LOOP
  
        l_folder_info(apex_json.get_varchar2('items[%d].id',i)) := apex_json.get_date('items[%d].modifiedTime', i);
  
      END LOOP;
    END IF;

    /*
      1-3 構造計算書ファイルフォルダの一覧取得
    */
    l_kozo_keisan_sho_folder_id := c_079001.get_folder_contents(in_folder_id => co_kozo_keisan_sho_folder_id, io_access_token => l_first_access_token);

    apex_json.parse(l_kozo_keisan_sho_folder_id);

    IF apex_json.get_count('items') != 0 THEN
      FOR i IN 1..apex_json.get_count('items')
      LOOP
  
        l_folder_info(apex_json.get_varchar2('items[%d].id',i)) := apex_json.get_date('items[%d].modifiedTime', i);
  
      END LOOP;
    END IF;

    /*
      1-4 DMフォルダの一覧取得
    */
    l_dm_temporary_folder_id := c_079001.get_folder_contents(in_folder_id => co_dm_temporary_folder_id, io_access_token => l_first_access_token);

    apex_json.parse(l_dm_temporary_folder_id);

    IF apex_json.get_count('items') != 0 THEN
      FOR i IN 1..apex_json.get_count('items')
      LOOP
  
        l_folder_info(apex_json.get_varchar2('items[%d].id',i)) := apex_json.get_date('items[%d].modifiedTime', i);

      END LOOP;
    END IF;

    /*
      1-5 INFOフォルダの一覧取得
    */
    l_info_temporary_folder_id := c_079001.get_folder_contents(in_folder_id => co_info_temporary_folder_id, io_access_token => l_first_access_token);

    apex_json.parse(l_info_temporary_folder_id);

    IF apex_json.get_count('items') != 0 THEN
      FOR i IN 1..apex_json.get_count('items')
      LOOP
  
        l_folder_info(apex_json.get_varchar2('items[%d].id',i)) := apex_json.get_date('items[%d].modifiedTime', i);
  
      END LOOP;
    END IF;
    
    /*
      3-1 戻り値を返却 - フォルダID（id）と更新日付（modifiedTime）情報を戻り値として返却
    */
    RETURN l_folder_info;

    /*
      2-1 例外処理 - エラーログを出力
    */
    -- TODO 「119001_ログ出力」のアプリケーションログ出力を呼び出す


  END get_temporary_folder;


  
  FUNCTION get_delete_folder_id (
    in_folder_items IN g_folderid_modifiedtime
  ) RETURN g_folder_ids IS

    l_folder_id VARCHAR2(100);

    l_folderid_delelte g_folder_ids := g_folder_ids();

  BEGIN
    /*
      1-1 システム日付 ＞ 更新日付　を抽出条件に合致するフォルダIDを抽出
    */
    IF in_folder_items.COUNT != 0 THEN 
      -- 一番目のフォルダIDを変数に入れる
      l_folder_id := in_folder_items.FIRST;

      -- sysdateと更新日付を比較し戻り値(配列)に入れる
      WHILE l_folder_id IS NOT NULL
      LOOP
        IF sysdate > in_folder_items(l_folder_id) THEN 

          l_folderid_delelte.EXTEND;

          l_folderid_delelte(l_folderid_delelte.LAST) := l_folder_id;

          l_folder_id := in_folder_items.NEXT(l_folder_id);

        END IF;
      END LOOP;
    END IF;

    RETURN l_folderid_delelte;

    /*
      2-1 例外処理 - エラーログを出力
    */
    -- TODO 「119001_ログ出力」のアプリケーションログ出力を呼び出す

  END get_delete_folder_id;


  PROCEDURE delete_temporary_folder (
    in_folder_ids           IN g_folder_ids
  , out_delete_folder_count OUT NUMBER
  ) IS
  
    l_folder_id NUMBER;
  
    l_first_access_token VARCHAR2(1000) := NULL;
  
    l_delete_folder_count NUMBER :=0;

  BEGIN

    IF in_folder_ids.COUNT != 0 THEN

      l_folder_id := in_folder_ids.FIRST;

      -- フォルダID文繰り返す
      FOR l_folder_id IN in_folder_ids.FIRST .. in_folder_ids.LAST
      LOOP

          c_079001.delete_folder(in_delete_folder_id => in_folder_ids(l_folder_id), io_access_token => l_first_access_token);

          l_delete_folder_count := l_delete_folder_count + 1;

     END LOOP;
    END IF;

    out_delete_folder_count := l_delete_folder_count;

    /*
      2-1 例外処理 - エラーログを出力
    */
    -- TODO 「119001_ログ出力」のアプリケーションログ出力を呼び出す

  END delete_temporary_folder;


  PROCEDURE get_sonzai_check_folder_id (
      out_anken_kanren_folder_ids         OUT g_folder_ids
    , out_shinsei_kanren_folder_ids       OUT g_folder_ids
    , out_tuika_todokede_folder_ids       OUT g_folder_ids
  ) IS

    -- OUT変数用変数
    l_anken_folder_ids g_folder_ids := g_folder_ids();
    
    l_shinsei_folder_ids g_folder_ids := g_folder_ids();
    
    l_tuika_folder_ids g_folder_ids := g_folder_ids();
  
    -- フォルダID習得用カーソル
    CURSOR c_anken_kanren IS
      SELECT
        folder.ocm_folder_id AS folder_id
      FROM
        folder folder
        INNER JOIN project project ON folder.project_id = project.project_id
      WHERE
        folder.project_id IS NOT NULL
        AND folder.request_id IS NULL
        AND folder.additional_notification_id IS NULL;

    CURSOR c_shinsei_kanren IS
      SELECT
        folder.ocm_folder_id AS folder_id
      FROM
        folder folder
        INNER JOIN request request ON folder.request_id = request.request_id
      WHERE
        folder.request_id IS NOT NULL
        AND folder.project_id IS NULL
        AND folder.additional_notification_id IS NULL;

    CURSOR c_tuika_todokede IS
      SELECT
        folder.ocm_folder_id AS folder_id
      FROM
        folder folder
        INNER JOIN additional_notification add_noti ON folder.additional_notification_id = add_noti.additional_notification_id
      WHERE
        folder.additional_notification_id IS NOT NULL
        AND folder.project_id IS NULL
        AND folder.request_id IS NULL;

  BEGIN
    
    /*
      1-1 案件関連フォルダのOCMフォルダIDを取得する
    */
    FOR r_anken_kanren IN c_anken_kanren
    LOOP
      
      l_anken_folder_ids.EXTEND;

      l_anken_folder_ids(l_anken_folder_ids.LAST) := r_anken_kanren.folder_id;

    END LOOP;
    
    /*
      1-2 申請関連フォルダのOCMフォルダIDを取得する
    */
    FOR r_shinsei_kanren IN c_shinsei_kanren
    LOOP

      l_shinsei_folder_ids.EXTEND;

      l_shinsei_folder_ids(l_shinsei_folder_ids.LAST) := r_shinsei_kanren.folder_id;

    END LOOP;

    /*
      1-3 追加届出関連フォルダのOCMフォルダIDを取得する
    */
    FOR r_tuika_todokede IN c_tuika_todokede
    LOOP
      
      l_tuika_folder_ids.EXTEND;

      l_tuika_folder_ids(l_tuika_folder_ids.LAST) := r_tuika_todokede.folder_id;

    END LOOP;

    out_anken_kanren_folder_ids := l_anken_folder_ids;
    out_shinsei_kanren_folder_ids := l_shinsei_folder_ids;
    out_tuika_todokede_folder_ids := l_tuika_folder_ids;
    
    /*
      2-1 例外処理 - エラーログを出力
    */
    -- TODO 「119001_ログ出力」のアプリケーションログ出力を呼び出す

  END get_sonzai_check_folder_id;


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

          c_079001.get_folder(in_folder_id => io_anken_kanren_folder_ids(l_anken_id), io_access_token => l_first_access_token);

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


  PROCEDURE send_mail (
    in_anken_kanren_folder_ids         IN g_folder_ids
  , in_shinsei_kanren_folder_ids       IN g_folder_ids
  , in_tuika_todokede_folder_ids       IN g_folder_ids
  ) IS

    l_anken_folder_id NUMBER;
    l_shinsei_folder_id NUMBER;
    l_tuika_folder_id NUMBER;

    l_maker_customer_control_number request.maker_customer_control_number%TYPE;
    l_parent_receipt_number project.parent_receipt_number%TYPE;
    l_branch_name branch_name.branch_name%TYPE;
    l_folder_name folder_name.folder_name%TYPE;
    l_web_request_number request.web_request_number%TYPE;
    l_request_date request.request_date%TYPE;
    l_review_reciept_number review.receipt_number%TYPE;
    l_exam_reciept_number examination.receipt_number%TYPE;
    l_additional_notification_name additional_notification_name.additional_notification_name%TYPE;

    l_count_folder_ids NUMBER := 0;

    l_msg_text g_msg_text := g_msg_text();

    l_msg_text_body clob;

    l_msg_to setting.value%TYPE;

  BEGIN

    /*
      1-1 案件関連フォルダ情報取得
    */
    l_anken_folder_id := in_anken_kanren_folder_ids.FIRST;

    FOR l_anken_folder_id IN in_anken_kanren_folder_ids.FIRST .. in_anken_kanren_folder_ids.LAST
    LOOP
      SELECT
        request.maker_customer_control_number
      , project.parent_receipt_number
      , branch_name.branch_name
      , folder_name.folder_name
      INTO
        l_maker_customer_control_number
      , l_parent_receipt_number
      , l_branch_name
      , l_folder_name
      FROM
        folder folder
        INNER JOIN project project ON folder.project_id = project.project_id
        INNER JOIN branch branch ON request_branch.branch_id = branch.branch_id
        INNER JOIN branch_name branch_name ON branch.branch_id = branch_name.branch_id
        INNER JOIN folder_name folder_name ON folder.folder_name_id = folder_name.folder_name_id
        INNER JOIN request request ON project.request_id = request.request_id
        INNER JOIN request_branch request_branch ON request.request_id = request_branch.request_id
      WHERE
        folder.ocm_folder_id = in_anken_kanren_folder_ids(l_anken_folder_id)
        AND request_branch.request_branch_class = '1'
        AND branch.delete_flag = '0'
        AND branch_name.delete_flag = '0'
        AND folder_name.delete_flag = '0';

    l_msg_text.EXTEND;

    l_count_folder_ids := l_anken_folder_id;  

    l_msg_text(l_msg_text.LAST) := 
      '【'||l_count_folder_ids||'件目】'||CHR(13)||CHR(10)||
      'メーカー顧客管理番号: '||l_maker_customer_control_number||CHR(13)||CHR(10)||
      '親受付番号 : '||l_parent_receipt_number||CHR(13)||CHR(10)||
      '申請者支店 : '||l_branch_name||CHR(13)||CHR(10)||
      '消失フォルダ名 : '||l_folder_name||CHR(13)||CHR(10)||
      CHR(13)||CHR(10)||
      '----------------------------------------------------------------';

    END LOOP;

    /*
      1-2 申請関連フォルダ情報取得
    */
    l_shinsei_folder_id := in_shinsei_kanren_folder_ids.FIRST;
    
    FOR l_shinsei_folder_id IN in_shinsei_kanren_folder_ids.FIRST .. in_shinsei_kanren_folder_ids.LAST
    LOOP
      SELECT
        request.maker_customer_control_number
      , request.web_request_number
      , request.request_date
      , review.receipt_number
      , examination.receipt_number
      , branch_name.branch_name
      , folder_name.folder_name
      INTO
        l_maker_customer_control_number
      , l_web_request_number
      , l_request_date
      , l_review_reciept_number
      , l_exam_reciept_number
      , l_branch_name
      , l_folder_name
      FROM
        folder folder
        INNER JOIN request ON folder.request_id = request.request_id
        INNER JOIN review ON request.request_id = review.request_id
        INNER JOIN examination ON request.request_id = examination.request_id
        INNER JOIN request_branch ON request.request_id = request_branch.request_id
        INNER JOIN branch branch ON request_branch.branch_id = branch.branch_id
        INNER JOIN branch_name branch_name ON branch.branch_id = branch_name.branch_id
        INNER JOIN folder_name folder_name ON folder.folder_name_id = folder_name.folder_name_id
      WHERE
        folder.ocm_folder_id = in_shinsei_kanren_folder_ids(l_shinsei_folder_id)
        AND request_branch.request_branch_class = '1'
        AND branch.delete_flag = '0'
        AND branch_name.delete_flag = '0'
        AND folder_name.delete_flag = '0';

    l_msg_text.EXTEND;

    l_count_folder_ids := l_count_folder_ids + l_shinsei_folder_id;

    l_msg_text(l_msg_text.LAST) := 
      '【'||l_count_folder_ids||'件目】'||CHR(13)||CHR(10)||
      'メーカー顧客管理番号: '||l_maker_customer_control_number||CHR(13)||CHR(10)||
      'WEB申請番号 : '||l_web_request_number||CHR(13)||CHR(10)||
      '申請日時 : '||l_request_date||CHR(13)||CHR(10)||
      '審査受付番号 : '||l_review_reciept_number||CHR(13)||CHR(10)||
      '検査受付番号 : '||l_exam_reciept_number||CHR(13)||CHR(10)||
      '申請先支店 : '||l_branch_name||CHR(13)||CHR(10)||
      '消失フォルダ名 : '||l_folder_name||CHR(13)||CHR(10)||
      CHR(13)||CHR(10)||
      '----------------------------------------------------------------';

    END LOOP;

    /*
      1-3 追加届出関連フォルダ情報取得
    */
    l_tuika_folder_id := in_tuika_todokede_folder_ids.FIRST;

    FOR l_tuika_folder_id IN in_tuika_todokede_folder_ids.FIRST .. in_tuika_todokede_folder_ids.LAST
    LOOP
      SELECT
        request.maker_customer_control_number
      , project.parent_receipt_number
      , branch_name.branch_name
      , add_noti_name.additional_notification_name
      , folder_name.folder_name
      INTO
        l_maker_customer_control_number
      , l_parent_receipt_number
      , l_branch_name
      , l_additional_notification_name
      , l_folder_name
      FROM
        folder folder
        INNER JOIN additional_notification add_noti ON folder.additional_notification_id = add_noti.additional_notification_id
        INNER JOIN project project ON add_noti.project_id = project.project_id
        INNER JOIN branch branch ON request_branch.branch_id = branch.branch_id
        INNER JOIN branch_name branch_name ON branch.branch_id = branch_name.branch_id
        INNER JOIN additional_notification_name add_noti_name ON add_noti.additional_notification_id = add_noti_name.additional_notification_id
        INNER JOIN folder_name folder_name ON folder.folder_id = folder_name.folder_id
        INNER JOIN request request ON project.request_id = request.request_id
        INNER JOIN request_branch request_branch ON request.request_id = request_branch.request_id
      WHERE
        folder.ocm_folder_id IN in_tuika_todokede_folder_ids
        AND request_branch.request_branch_class = '1'
        AND branch.delete_flag = '0'
        AND branch_name.delete_flag = '0'
        AND add_noti_name.delete_flag = '0'
        AND folder_name.delete_flag = '0';

    l_msg_text.EXTEND;

    l_count_folder_ids := l_count_folder_ids + l_tuika_folder_id;

    l_msg_text(l_msg_text.LAST) := 
      '【'||l_count_folder_ids||'件目】'||CHR(13)||CHR(10)||
      'メーカー顧客管理番号: '||l_maker_customer_control_number||CHR(13)||CHR(10)||
      '親受付番号 : '||l_parent_receipt_number||CHR(13)||CHR(10)||
      '申請者支店 : '||l_branch_name||CHR(13)||CHR(10)||
      '追加届出名 : '||l_additional_notification_name||CHR(13)||CHR(10)||
      '消失フォルダ名 : '||l_folder_name||CHR(13)||CHR(10)||
      CHR(13)||CHR(10)||
      '----------------------------------------------------------------';

    END LOOP;

    /*
      2 システム管理者に通知する
    */
    -- settingテーブルで指定した送り先のメールアドレスを呼び出す
    SELECT
      value
    INTO
      l_msg_to
    FROM
      setting
    WHERE 
      setting_id = 2;

    FOR i IN l_msg_text.FIRST .. l_msg_text.LAST
    LOOP
      l_msg_text_body := l_msg_text_body ||CHR(13)||CHR(10)|| l_msg_text(i);
    END LOOP;

    APEX_MAIL.SEND(
      p_from => 'gic-idnet@gic-idnet-oci.tk'
    , p_to => l_msg_to
    , p_subject => '【バッチ】OCMフォルダ消失検知'
    , p_body => '
    ----------------------------------------------------------------'||CHR(13)||CHR(10)||
    'OCMフォルダの消失が検知されました。'||CHR(13)||CHR(10)||
    CHR(13)||CHR(10)||
    '検知日時 : '||TO_CHAR(SYSDATE, 'YYYY-MON-DD')||CHR(13)||CHR(10)||
    '検知件数 : '||l_count_folder_ids||CHR(13)||CHR(10)||
    CHR(13)||CHR(10)||
    '消失フォルダ情報'||CHR(13)||CHR(10)||
    l_msg_text_body
    );

    /*
      3-1 例外処理 - エラーログを出力
    */
    -- TODO 「119001_ログ出力」のアプリケーションログ出力を呼び出す

  END send_mail;

END b_115001;