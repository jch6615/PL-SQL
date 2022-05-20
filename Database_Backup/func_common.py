import base64

import smtplib
import email.utils
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
import ssl

import oci

# シークレット名によるシークレット名・シークレットOCIDキーバリューペアを取得する
def get_vault_secret(vault_client, compartment_id, secret_list):
    # シークレット名・シークレットOCIDキーバリューペアを取得する
    vault_ocid = dict()

    # 該当するコンパートメントのすべてのシークレットを取得する
    secret_summary = vault_client.list_secrets(compartment_id).data
    for secret in secret_summary:
        # シークレット名が取得必要な情報の名前に含まれば、OCIDを取得して、キーバリューペアを追加する
        if secret.secret_name in secret_list:
            vault_ocid[secret.secret_name] = secret.id
    return vault_ocid

# Vaultに格納されている情報を復号する
def get_secret_content(secret_client, secret_ocid):
    # シークレットクライアントによってVaultから情報を取得する
    secret_content = secret_client.get_secret_bundle(secret_ocid).data.secret_bundle_content.content.encode('utf-8')
    # base64で暗号化された文字列を復号する
    decrypted_secret_content = base64.b64decode(secret_content).decode("utf-8")

    # 復号された情報を返却する
    return decrypted_secret_content

# メールを送信する
def send_notification(
    email_sender, # メール送信アドレス
    email_sendername, # メール送信者名
    email_recipient, # メール受信アドレス
    smtp_username, # SMTPユーザー名
    smtp_password, # SMTPパスワード
    smtp_host, # SMTPホスト
    smtp_port, # SMPTPポート
    email_subject, # メールの件名
    email_message): # メールの本文

    charset = "utf-8"
    message = MIMEMultipart('alternative')

    # メールのヘッダーを付ける
    message['Subject'] = email_subject
    message['From'] = email.utils.formataddr((email_sendername, email_sender))
    message['To'] = email_recipient

    # メールの本文を付ける
    message.attach(MIMEText(email_message, 'html', charset))

    # メールを送信する
    try:
        # SMTPサーバに接続する
        server = smtplib.SMTP(
            smtp_host,
            smtp_port)
        server.ehlo()
        # OCIメール送信サービスのデフォルトCAを使用する
        server.starttls(
            context = ssl.create_default_context(purpose=ssl.Purpose.SERVER_AUTH,
            cafile = None,
            capath = None))
        # starttls()の前と後にehlo()を呼び出す（SMTPLIBドキュメントのおすすめ）
        server.ehlo()
        # SMTPサーバにログインする
        server.login(
            smtp_username,
            smtp_password)
        # メールの送信アドレス、受信アドレスと内容を設定する
        server.sendmail(
            email_sender,
            email_recipient,
            message.as_string())
        server.close()
    # 送信中エラーがあったら、実行を中止して、エラーをRAISEする
    except Exception as e:
        raise

# OKEのノードプールのノード数を指定した数字にする
# スケールインの場合は1
# スケールアウトの場合は2
def resize_node_pool(
        size,
        node_pool,
        container_engine_client):
    # ノードの構成（数）を指定する
    update_node_pool_node_config_details = oci.container_engine.models.UpdateNodePoolNodeConfigDetails(
        size = size)
    # ノードプールの構成を指定する
    update_node_pool_details = oci.container_engine.models.UpdateNodePoolDetails(
        node_config_details = update_node_pool_node_config_details)

    try:
        # ノードプールを指定して、ノードプールを更新する
        update_node_pool_response = container_engine_client.update_node_pool(
            node_pool_id = node_pool,
            update_node_pool_details = update_node_pool_details)
    except oci.exceptions.ServiceError as e:
        # 成功以外の場合、実行を中止して、エラーをRAISEする
        if  e.status != 201 or e.status != 202:
            raise

    return update_node_pool_response
