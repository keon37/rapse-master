from flask import render_template, request, redirect, url_for, flash, abort

from .. import routes
from app.util.roles import user_in_roles


# 관리자 - 사용자 리스트
@routes.route('/manage/push/log', methods=['GET'])
@user_in_roles(['admin'])
def manage_push_log():
    with open("/app/rapse/log/push.log") as f:
        file_content = f.read()

    return render_template('manage/push_log.html', log=file_content)
