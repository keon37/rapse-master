#!/bin/bash

export FLASK_APP=app/__init__.py
export FLASK_DEBUG=1
export APPLICATION_MODE=DEVELOPMENT

flask run --host=127.0.0.1 --port 5060
