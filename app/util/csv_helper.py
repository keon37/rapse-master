import datetime
from flask import Response


# csv 생성시 StringIO 대체용 (for performance)
class Line(object):
    def __init__(self):
        self._line = None

    def write(self, line):
        self._line = line

    def read(self):
        return self._line


def csv_response(data, filename):
    response = Response(data)
    response.headers['Content-Type'] = 'text/csv; charset=utf-8-sig'
    response.headers['Content-Disposition'] = 'attachment; filename={}-{}.csv'.format(
        filename,
        datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    )
    return response
