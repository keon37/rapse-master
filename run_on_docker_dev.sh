#!/bin/bash

export FLASK_APP=app
export FLASK_DEBUG=1
export APPLICATION_MODE=DEVELOPMENT

flask run --host=0.0.0.0 --port 5060
# uwsgi --ini uwsgi-dev.ini