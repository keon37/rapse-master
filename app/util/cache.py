from flask_caching import Cache

cache = Cache()


def clearCache():
    cache.clear()
