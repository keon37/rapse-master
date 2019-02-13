from flask import render_template, request, flash
from flask_login import current_user

from . import routes
from app.database.query import update_user
from app.util.forms import UserUpdateFormMy
from app.util.roles import user_in_roles


# 개인정보 수정
@routes.route('/me', methods=['GET', 'POST'])
@user_in_roles(['ANY'])
def me():
    user = current_user

    if request.method == 'GET':
        form = UserUpdateFormMy(obj=user)

    if request.method == 'POST':
        form = UserUpdateFormMy(request.form)

        if form.validate():
            user.USER_NM = form.USER_NM.data
            user.USER_COMP = form.USER_COMP.data
            user.USER_HP_NO = form.USER_HP_NO.data
            user.USER_EMAIL = form.USER_EMAIL.data

            if form.USER_PW.data:
                user.set_password(form.USER_PW.data)

            update_user(user)
            flash('사용자 데이터가 업데이트 되었습니다.')

    return render_template('/me.html', form=form)
