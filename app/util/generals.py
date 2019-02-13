import os
import logging
import logging.handlers


def getLogger(name):
    logger = logging.Logger(name)

    handler = logging.handlers.RotatingFileHandler(
        os.path.join('/app/rapse/log/', name + '.log'),
        mode='a',
        maxBytes=5 * 1024 * 1024,
        backupCount=10,
    )

    handler.setLevel(logging.INFO)
    handler.setFormatter(logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s'))
    logger.addHandler(handler)
    return logger


def split_list(list, size):
    for i in range(0, len(list), size):
        yield list[i:i + size]
