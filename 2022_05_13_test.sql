/*
  2022/05/13
  中身が空、空＋あり
*/
DECLARE
  -- 配列
  TYPE l_array_time_test IS 
    TABLE OF TIMESTAMP INDEX BY VARCHAR2(100);
  -- 配列関連変数
  l_array_time l_array_time_test;
  l_index varchar(100);
  l_array_body varchar(30000);
  
  -- フォルダ関連変数
  l_shinpuro varchar2(10000);
  l_shinpuro_id varchar2(10000);
  l_shinpuro_modifiedTime_timeStamp TIMESTAMP;
  l_shinpuro_folder_id varchar2(10000) := 'F45FA03FEA057B1738F55CFF250012DBD47E59472E21';
  
  --　空フォルダテスト用
  l_empty varchar2(10000);
  l_empty_id varchar2(10000);
  l_empty_modifiedTime_timeStamp TIMESTAMP;
  l_empty_folder_id varchar2(10000) := 'FEA78C5303824D5EDCC4975FF78EE3D1FC5BDFA99D9F';
  
  l_sysdate TIMESTAMP;

  l_access_token varchar2(10000) := 'eyJ4NXQjUzI1NiI6Il9tS3JtdW04R2tRYmhSMEhTeW03eXB4SUpMS3NEMzd0RWZNYjFlN0lJOVkiLCJ4NXQiOiIzblFUY2F0VVUxRktLU2ktTlBid0NSNU9iNTgiLCJraWQiOiJTSUdOSU5HX0tFWSIsImFsZyI6IlJTMjU2In0.eyJ1c2VyX3R6IjoiQXNpYVwvVG9reW8iLCJzdWIiOiJqYW5nLXNAaWRuZXQuY28uanAiLCJ1c2VyX2xvY2FsZSI6ImphIiwic2lkbGUiOjQ4MCwiaWRwX25hbWUiOiJVc2VyTmFtZVBhc3N3b3JkIiwidXNlci50ZW5hbnQubmFtZSI6ImlkY3MtZDQzZDhjOTVmZjRmNDllNzg1MWRlZWUzYmRlYmUxYzciLCJpZHBfZ3VpZCI6IlVzZXJOYW1lUGFzc3dvcmQiLCJhbXIiOlsiVVNFUk5BTUVfUEFTU1dPUkQiXSwiaXNzIjoiaHR0cHM6XC9cL2lkZW50aXR5Lm9yYWNsZWNsb3VkLmNvbVwvIiwidXNlcl90ZW5hbnRuYW1lIjoiaWRjcy1kNDNkOGM5NWZmNGY0OWU3ODUxZGVlZTNiZGViZTFjNyIsImNsaWVudF9pZCI6IkU1RTg0OTNEQ0Q5MzQwNTQ4QjkwN0Y0MkVCMzQyMDgzX0FQUElEIiwic2lkIjoiZGY3MzczYWE0YjI1NGZlM2JhYzI5ZmFmMmRhMWM3ODc6MjViNjM5Iiwic3ViX3R5cGUiOiJ1c2VyIiwic2NvcGUiOiJvZmZsaW5lX2FjY2VzcyB1cm46b3BjOmNlYzphbGwiLCJjbGllbnRfdGVuYW50bmFtZSI6ImlkY3MtZDQzZDhjOTVmZjRmNDllNzg1MWRlZWUzYmRlYmUxYzciLCJyZWdpb25fbmFtZSI6ImFwLXRva3lvLWlkY3MtMSIsInVzZXJfbGFuZyI6ImVuIiwiZXhwIjoxNjUyOTQxNDE0LCJpYXQiOjE2NTIzMzY2MTQsImNsaWVudF9ndWlkIjoiZTc5ZmQwNGIxMTk5NDNkYjhjYjU0NzZlNjliM2UxNDkiLCJjbGllbnRfbmFtZSI6IkNFQ1NBVVRPX21pdG9jb09DRUNFQ1NBVVRPIiwiaWRwX3R5cGUiOiJMT0NBTCIsInRlbmFudCI6ImlkY3MtZDQzZDhjOTVmZjRmNDllNzg1MWRlZWUzYmRlYmUxYzciLCJqdGkiOiJlNmVlNDk4OTdkMTU0MWU2OGZiNjVkMDBkNDRjYTViOCIsImd0cCI6InJ0IiwidXNlcl9kaXNwbGF5bmFtZSI6IuOCt-ODm-ODsyDjgrjjg6Pjg7MiLCJvcGMiOnRydWUsInN1Yl9tYXBwaW5nYXR0ciI6InVzZXJOYW1lIiwicHJpbVRlbmFudCI6dHJ1ZSwidG9rX3R5cGUiOiJBVCIsImNhX2d1aWQiOiJjYWNjdC0xMjMxNzcyZGE5ZTk0ZDMwYjM4NTdiYzVmNjRjNjRmMyIsImF1ZCI6WyJodHRwczpcL1wvRTVFODQ5M0RDRDkzNDA1NDhCOTA3RjQyRUIzNDIwODMuY2VjLm9jcC5vcmFjbGVjbG91ZC5jb206NDQzXC9vc25cL3NvY2lhbFwvYXBpIiwiaHR0cHM6XC9cL0U1RTg0OTNEQ0Q5MzQwNTQ4QjkwN0Y0MkVCMzQyMDgzLmNlYy5vY3Aub3JhY2xlY2xvdWQuY29tOjQ0M1wvZG9jdW1lbnRzXC9pbnRlZ3JhdGlvblwvc29jaWFsIiwiaHR0cHM6XC9cL0U1RTg0OTNEQ0Q5MzQwNTQ4QjkwN0Y0MkVCMzQyMDgzLmNlYy5vY3Aub3JhY2xlY2xvdWQuY29tOjQ0M1wvIiwidXJuOm9wYzpsYmFhczpsb2dpY2FsZ3VpZD1FNUU4NDkzRENEOTM0MDU0OEI5MDdGNDJFQjM0MjA4MyJdLCJzdHUiOiJDRUNTQVVUTyIsInVzZXJfaWQiOiIyMDQ1MDNlY2QzYmE0ODVhOWU3Yjk1ZTUzY2QxZDI2ZiIsInJ0X2p0aSI6ImE5NjNmZTVlMDcyODQ1MGY4MmIyNTBhNWI2N2VhYjJkIiwidGVuYW50X2lzcyI6Imh0dHBzOlwvXC9pZGNzLWQ0M2Q4Yzk1ZmY0ZjQ5ZTc4NTFkZWVlM2JkZWJlMWM3LmlkZW50aXR5Lm9yYWNsZWNsb3VkLmNvbTo0NDMiLCJyZXNvdXJjZV9hcHBfaWQiOiJlNzlmZDA0YjExOTk0M2RiOGNiNTQ3NmU2OWIzZTE0OSJ9.gYQS41X7Np_1kJFa_iabbK3sDFPxGEVGkt_XphUp0NwITVk-zV-ABAxyrDBfKtmGqrIKMD9dVvnsdNQ5Eb4fIFeYggWy4jame7pgzsmsLGuaQZS5GlF7vVEfmytBsE9nBjgHPdnjLpBnWveOOzwv6bGg387PCZCyet41tgjwh-TmlLxz0ikaGQuzcPkQZw1nduzQE3rPyNZ2Sq9hfI9oqo0SV2JcQTcNUxqbrQRenHdN66Xo9fDuJlvWZqVyJwhActMOJORQ-k_Nv4m2gtGEqSiJe71W6Qt_Si38jOxv-nJdebycEethSIZm7rIZXYkd8-SjSSAxKgdFRvThvKfmCw';
  l_access_token_first varchar2(10000) := NULL;
  
BEGIN
  /*
    申請プログラム
  
  l_shinpuro := c_079001.get_folder_contents(in_folder_id => l_shinpuro_folder_id, io_access_token => l_access_token);
  apex_json.parse(l_shinpuro);
  
  FOR i IN 1..apex_json.get_count('items')
  LOOP
    l_shinpuro_id := apex_json.get_varchar2('items[%d].id',i);
    l_shinpuro_modifiedTime_timeStamp := apex_json.get_date('items[%d].modifiedTime', i);

    l_array_time(l_shinpuro_id) := l_shinpuro_modifiedTime_timeStamp;

  END LOOP;

    l_index := l_array_time.FIRST;

    WHILE l_index IS NOT NULL
    LOOP
      l_array_body := l_array_body ||CHR(13)||CHR(10)|| l_array_time(l_index);
      l_index := l_array_time.NEXT(l_index);
    END LOOP;

    DBMS_OUTPUT.PUT_LINE('array_body : ' || l_array_body);
  */
    
  /*
    空フォルダ
  */
  l_empty := c_079001.get_folder_contents(in_folder_id => l_empty_folder_id, io_access_token => l_access_token);
  apex_json.parse(l_empty);
  
  FOR i IN 1..apex_json.get_count('items')
  LOOP
    l_empty_id := apex_json.get_varchar2('items[%d].id',i);
    l_empty_modifiedTime_timeStamp := apex_json.get_date('items[%d].modifiedTime', i);

    l_array_time(l_empty_id) := l_empty_modifiedTime_timeStamp;

  END LOOP;

    l_index := l_array_time.FIRST;

    WHILE l_index IS NOT NULL
    LOOP
      l_array_body := l_array_body ||CHR(13)||CHR(10)|| l_array_time(l_index);
      l_index := l_array_time.NEXT(l_index);
    END LOOP;

    DBMS_OUTPUT.PUT_LINE('array_body : ' || l_array_body);
    
END;


/*
  
*/
DECLARE

  TYPE prefecture_array IS TABLE OF VARCHAR2(100);

  l_prefectures prefecture_array := prefecture_array();
  l_prefectures_body varchar2(10000);

  CURSOR c_prefecture IS
    SELECT
      prefecture_name AS pre_name
    FROM
      prefecture
    WHERE delete_flag IS NOT NULL;

BEGIN
  FOR r_prefecture IN c_prefecture
  LOOP
    l_prefectures.EXTEND;
    l_prefectures(l_prefectures.LAST) := r_prefecture.pre_name;
  END LOOP;
  
  FOR i IN 0..l_prefectures.COUNT-1
  LOOP
    l_prefectures_body := l_prefectures_body ||CHR(13)||CHR(10)|| l_prefectures(i);
  END LOOP;

  DBMS_OUTPUT.PUT_LINE('prefectures : ' || l_prefectures_body);
END;

