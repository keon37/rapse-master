from pyfcm import FCMNotification
from app.util.codes import regions
from app.util.generals import getLogger, split_list


def logPush(disease_type, target, title, body, result):
    pushLogger = getLogger('push')
    pushLogger.info('알림 메세지 발송 시작 ----------------------------------------------------------')
    pushLogger.info('질병타입 : %s', disease_type)
    pushLogger.info('제목 : %s', title)
    pushLogger.info('내용 : %s', body)
    pushLogger.info('대상지역 : %s', target)
    pushLogger.info('발송결과 : %s', result)


def logResult(result):
    pushLogger = getLogger('push')
    pushLogger.info('result : %s', result)


def get_push_service():
    return FCMNotification(
        api_key=
        "AAAADZ1cOAU:APA91bG5XLVKq6wNh1O3cOOMsHoeCdoOgUEX_9FmoJyclGaOT4sHzPCWSkWceVqRv28D3TwIqVwwbX6A9bAY0DiGpk6BWJYQxV0OnlmZsVcp2AwzIWtCxjttXoOZI_AShw1A_JnrSaLSufYpuwiR53bG9OCYlXjOUg"
    )


def make_topic_condition(disease_type, topics):
    topics = ["'{}' in topics".format(make_topic_name(disease_type, topic)) for topic in topics]
    topic_condition = " || ".join(topics)
    return topic_condition


def make_topic_name(disease_type, topic):
    return "{}_{}".format(disease_type, regions.get(topic, '0'))


def send_to_devices(tokens, title, body):
    result = get_push_service().notify_multiple_devices(
        registration_ids=tokens,
        **make_message(title, body),
    )
    logPush('', tokens, title, body, result)
    return result


def send_to_topic(disease_type, topic, title, body):
    result = get_push_service().notify_topic_subscribers(
        topic_name=make_topic_name(disease_type, topic),
        **make_message(title, body),
    )
    logPush(disease_type, topic, title, body, result)
    return result


def send_to_topics(disease_type, topics, title, body):
    push_service = get_push_service()
    if '모든 지역' not in topics:
        topics.append('모든 지역')

    result = []
    for topic_chunk in split_list(topics, 5):
        result.append(
            push_service.notify_topic_subscribers(
                condition=make_topic_condition(disease_type, topic_chunk),
                **make_message(title, body),
            )
        )

    logPush(disease_type, topics, title, body, result)
    return result


def subscribe(tokens, topic):
    result = get_push_service().subscribe_registration_ids_to_topic(tokens, topic)
    logResult(result)
    return result


def unsubscribe(tokens, topic):
    result = get_push_service().unsubscribe_registration_ids_from_topic(tokens, topic)
    logResult(result)
    return result


def make_message(title, body):
    return {
        'message_title': title,
        'message_body': body,
        'data_message': {
            "title": title,
            "body": body,
        },
        'click_action': "FCM_PLUGIN_ACTIVITY",
        'message_icon': "icon_push",
    }


# disease_type = 'fmd'
# title = '구제역 질병 권역 알림'
# body = '구제역이 추가로 확산되는 것을 차단하고 조기에 종식시키기 위해 해당 지역을 구제역 질병 권역으로 지정하오니 참고 바랍니다.'

# send_to_topics(disease_type, ['모든 지역', '서울특별시'], title, body)

# subscribe(brother_iPhone, 'all')
# unsubscribe(brother_iPhone, 'all')
# send_to_topics(['모든 지역', '서울특별시'], title, body)
# send_to_topics(['부산광역시2', '서울특별시'], title, body)
# sendToTopic('모든 지역', title, body)
# sendToTopic('서울특별시', title, body)
# phones = [
#     'dCJbvMpMFwo:APA91bHDylnrwxYGcQxeAG9hiZnTqIsFiaN01pes4V9eRnFRnD-1rlonx71DPK55ycf6_R1x44xx4MZhAr3A0uj5SbZIiHL9ZEmahHyzHW7Gftlfp7Avl3a3-O3VQLE6mKFkUGTQ5J_yeEckri9DYFqGmB0O8sQ03A',
# ]
# # send_to_devices('test', [brother_iPhone], 'test', 'test')
# get_push_service().notify_multiple_devices(
#     registration_ids=phones,
#     **make_message('test', 'test'),
# )
