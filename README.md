[![Build Status](https://travis-ci.org/mpasternak/django-monitio.png?branch=master)](https://travis-ci.org/mpasternak/django-monitio)
[![Build Status](https://drone.io/github.com/mpasternak/django-monitio/status.png)](https://drone.io/github.com/mpasternak/django-monitio/latest)

BIG CHANGE, version 0.4
=======================

With the transaction framework changed in Django 1.6 and having in mind, that
transaction signals are not really a good idea, at this moment you send the
notifies MANUALLY.

API functions return a Message object and if you want to notify about it,
use notify.via_sse

In the future, this package could become a thin layer of just the notification
code, as the persistent-message applications seem to be popular, perhaps it
would be better to find a well-supported persistent-message application AND
have this package as separate, thin layer of glue-code between that persistent
messaging library and SSE messaging delivery.


Monitio for Django
==================

Monitio allows you to have messages (aka notifications), that:

* can be persisted (stored in the database and read later),
* which dynamically show on the web UI when added,
* and can be optionally sent via e-mail to your end-user.

Monitio is built upon:

* [django-sse](https://github.com/niwibe/django-sse)
 * which uses [django-redis](https://github.com/niwibe/django-redis)
 * ... and [Redis database](https://redis.io)
* [Yaffle's EventSource.js](https://github.com/Yaffle/EventSource) for cross-browser Server-Sent Events compatibility
* [django-cors-headers](https://github.com/ottoyiu/django-cors-headers) for the same thing
* [django-transaction-signals](https://github.com/davehughes/django-transaction-signals)
* [jQuery](http://jquery.com/) and [jQueryUI](http://jqueryui.com)

With such sophisticated setup, using packages from many individuals, the demo 
application is currently properly running on MSIE 10, Opera 12, FFox 16 and 
Safari 5.1.7 on Windows. Also, monitio has been tested in production environment
with nginx + gunicorn, which also has been found to work properly. 

Documentation
-------------

A Django app for unified, persistent and live user messages/notifications, built on top of Django's [messages framework](http://docs.djangoproject.com/en/dev/ref/contrib/messages/) (`django.contrib.messages`).

Monitio is a messages storage backend that provides support for messages that are supposed to be persistent, that is, they outlast a browser session and will be stored in the database. These messages can be displayed as you will to the user, you can let the user mark them as read, remove them or even reply them. For some of these actions there are views you can import in your project urls.py.

* Support persistent and nonpersistent messages for authenticated users. Persistent messages are stored in the database. 
* For anonymous users, messages are stored using the cookie/session-based approach. There is no support for persistent messages for anonymous users.
* There is a unified API for displaying messages to both types of users, that is, you can use the same code you'd be using with Django's messaging framework in order to add and display messages, but there is additional functionality available if the user is authenticated.

Installation
------------

This document assumes that you are familiar with Python and Django.

1. Clone this git repository (no PyPI package for this fork). master branch is the lastest stable branch: 

        $ git clone git://github.com/mpasternak/django-monitio.git

2. Make sure `monitio` is in your `PYTHONPATH`.
3. Add `monitio` & company to your `INSTALLED_APPS` setting.

        INSTALLED_APPS = (
            ...
            'django_sse',
            'corsheaders',
            'monitio',
        )

4. Make sure Django's `MessageMiddleware` is in your `MIDDLEWARE_CLASSES` setting (which is the case by default), also enable `CorsMiddleware` there. Add `LocaleMiddleware` if you want to use translations:

        MIDDLEWARE_CLASSES = (
            ...
            'django.contrib.messages.middleware.MessageMiddleware',
    		'corsheaders.middleware.CorsMiddleware',
            'django.middleware.locale.LocaleMiddleware',
            ...
        )

5. Add the CONTEXT_PROCESSOR for messages and static URL:

        CONTEXT_PROCESSORS = (
            ...
            'django.contrib.messages.context_processors.messages',
            'django.core.context_processors.static',
            ...
        )

 
6. Add the `monitio` URLs to your URL conf. For instance, in order to make messages available under `http://domain.com/messages/`, add the following line to `urls.py`.

        urlpatterns = patterns('',
            (r'^messages/', include('monitio.urls', namespace='monitio')),
            ...
        )

7. In your settings, set the message [storage backend](http://docs.djangoproject.com/en/dev/ref/contrib/messages/#message-storage-backends) to `monitio.storage.PersistentMessageStorage`:

        MESSAGE_STORAGE = 'monitio.storage.PersistentMessageStorage'
        
8. In your settings, add a reasonable default, which will prevent from showing read messages to the users:

        MONITIO_EXCLUDE_READ = True
        
9. Setup `django-sse` and `corsheaders`:

        REDIS_SSEQUEUE_CONNECTION_SETTINGS = {
            'location': '127.0.0.1:6379',
            'db': 0,
        }
        
        CORS_ORIGIN_WHITELIST = (
            '127.0.0.1',
            '127.0.0.1:8000',
        )

10. Set up the database tables using

	    $ manage.py syncdb

11. If you want to use the bundled templates, add the `templates` directory to your `TEMPLATE_DIRS` setting:

        TEMPLATE_DIRS = (
            ...
            'path/to/monitio/templates')
        )
        
12. Setup a server - for [nginx](http://nginx.org/) + [gunicorn](http://gunicorn.org), please use configuration below:
		
		location ~ ^/messages/sse/(?<user>)$ {
            proxy_pass http://your-gunicorn-address.../messages/sse/$user$is_args$args;
			proxy_buffering off;
			proxy_cache off;
			proxy_set_header Host $host;
			
			proxy_set_header Connection '';
			proxy_http_version 1.1;
			chunked_transfer_encoding off;
		}

   And, for [gunicorn](http://gunicorn.org), make sure you install [gevent](http://www.gevent.org/) and run [gunicorn](http://gunicorn.org) with parameter `-k gevent`.
   I *strongly* suggest you run the gevent-enabled server only for serving SSE messages and keep another gunicorn server for everything else - for some (I suppose, rare)
   cases, gevent can be problematic if you access network from your website code. For example, my use case was using XMPP, which did not work with gevent (both
   xmpppy and SleekXMPP modules did not).

Using messages in views and templates
-------------------------------------

### Message levels ###

Django's messages framework provides a number of [message levels](http://docs.djangoproject.com/en/dev/ref/contrib/messages/#message-levels) for various purposes such as success messages, warnings etc. 

    import monitio
    # persistent message levels:
    monitio.INFO
    monitio.SUCCESS
    monitio.WARNING
    monitio.ERROR
    
This app provides constants with the same names, the difference being that messages with these levels are going to be persistent:

    from django.contrib import messages
    # temporary message levels:
    messages.INFO 
    messages.SUCCESS 
    messages.WARNING
    messages.ERROR

**Note**: Let's stress the importance of this. If you use `monitio` constants the message will be stored in the database and kept there till somebody explicitly deletes it. If you use `contrib.messages` constants, you get the same behavior as if you were using a non persistent storage, messages are stored in the database ensuring reception but they are removed right after being accessed.
;
### Adding a message ###

Since the app is implemented as a [storage backend](http://docs.djangoproject.com/en/dev/ref/contrib/messages/#message-storage-backends) for Django's [messages framework](http://docs.djangoproject.com/en/dev/ref/contrib/messages/), you can still use the regular Django API to add a message:

    from django.contrib import messages
    messages.add_message(request, messages.INFO, 'Hello world.')

This is compatible and equivalent to using the API provided by `monitio`:

    import monitio
    from django.contrib import messages
    monitio.add_message(request, messages.INFO, 'Hello world.')

In order to add a persistent message (one that is stored permanently in the Database), use `monitio` levels listed above:

    messages.add_message(request, monitio.WARNING, 'This message is stored in monitio table till removed.')

or the equivalent:

    monitio.add_message(request, monitio.WARNING, 'This message is stored in monitio table till removed')
    
Note that this is only possible for logged-in users, so you are probably going to have make sure that the current user is not anonymous using `request.user.is_authenticated()`. Adding a persistent message for anonymous users raises a `NotImplementedError`.

### Extended API ###

Persistent Messages has an extended API that will let you do some extra nice things. This is the prototype of `add_message` in contrib messages:

    def add_message(request, level, message, extra_tags='', fail_silently=False):

This is the prototype of `add_message` in Persistent Messages.

    def add_message(request, level, message, extra_tags='', fail_silently=False, subject='', user=None, email=False, from_user=None, expires=None, close_timeout=None):

#### Subject and email notifications ####

Using `monitio.add_message`, you can also add a subject line to the message. You can also set if you want an email notification to be sent. The following message will be stored as a message in the database and also sent to the email address associated with the current user:

    monitio.add_message(request, monitio.INFO, 'Message body', subject='Please read me', email=True)

**Note!** Email notifications at the moment are too simple, I don't recommend using them, I'm not.

#### Send messages to different users ####

You can also pass this function a `User` object if the message is supposed to be sent to a user other than the one who is currently authenticated. User Sally will see this message the next time she logs in:

    from django.contrib.auth.models import User
    sally = User.objects.get(username='Sally')
    monitio.add_message(request, monitio.SUCCESS, 'Hi Sally, here is a message to you.', subject='Success message', user=sally)
    
You can also set a `from_user`, which lets you use Persistent Messages as messaging system between users.

#### You can make messages expire ####

You need to pass a date and time to `expires` argument. Once the message has expired, it will not be included in the returned QuerySet. At the moment there is no view or method to clear expired messages from database.

### Displaying messages ###

To add monitio to your template:

* add to `<head>` section:
    ```
    {% include "monitio/header.html" %}
    ```
    
 This will include `yaffle.js`, `monitio.js` monitio translations and themes.
 
* in the `<body>` section, place the message placeholder anywhere you like:

    ```
    <div id="monitioMessages"></div>
    ```
    
* ... and initialize monitio, optionally passing theme parameter:
    ```
    <script type="text/javascript">
        $(document).ready(function () {
            initial = [];
            {% if messages %}
                {% for message in messages %}
                    initial.push({
                        'subject': '{{ message.subject }}',
                        'message': '{{ message.message }}',
                        'level': '{{ message.level }}',
                        'url': '{{ message.url }}',
                        'is_persistent': {{ message.is_persistent|lower }},
                        'pk': '{{ message.pk }}'});
                {% endfor %}
            {% endif %}


            $("#monitioMessages").MessagesPlaceholder({
                "url": '{% url "monitio:persistent-messages-sse" user.username %}',
                "theme": "foundation" // remove for jqueryui theme,
                "initial": initial
            });

        });
    </script>
    <div id="monitio"></div>
    ```

* don't forget to add links to `jquery`, `jqueryui` and optionally to `foundation 5`

* if any problems, check `foundation_index.html` in the `test_app/templates` directory, as it is much simpler than original one. 

### Creating notifications from background tasks (eg. Celery) ###

To create a notofication from a long-running, background process, use
api.create_message:

    def create_message(to_user, level, message, from_user=None, extra_tags='',
                   subject='', expires=None, close_timeout=None, sse=True,
                   email=False):

This function will call PersistentStorage.add method for you.

### Storage extra methods ###

In Django `request._messages` is set to the default storage you configured in your settings. Persistent Messages storage has some extra methods that Django built-in storages don't have that can be very useful:

* **get_persistent**: Get read and unread persistent messages
* **get_persistent_unread**: Get unread persistent messages
* **get_nonpersistent**: Gets nonpersistent messages
* **count_unread**: Counts persistent and nonpersistent unread messages
* **count_persistent_unread**: Counts persistent unread messages
* **count_nonpersistent**: Counts nonpersistent messages

Let's see some examples of what this means.

#### Display number of unread messages ####

Imagine you've created an inbox for your users using Persistent Messages and you want to show them in the menu how many unread messages they have, if they have them:

    <ul id="menu">
        <li><a href="">inbox {% if messages.count_persistent_unread > 0 %}({{ messages.count_persistent_unread }}){% endif %}</a></li>
    </ul>

### AUTHORS ###

django-monitio is (C) 2013-2014 [mpasternak](https://github.com/mpasternak).

[philomat](https://github.com/philomat) is the author of original code for
[django-persistent-messages](https://github.com/philomat/django-persistent-messages),
which was then forked by [maurojp](https://github.com/maurojp).



