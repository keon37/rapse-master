import os.path

from flask import current_app, url_for
from flask_login import current_user

from . import routes


@routes.context_processor
def inject_menus():
    user_role = getattr(current_user, 'USER_ROLE', '')

    menus = []

    if user_role == '':
        menus.append(
            Menu(
                'public', '권역정보', [
                    Menu('/public/fmd', '구제역 권역정보'),
                    Menu('/public/restriction/fmd', '구제역 이동제한 정보'),
                    Menu('/public/hpai', 'HPAI 권역정보'),
                    Menu('/public/restriction/hpai', 'HPAI 이동제한 정보'),
                ]
            )
        )

    if user_role in ['admin']:
        if current_user.USER_ID == 'admin':
            menus.append(
                Menu(
                    'public', '권역정보', [
                        Menu('/public/fmd', '구제역 권역정보'),
                        Menu('/public/restriction/fmd', '구제역 이동제한 정보'),
                        Menu('/public/hpai', 'HPAI 권역정보'),
                        Menu('/public/restriction/hpai', 'HPAI 이동제한 정보'),
                    ]
                )
            )

        if current_user.USER_ID == 'fmd':
            menus.append(Menu('public', '권역정보', [
                Menu('/public/fmd', '구제역 권역정보'),
                Menu('/public/restriction/fmd', '구제역 이동제한 정보'),
            ]))

        if current_user.USER_ID == 'hpai':
            menus.append(Menu('public', '권역정보', [
                Menu('/public/hpai', 'HPAI 권역정보'),
                Menu('/public/restriction/hpai', 'HPAI 이동제한 정보'),
            ]))

    if user_role in ['admin']:
        if current_user.USER_ID == 'admin':
            menus.append(Menu('normal', '평시권역', [
                Menu('/normal/fmd', '평시 FMD 권역화'),
                Menu('/normal/hpai', '평시 HPAI 권역화'),
            ]))
            menus.append(
                Menu(
                    'breakout', '발생권역', [
                        Menu('/breakout/fmd', '발생시 FMD 권역화'),
                        Menu('/breakout/groupings/fmd', '발생시 FMD 권역설정'),
                        Menu('/breakout/hpai', '발생시 HPAI 권역화'),
                        Menu('/breakout/groupings/hpai', '발생시 HPAI 권역설정'),
                    ]
                )
            )
            menus.append(
                Menu(
                    'facilities', '시설정보', [
                        Menu('/facilities/fmd/density', 'FMD 시설 밀집도'),
                        Menu('/facilities/fmd/scale', 'FMD 시설 규모'),
                        Menu('/facilities/hpai/density', 'HPAI 시설 밀집도'),
                        Menu('/facilities/hpai/scale', 'HPAI 시설 규모'),
                    ]
                )
            )

        if current_user.USER_ID == 'fmd':
            menus.append(Menu('normal', '평시권역', [
                Menu('/normal/fmd', '평시 FMD 권역화'),
            ]))
            menus.append(
                Menu('breakout', '발생권역', [
                    Menu('/breakout/fmd', '발생시 FMD 권역화'),
                    Menu('/breakout/groupings/fmd', '발생시 FMD 권역설정'),
                ])
            )
            menus.append(
                Menu('facilities', '시설정보', [
                    Menu('/facilities/fmd/density', 'FMD 시설 밀집도'),
                    Menu('/facilities/fmd/scale', 'FMD 시설 규모'),
                ])
            )

        if current_user.USER_ID == 'hpai':
            menus.append(Menu('normal', '평시권역', [
                Menu('/normal/hpai', '평시 HPAI 권역화'),
            ]))
            menus.append(
                Menu('breakout', '발생권역', [
                    Menu('/breakout/hpai', '발생시 HPAI 권역화'),
                    Menu('/breakout/groupings/hpai', '발생시 HPAI 권역설정'),
                ])
            )
            menus.append(
                Menu(
                    'facilities', '시설정보', [
                        Menu('/facilities/hpai/density', 'HPAI 시설 밀집도'),
                        Menu('/facilities/hpai/scale', 'HPAI 시설 규모'),
                    ]
                )
            )

        menus.append(
            Menu(
                'manage',
                '관리메뉴',
                [
                    Menu('/manage/users', '사용자 관리'),
                    Menu('/manage/appusers', '앱 사용자 관리'),
                    # Menu('/manage/push/log', '알림 메세지 발송 로그'),
                    Menu('/manage/data', '데이터 관리'),
                ]
            )
        )

    elif user_role in ['user']:
        pass
    else:
        menus.append(Menu('manage', '관리자', [
            Menu('/login', '로그인'),
        ]))

    return {
        'menus': menus,
    }


class Menu:
    def __init__(self, href, caption, children=[]):
        self.href = href
        self.caption = caption
        self.children = children

    def isActive(self, href):
        if self.href == href:
            return True

        for child in self.children:
            if child.href == href:
                return True

        return False


@routes.context_processor
def inject_debug():
    return {
        'is_debug': current_app.config['DEBUG'],
    }


@routes.context_processor
def override_url_for():
    return dict(url_for=dated_url_for)


def dated_url_for(endpoint, **values):
    if endpoint == 'static':
        filename = values.get('filename', None)
        if filename:
            file_path = os.path.join(current_app.root_path, endpoint, filename)
            values['q'] = int(os.stat(file_path).st_mtime)
    return url_for(endpoint, **values)
