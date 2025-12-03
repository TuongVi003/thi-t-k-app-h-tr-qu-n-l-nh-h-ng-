from apscheduler.schedulers.background import BackgroundScheduler
from apscheduler.triggers.cron import CronTrigger
from django_apscheduler.jobstores import DjangoJobStore, register_events
from django_apscheduler import util
from django.db import utils as db_utils
from .jobs import notify_reservations

def start():
    scheduler = BackgroundScheduler(timezone="Asia/Ho_Chi_Minh")
    try:
        scheduler.add_jobstore(DjangoJobStore(), "default")
    except db_utils.ProgrammingError as e:
        print("ERROR: Cannot initialize DjangoJobStore; the required django_apscheduler DB tables are missing.")
        print("Make sure 'django_apscheduler' is listed in INSTALLED_APPS and run: python manage.py migrate")
        raise

    scheduler.add_job(
        notify_reservations,
        trigger=CronTrigger(minute="*/1"),  # chạy mỗi 1 phút
        id="notify_reservations",
        max_instances=1,
        replace_existing=True,
    )

    register_events(scheduler)
    scheduler.start()
    print("Scheduler started...")
