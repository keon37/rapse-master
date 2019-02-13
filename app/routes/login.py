from flask import render_template, redirect, flash, request, url_for, make_response
from flask_login import login_user, logout_user, current_user

from . import routes
from app.login_manager import login_manager
from app.database.query import read_user_by_id, read_user_by_no
from app.util.forms import LoginForm
from app.util.roles import user_in_roles


# for flask_login
@login_manager.user_loader
def load_user(user_no):
    return read_user_by_no(user_no)


# for flask_login
@login_manager.unauthorized_handler
def unauthorized_callback():
    return redirect(url_for('routes.login'))


@routes.route('/login', methods=['GET', 'POST'])
def login():
    # 로그인 사용자가 재접근하려고 할때 첫 화면으로 보내기
    if current_user.is_authenticated:
        return redirect(url_for('routes.normal_fmd'))

    # 로그인 분기처리
    form = LoginForm(request.form)
    if request.method == 'POST':
        if form.validate():
            user = read_user_by_id(form.USER_ID.data)

            if user:
                if user.APPROVAL == '1':
                    if user.check_password(form.USER_PW.data):
                        login_user(user)
                        return redirect(url_for('routes.index'))
                    else:
                        flash('아이디 또는 패스워드가 잘못되었습니다.<br>아이디/비밀번호를 잊어버리신 경우 관리자에게 문의바랍니다.')
                else:
                    flash('아직 관리자로부터 사용승인을 받지 않은 아이디 입니다.<br>관리자에게 문의 바랍니다.')
            else:
                flash('아이디 또는 패스워드가 잘못되었습니다.<br>아이디/비밀번호를 잊어버리신 경우 관리자에게 문의바랍니다.')
        else:
            flash('아이디와 패스워드를 모두 입력하셔야 합니다.')

    return render_template('login.html', form=form)


@routes.route("/logout")
@user_in_roles(['ANY'])
def logout():
    response = make_response(redirect(url_for('routes.index')))
    logout_user()

    return response
