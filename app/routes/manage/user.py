from flask import render_template, request, redirect, url_for, flash, abort

from .. import routes
from app.database.query import read_users, read_user_by_no, create_user, update_user, read_user_apps
from app.database.models import User
from app.util.forms import UserCreateFormAdmin, UserUpdateFormAdmin
from app.util.roles import user_in_roles


# 관리자 - 사용자 리스트
@routes.route('/manage/users', methods=['GET'])
@user_in_roles(['admin'])
def manage_users():
    condition_key = request.args.get('cond_key', '', type=str).strip()
    condition_value = request.args.get('cond_val', '', type=str).strip()

    page = request.args.get('page', 1, type=int)
    per_page = request.args.get('per_page', 10, type=int)

    users = read_users(page, per_page, condition_key, condition_value)
    return render_template('manage/users.html', users=users, condition_key=condition_key, condition_value=condition_value)


# 관리자 - 사용자 상세
@routes.route('/manage/users/<user_no>', methods=['GET', 'POST'])
@user_in_roles(['admin'])
def manage_user(user_no):
    if request.method == 'GET':
        user = read_user_by_no(user_no)
        if user is None and user_no != 'create':
            return abort(404)

        if user_no == 'create':
            form = UserCreateFormAdmin(obj=user)
        else:
            form = UserUpdateFormAdmin(obj=user)

    if request.method == 'POST':
        if request.form['action'] == 'update':
            form = UserUpdateFormAdmin(request.form)

        if request.form['action'] == 'create':
            form = UserCreateFormAdmin(request.form)

        if form.validate():
            user = User(
                USER_ID=form.USER_ID.data,
                USER_NM=form.USER_NM.data,
                USER_COMP=form.USER_COMP.data,
                USER_HP_NO=form.USER_HP_NO.data,
                USER_EMAIL=form.USER_EMAIL.data,
                USER_ROLE=form.USER_ROLE.data,
            )

            if form.USER_PW.data:
                user.set_password(form.USER_PW.data)

            if request.form['action'] == 'update':
                user.USER_NO = form.USER_NO.data
                user.APPROVAL = form.APPROVAL.data
                update_user(user)
                flash('사용자 데이터가 업데이트 되었습니다.')

            if request.form['action'] == 'create':
                user.APPROVAL = True
                create_user(user)
                flash('사용자가 추가되었습니다.')
                return redirect(url_for('routes.users'))

    return render_template('/manage/user.html', form=form)


# 관리자 - 앱 사용자 리스트
@routes.route('/manage/appusers', methods=['GET'])
@user_in_roles(['admin'])
def manage_appusers():
    condition_key = request.args.get('cond_key', '', type=str).strip()
    condition_value = request.args.get('cond_val', '', type=str).strip()

    page = request.args.get('page', 1, type=int)
    per_page = request.args.get('per_page', 10, type=int)

    users = read_user_apps(page, per_page, condition_key, condition_value)
    return render_template('manage/appusers.html', users=users, condition_key=condition_key, condition_value=condition_value)
