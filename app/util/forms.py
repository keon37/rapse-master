from wtforms import Form, StringField, PasswordField, validators, SelectField, ValidationError, DateTimeField

from app.util.codes import user_disable, dict_to_wtform_choices
from app.util.roles import roles

from app.database.models import User, Grouping


# 들어오는 모든 데이터를 strip 해주기 위함
class MyBaseForm(Form):
    class Meta:
        def bind_field(self, form, unbound_field, options):
            filters = unbound_field.kwargs.get('filters', [])
            # 패스워드 필드일때만 제외
            if unbound_field.field_class is not PasswordField:
                filters.append(my_strip_filter)
            return unbound_field.bind(form=form, filters=filters, **options)


def my_strip_filter(value):
    if value is not None and hasattr(value, 'strip'):
        return value.strip()
    return value


# 사용자 폼
class UserForm(MyBaseForm):
    USER_NM = StringField('이름(실명)', [validators.Length(min=2, max=25)])
    USER_HP_NO = StringField('연락처', [validators.Length(min=9, max=15)])
    USER_COMP = StringField('소속', [validators.Length(min=1, max=25)])
    USER_EMAIL = StringField('이메일', [validators.Length(min=5, max=50)])

    class Meta:
        locales = ['ko']


class UserCreateFormUser(UserForm):
    USER_ID = StringField('아이디', [validators.Length(min=3, max=25)])
    USER_PW = PasswordField('패스워드', [validators.Length(min=4, max=25)], render_kw={"autocomplete": "new-password"})

    def validate_USER_ID(form, field):
        user = User.query.filter(User.USER_ID == field.data).first()
        if user:
            if user.APPROVAL == '1':
                raise ValidationError('동일한 아이디가 존재합니다.')
            elif user.APPROVAL == '0':
                raise ValidationError('동일한 아이디가 존재하며, 사용승인 대기중입니다.')


class UserCreateFormAdmin(UserForm):
    USER_ID = StringField('아이디', [validators.Length(min=3, max=25)])
    USER_PW = PasswordField('패스워드', [validators.Length(min=4, max=25)], render_kw={"autocomplete": "new-password"})

    USER_ROLE = SelectField('권한', choices=dict_to_wtform_choices(roles), default='user')

    def validate_USER_ID(form, field):
        user = User.query.filter(User.USER_ID == field.data).first()
        if user:
            if user.APPROVAL == '1':
                raise ValidationError('동일한 아이디가 존재합니다.')
            elif user.APPROVAL == '0':
                raise ValidationError('동일한 아이디가 존재하며, 사용승인 대기중입니다.')


class UserUpdateFormAdmin(UserForm):
    USER_ID = StringField('아이디', [validators.Length(min=3, max=25)])
    USER_PW = PasswordField('패스워드', [validators.Optional(), validators.Length(min=4, max=25)], render_kw={"autocomplete": "new-password"})

    USER_NO = StringField("사용자 고유번호", render_kw={'readonly': True})
    CREAT_DT = StringField("계정 생성일", render_kw={'readonly': True})
    USER_ROLE = SelectField('권한', choices=dict_to_wtform_choices(roles))
    APPROVAL = SelectField('사용승인', choices=dict_to_wtform_choices(user_disable))

    def validate_USER_ID(form, field):
        user = User.query.filter(User.USER_ID == field.data).filter(User.USER_NO != form.USER_NO.data).first()
        if user:
            if user.APPROVAL == '1':
                raise ValidationError('동일한 아이디가 존재합니다.')
            elif user.APPROVAL == '0':
                raise ValidationError('동일한 아이디가 존재하며, 사용승인 대기중입니다.')


class UserUpdateFormMy(UserForm):
    USER_ID = StringField('아이디', [validators.Length(min=3, max=25)], render_kw={'readonly': True})
    USER_PW = PasswordField('패스워드', [validators.Optional(), validators.Length(min=4, max=25)], render_kw={"autocomplete": "new-password"})


# 로그인 폼
class LoginForm(MyBaseForm):
    USER_ID = StringField('아이디', [validators.Required()], render_kw={"placeholder": "아이디"})
    USER_PW = PasswordField('패스워드', [validators.Required()], render_kw={"placeholder": "패스워드"})

    class Meta:
        locales = ['ko']


class GroupingForm(MyBaseForm):
    START_DATE = DateTimeField(
        '시작일', [validators.Required()], format='%Y-%m-%d', render_kw={
            'data-date-format': "yyyy-mm-dd",
            "placeholder": "시작일 선택"
        }
    )
    END_DATE = DateTimeField(
        '종료일', [validators.Required()], format='%Y-%m-%d', render_kw={
            'data-date-format': "yyyy-mm-dd",
            "placeholder": "종료일 선택"
        }
    )

    DISEASE_TYPE = StringField("질병타입")

    def validate(self):
        rv = Form.validate(self)
        if not rv:
            return False

        start = self.START_DATE.data.date()
        end = self.END_DATE.data.date()

        query = Grouping.query
        query = query.filter(Grouping.DISEASE_TYPE == self.DISEASE_TYPE.data)
        query = query.filter(
            ((Grouping.START_DATE >= start) & (Grouping.START_DATE <= end))
            | ((Grouping.END_DATE >= start) & (Grouping.END_DATE <= end))
        )

        if isinstance(self, GroupingUpdateForm):
            query = query.filter(Grouping.GROUPING_NO != self.GROUPING_NO.data)

        grouping = query.first()

        if grouping:
            if (grouping.START_DATE >= start) & (grouping.START_DATE <= end):
                self.START_DATE.errors.append('시작일이 겹치는 데이터가 존재합니다. 권역화 고유번호: {}'.format(grouping.GROUPING_NO))
            else:
                self.END_DATE.errors.append('종료일이 겹치는 데이터가 존재합니다. 권역화 고유번호: {}'.format(grouping.GROUPING_NO))
            return False

        return True


class GroupingCreateForm(GroupingForm):
    pass


class GroupingUpdateForm(GroupingForm):
    GROUPING_NO = StringField("고유번호", render_kw={'readonly': True})
    CREATE_DT = StringField("생성일", render_kw={'readonly': True})
