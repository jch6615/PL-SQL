create or replace PACKAGE b_115001 AS
  
  /*
    変数
  */
  TYPE g_folderid_modifiedtime IS 
    TABLE OF TIMESTAMP INDEX BY VARCHAR2(100);

  TYPE g_folder_ids IS TABLE OF VARCHAR2(100);

  TYPE g_msg_text IS TABLE OF VARCHAR2(1000);

  /*
    ファイルメンテナンスの各処理を呼び出す
  */
  PROCEDURE file_maintenance_main;

  /*
    テンポラリフォルダの一覧を取得する
  */
  FUNCTION get_temporary_folder RETURN g_folderid_modifiedtime;

  /*
    OCMから取得したテンポラリフォルダの一覧から前日日時以前であるフォルダのフォルダIDを抽出する
  */
  FUNCTION get_delete_folder_id (
      in_folder_items IN g_folderid_modifiedtime
  ) RETURN g_folder_ids;

  /*
    不要なテンポラリフォルダおよびファイルを削除する
  */
  PROCEDURE delete_temporary_folder (
      in_folder_ids           IN g_folder_ids
    , out_delete_folder_count OUT NUMBER
  );

  /*
    存在確認の対象となるフォルダのフォルダIDを取得する
  */
  PROCEDURE get_sonzai_check_folder_id (
      out_anken_kanren_folder_ids         OUT g_folder_ids
    , out_shinsei_kanren_folder_ids       OUT g_folder_ids
    , out_tuika_todokede_folder_ids       OUT g_folder_ids
  );

  /*
    REST APIでOCMにフォルダ取得をリクエストして存在確認を行い、存在しなかったフォルダのフォルダIDを取得する
  */
  PROCEDURE get_lost_folder_id (
      io_anken_kanren_folder_ids         IN OUT g_folder_ids
    , io_shinsei_kanren_folder_ids       IN OUT g_folder_ids
    , io_tuika_todokede_folder_ids       IN OUT g_folder_ids
  );

  /*
    消失フォルダ情報のメールを作成して送信する
  */
  PROCEDURE send_mail (
      in_anken_kanren_folder_ids         IN  g_folder_ids
    , in_shinsei_kanren_folder_ids       IN  g_folder_ids
    , in_tuika_todokede_folder_ids       IN  g_folder_ids
  );

END b_115001;