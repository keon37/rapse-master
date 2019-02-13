from flask import render_template, redirect, flash, request, url_for

from . import routes
from app.login_manager import login_manager
from app.database.query import create_user
from app.database.models import User
from app.util.forms import UserCreateFormUser


@routes.route('/signup', methods=['GET', 'POST'])
def signup():
    form = UserCreateFormUser(request.form)

    if request.method == 'POST':
        if form.validate():
            user = User(
                USER_ID=form.USER_ID.data,
                USER_NM=form.USER_NM.data,
                USER_COMP=form.USER_COMP.data,
                USER_EMAIL=form.USER_EMAIL.data,
                USER_HP_NO=form.USER_HP_NO.data,
            )

            user.set_password(form.USER_PW.data)
            user.APPROVAL = False

            create_user(user)

            flash('회원가입이 완료되었습니다. 관리자의 승인을 얻은 후 사용할 수 있습니다. 문의 031-0000-0000')
            return redirect(url_for('routes.index'))

    return render_template('/signup.html', form=form)